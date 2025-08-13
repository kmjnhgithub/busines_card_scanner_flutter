import 'dart:convert';

import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:dio/dio.dart';

/// OpenAI Service 抽象介面
abstract class OpenAIService {
  Future<ParsedCardData> parseCardFromText(String ocrText, {ParseHints? hints});

  Future<BatchParseResult> parseCardsFromTexts(
    List<String> ocrTexts, {
    ParseHints? hints,
  });

  Future<AIServiceStatus> getServiceStatus();
}

/// OpenAI Service 實作
class OpenAIServiceImpl implements OpenAIService {
  final Dio dio;
  final EnhancedSecureStorage secureStorage;

  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-3.5-turbo';
  static const double _temperature = 0.1;
  static const int _maxTokens = 1000;
  static const int _maxTextLength = 10000;

  OpenAIServiceImpl({required this.dio, required this.secureStorage});

  @override
  Future<ParsedCardData> parseCardFromText(
    String ocrText, {
    ParseHints? hints,
  }) async {
    // 輸入驗證
    if (ocrText.trim().isEmpty) {
      throw const InvalidInputFailure(
        field: 'ocrText',
        userMessage: 'OCR text cannot be empty',
      );
    }

    if (ocrText.length > _maxTextLength) {
      throw InvalidInputFailure(
        field: 'ocrText',
        value: '${ocrText.length} characters',
        userMessage: 'OCR text is too long',
      );
    }

    // 檢查惡意內容
    if (_containsMaliciousContent(ocrText)) {
      throw const InvalidInputFailure(
        field: 'ocrText',
        userMessage: 'Input contains potentially unsafe content',
      );
    }

    // 取得 API Key
    final apiKeyResult = await secureStorage.getApiKey('openai_api_key');
    final apiKey = apiKeyResult.fold((failure) => null, (key) => key);

    if (apiKey == null || apiKey.isEmpty) {
      throw const AIServiceUnavailableFailure(
        userMessage: 'AI service is not configured',
      );
    }

    try {
      // 建立 API 請求
      final response = await dio.post(
        '$_baseUrl/chat/completions',
        data: _buildChatCompletionRequest(ocrText, hints),
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // 解析回應
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on Exception catch (e) {
      throw AIServiceUnavailableFailure(
        userMessage: 'AI service is temporarily unavailable',
        reason: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<BatchParseResult> parseCardsFromTexts(
    List<String> ocrTexts, {
    ParseHints? hints,
  }) async {
    // TODO: 實作批次處理
    final successful = <ParsedCardData>[];
    final failed = <BatchParseError>[];

    for (int i = 0; i < ocrTexts.length; i++) {
      try {
        final result = await parseCardFromText(ocrTexts[i], hints: hints);
        successful.add(result);
      } on Exception catch (e) {
        failed.add(BatchParseError(index: i, error: e.toString()));
      }
    }

    return BatchParseResult(successful: successful, failed: failed);
  }

  @override
  Future<AIServiceStatus> getServiceStatus() async {
    final startTime = DateTime.now();

    try {
      final apiKeyResult = await secureStorage.getApiKey('openai_api_key');
      final apiKey = apiKeyResult.fold((failure) => null, (key) => key);

      if (apiKey == null || apiKey.isEmpty) {
        return AIServiceStatus(
          isAvailable: false,
          error: 'API key not configured',
          responseTimeMs: 0,
          remainingQuota: 0,
          quotaResetAt: DateTime.now(),
          checkedAt: startTime,
        );
      }

      // 檢查 API 狀態
      final response = await dio.get(
        '$_baseUrl/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      final endTime = DateTime.now();
      final responseTime = endTime
          .difference(startTime)
          .inMilliseconds
          .toDouble();

      // 解析配額資訊
      final headers = response.headers;
      final remainingQuota =
          int.tryParse(
            headers.value('x-ratelimit-remaining-requests') ?? '0',
          ) ??
          0;

      final resetTime =
          DateTime.tryParse(
            headers.value('x-ratelimit-reset-requests') ?? '',
          ) ??
          DateTime.now().add(const Duration(hours: 1));

      return AIServiceStatus(
        isAvailable: true,
        responseTimeMs: responseTime,
        remainingQuota: remainingQuota,
        quotaResetAt: resetTime,
        checkedAt: startTime,
      );
    } on Exception catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime
          .difference(startTime)
          .inMilliseconds
          .toDouble();

      return AIServiceStatus(
        isAvailable: false,
        error: 'Service check failed: ${e.toString()}',
        responseTimeMs: responseTime,
        remainingQuota: 0,
        quotaResetAt: DateTime.now(),
        checkedAt: startTime,
      );
    }
  }

  /// 建立 Chat Completion 請求
  Map<String, dynamic> _buildChatCompletionRequest(
    String ocrText,
    ParseHints? hints,
  ) {
    final systemPrompt = _buildSystemPrompt(hints);
    final userPrompt = _buildUserPrompt(ocrText);

    return {
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': _temperature,
      'max_tokens': _maxTokens,
      'response_format': {'type': 'json_object'},
    };
  }

  /// 建立系統提示
  String _buildSystemPrompt(ParseHints? hints) {
    return '''
你是一個專業的名片資訊解析專家。請將輸入的名片文字解析為結構化的 JSON 格式。

要求：
1. 輸出必須是有效的 JSON 格式
2. 包含以下欄位：name, company, jobTitle, phone, mobile, email, address, confidence
3. confidence 是 0-1 之間的數值，表示解析準確度
4. 如果某個欄位無法識別，設為 null
5. 電話號碼去除多餘符號，保持可讀性
6. email 必須是有效格式

語言偏好：${hints?.language ?? '中文'}
國家/地區：${hints?.country ?? '台灣'}
''';
  }

  /// 建立用戶提示
  String _buildUserPrompt(String ocrText) {
    return '''
請解析以下名片文字：

$ocrText

請以 JSON 格式回覆，包含 name, company, jobTitle, phone, mobile, email, address, confidence 等欄位。
''';
  }

  /// 解析 API 回應
  ParsedCardData _parseResponse(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List;
      if (choices.isEmpty) {
        throw const AIServiceUnavailableFailure(
          userMessage: 'No response from AI service',
        );
      }

      final message = choices[0]['message'];
      final content = message['content'] as String;

      final parsedData = jsonDecode(content) as Map<String, dynamic>;

      return _sanitizeAndValidateResult(parsedData);
    } on Exception catch (e) {
      throw AIServiceUnavailableFailure(
        userMessage: 'Failed to parse AI response',
        reason: 'Parse error: $e',
      );
    }
  }

  /// 清理和驗證 AI 結果
  ParsedCardData _sanitizeAndValidateResult(Map<String, dynamic> data) {
    return ParsedCardData(
      name: _sanitizeString(data['name']),
      company: _sanitizeString(data['company']),
      jobTitle: _sanitizeString(data['jobTitle']),
      phone: _validatePhone(_sanitizeString(data['phone'])),
      mobile: _validatePhone(_sanitizeString(data['mobile'])),
      email: _validateEmail(_sanitizeString(data['email'])),
      address: _sanitizeString(data['address']),
      confidence: _validateConfidence(data['confidence']),
      source: ParseSource.ai,
      parsedAt: DateTime.now(),
    );
  }

  /// 清理字串
  String? _sanitizeString(value) {
    if (value == null) {
      return null;
    }
    final str = value.toString().trim();
    if (str.isEmpty) {
      return null;
    }

    // 移除可能的惡意內容
    final sanitized = str
        .replaceAll(RegExp('<[^>]*>'), '') // 移除 HTML 標籤
        .replaceAll(RegExp('javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*='), ''); // 移除事件處理器

    return sanitized.isEmpty ? null : sanitized;
  }

  /// 驗證電話號碼
  String? _validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null;
    }

    // 簡單的電話號碼驗證
    final phonePattern = RegExp(r'^[+]?[\d\s\-()]{7,}$');
    return phonePattern.hasMatch(phone) ? phone : null;
  }

  /// 驗證 email
  String? _validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return null;
    }

    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailPattern.hasMatch(email) ? email : null;
  }

  /// 驗證信心度
  double _validateConfidence(confidence) {
    if (confidence == null) {
      return 0;
    }

    final value = double.tryParse(confidence.toString()) ?? 0.0;
    return value.clamp(0.0, 1.0);
  }

  /// 檢查惡意內容
  bool _containsMaliciousContent(String text) {
    final maliciousPatterns = [
      RegExp('<script[^>]*>', caseSensitive: false),
      RegExp('javascript:', caseSensitive: false),
      RegExp(r'<.*?on\w+\s*=', caseSensitive: false),
      RegExp('<!DOCTYPE.*?>', caseSensitive: false),
      RegExp(r'<\?xml', caseSensitive: false),
      RegExp(r'DROP\s+TABLE', caseSensitive: false),
      RegExp('UNION.*?SELECT', caseSensitive: false),
    ];

    return maliciousPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// 處理 Dio 異常
  RepositoryException _handleDioException(DioException e) {
    if (e.response?.statusCode == 429) {
      final errorData = e.response?.data;
      if (errorData is Map && errorData['error']?['code'] == 'quota_exceeded') {
        return AIQuotaExceededFailure(
          resetTime: DateTime.now().add(const Duration(hours: 1)),
          userMessage: 'AI service quota has been exceeded',
        );
      }
      return AIRateLimitFailure(
        retryAfter: const Duration(minutes: 1),
        userMessage: 'Too many requests, please try again later',
      );
    }

    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return const AIServiceUnavailableFailure(
        userMessage: 'AI service request timed out',
      );
    }

    return const AIServiceUnavailableFailure(
      userMessage: 'AI service is temporarily unavailable',
    );
  }
}
