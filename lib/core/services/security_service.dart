import 'dart:convert';

import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

/// 安全服務，提供輸入清理、內容驗證和敏感資訊保護功能
///
/// 功能包括：
/// - 輸入清理（SQL 注入、XSS 攻擊防護）
/// - API 回應驗證
/// - 敏感資訊遮蔽（API Key、密碼、信用卡號）
/// - 內容安全驗證
/// - 安全標頭驗證
/// - 可疑活動檢測
class SecurityService {
  /// SQL 注入攻擊模式
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(
      r'\b(DROP|DELETE|UNION|INSERT|UPDATE|SELECT)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(TABLE|FROM|INTO)\b', caseSensitive: false),
    RegExp(r'(--|#|/\*|\*/)', caseSensitive: false),
    RegExp(r"'\s*(OR|AND)\s*'[^']*'", caseSensitive: false),
    RegExp(r';\s*(DROP|DELETE)', caseSensitive: false),
    RegExp(r"'\s*;\s*", caseSensitive: false),
    RegExp("'", caseSensitive: false), // 移除所有單引號
  ];

  /// XSS（跨站腳本攻擊）模式
  static final List<RegExp> _xssPatterns = [
    RegExp('<script[^>]*>.*?</script>', caseSensitive: false),
    RegExp('<iframe[^>]*>.*?</iframe>', caseSensitive: false),
    RegExp(r'javascript:\s*alert\s*\(', caseSensitive: false),
    RegExp(r'<[^>]*\s+on\w+\s*=', caseSensitive: false),
    RegExp('<svg[^>]*onload[^>]*>', caseSensitive: false),
    RegExp('<img[^>]*onerror[^>]*>', caseSensitive: false),
    RegExp(r'alert\s*\(', caseSensitive: false), // 移除任何 alert 呼叫
    RegExp('<script[^>]*>', caseSensitive: false), // 檢測任何 script 標籤
    RegExp('</script>', caseSensitive: false), // 檢測結尾標籤
  ];

  /// 敏感資訊檢測模式（API Key、密碼等）
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r'(api[_-]?key|apikey)\s*[:=]\s*[\w\-]+', caseSensitive: false),
    RegExp(r'bearer\s+[\w\-\.]+', caseSensitive: false),
    RegExp(r'sk-[\w]+', caseSensitive: false), // OpenAI API key pattern
    RegExp(r'(password|pwd|pass)\s*[:=]\s*[^\s]+', caseSensitive: false),
    RegExp(r'authorization\s*:\s*[\w\s]+', caseSensitive: false),
    RegExp(r'password\s+is:\s*[^\s]+', caseSensitive: false), // 密碼模式
  ];

  /// 信用卡號碼檢測模式
  static final List<RegExp> _creditCardPatterns = [
    RegExp(r'\b4\d{3}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // Visa
    RegExp(r'\b5[1-5]\d{2}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // MasterCard
    RegExp(r'\b3[47]\d{13}\b'), // American Express
    RegExp(r'\b3[0-9]\d{11}\b'), // Diners Club
  ];

  /// 惡意代碼執行模式
  static final List<RegExp> _maliciousExecutionPatterns = [
    RegExp(r'eval\s*\(', caseSensitive: false),
    RegExp(r'exec\s*\(', caseSensitive: false),
    RegExp(r'system\s*\(', caseSensitive: false),
    RegExp('shell_exec', caseSensitive: false),
    RegExp('base64_decode', caseSensitive: false),
    RegExp(r'window\.location', caseSensitive: false),
    RegExp(r'document\.cookie', caseSensitive: false),
  ];

  /// 清理輸入內容，移除潛在的惡意代碼
  Either<SecurityFailure, String> sanitizeInput(String input) {
    if (input.trim().isEmpty) {
      return const Left(
        SecurityFailure(
          userMessage: '輸入內容不能為空',
          internalMessage: 'Empty input provided for sanitization',
        ),
      );
    }

    String sanitized = input;

    try {
      // 移除 SQL 注入模式
      for (final pattern in _sqlInjectionPatterns) {
        sanitized = sanitized.replaceAll(pattern, '');
      }

      // 移除 XSS 模式
      for (final pattern in _xssPatterns) {
        sanitized = sanitized.replaceAll(pattern, '');
      }

      // 移除 HTML 標籤（保留內容）
      sanitized = sanitized.replaceAll(RegExp('<[^>]*>'), '');

      // 移除控制字元（保留換行和tab）
      sanitized = sanitized.replaceAll(
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
        '',
      );

      // 清理過度的空白
      sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

      return Right(sanitized);
    } on Exception catch (e) {
      return Left(
        SecurityFailure(
          userMessage: '輸入清理過程發生錯誤',
          internalMessage: 'Error during input sanitization: ${e.toString()}',
        ),
      );
    }
  }

  /// 驗證 API 回應內容的安全性
  Either<SecurityFailure, String> validateApiResponse(String response) {
    if (response.isEmpty) {
      return const Left(
        SecurityFailure(
          userMessage: 'API 回應為空',
          internalMessage: 'Empty API response',
        ),
      );
    }

    try {
      // 檢查是否包含惡意腳本
      for (final pattern in _xssPatterns) {
        if (pattern.hasMatch(response)) {
          return const Left(
            SecurityFailure(
              userMessage: 'API 回應包含不安全內容',
              internalMessage: 'XSS pattern detected in API response',
              securityCode: 'XSS_DETECTED',
            ),
          );
        }
      }

      // 檢查是否包含惡意執行代碼
      for (final pattern in _maliciousExecutionPatterns) {
        if (pattern.hasMatch(response)) {
          return const Left(
            SecurityFailure(
              userMessage: 'API 回應包含可疑代碼',
              internalMessage: 'Malicious execution pattern detected',
              securityCode: 'MALICIOUS_CODE',
            ),
          );
        }
      }

      // 基本 JSON 格式驗證（如果是 JSON）
      if (response.trim().startsWith('{') || response.trim().startsWith('[')) {
        try {
          json.decode(response);
        } on FormatException catch (e) {
          return Left(
            SecurityFailure(
              userMessage: 'API 回應格式錯誤',
              internalMessage: 'Invalid JSON in API response: ${e.message}',
              securityCode: 'INVALID_JSON',
            ),
          );
        }
      }

      return Right(response);
    } on Exception catch (e) {
      return Left(
        SecurityFailure(
          userMessage: 'API 回應驗證失敗',
          internalMessage: 'API response validation error: $e',
        ),
      );
    }
  }

  /// 遮蔽文字中的敏感資訊
  Either<SecurityFailure, String> maskSensitiveInfo(String text) {
    if (text.isEmpty) {
      return Right(text);
    }

    String masked = text;

    try {
      // 遮蔽 API 金鑰
      for (final pattern in _sensitivePatterns) {
        masked = masked.replaceAllMapped(pattern, (match) {
          // 檢查是否有捕獲群組
          if (match.groupCount > 0) {
            final key = match.group(1) ?? '';
            return '$key: ***';
          } else {
            // 沒有捕獲群組，直接替換為遮蔽文字
            return '***';
          }
        });
      }

      // 遮蔽信用卡號碼
      for (final pattern in _creditCardPatterns) {
        masked = masked.replaceAllMapped(pattern, (match) {
          final cardNumber = match.group(0) ?? '';
          final lastFour = cardNumber
              .replaceAll(RegExp(r'[-\s]'), '')
              .substring(
                cardNumber.replaceAll(RegExp(r'[-\s]'), '').length - 4,
              );
          return '****-****-****-$lastFour';
        });
      }

      return Right(masked);
    } on Exception catch (e) {
      return Left(
        SecurityFailure(
          userMessage: '敏感資訊遮蔽失敗',
          internalMessage: 'Error masking sensitive information: $e',
        ),
      );
    }
  }

  /// 驗證內容是否包含惡意代碼
  Either<SecurityFailure, String> validateContent(String content) {
    if (content.isEmpty) {
      return Right(content);
    }

    try {
      // 檢查惡意執行模式
      for (final pattern in _maliciousExecutionPatterns) {
        if (pattern.hasMatch(content)) {
          return const Left(
            SecurityFailure(
              userMessage: '內容包含不安全的代碼',
              internalMessage:
                  'Malicious execution pattern detected in content',
              securityCode: 'MALICIOUS_CONTENT',
            ),
          );
        }
      }

      // 檢查 XSS 模式
      for (final pattern in _xssPatterns) {
        if (pattern.hasMatch(content)) {
          return const Left(
            SecurityFailure(
              userMessage: '內容包含可疑腳本',
              internalMessage: 'XSS pattern detected in content',
              securityCode: 'XSS_CONTENT',
            ),
          );
        }
      }

      // 檢查內容長度（防止 DoS 攻擊）
      if (content.length > 100000) {
        // 100KB 限制
        return const Left(
          SecurityFailure(
            userMessage: '內容過長',
            internalMessage: 'Content exceeds size limit',
            securityCode: 'SIZE_LIMIT',
          ),
        );
      }

      // 檢查過多的控制字元（排除換行符）
      final controlCharCount = RegExp(
        r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
      ).allMatches(content).length;
      if (controlCharCount > content.length * 0.2) {
        // 超過 20% 為控制字元
        return const Left(
          SecurityFailure(
            userMessage: '內容包含過多控制字元',
            internalMessage: 'Excessive control characters in content',
            securityCode: 'SUSPICIOUS_CONTENT',
          ),
        );
      }

      return Right(content);
    } on Exception catch (e) {
      return Left(
        SecurityFailure(
          userMessage: '內容驗證失敗',
          internalMessage: 'Content validation error: $e',
        ),
      );
    }
  }

  /// 驗證安全標頭
  Either<SecurityFailure, Map<String, String>> validateSecurityHeaders(
    Map<String, String> headers,
  ) {
    final requiredSecurityHeaders = [
      'X-Content-Type-Options',
      'X-Frame-Options',
    ];

    final recommendedSecurityHeaders = [
      'Strict-Transport-Security',
      'Content-Security-Policy',
      'X-XSS-Protection',
    ];

    try {
      // 檢查必要的安全標頭
      for (final header in requiredSecurityHeaders) {
        if (!headers.containsKey(header)) {
          return Left(
            SecurityFailure(
              userMessage: '缺少必要的安全標頭',
              internalMessage: 'Missing required security header: $header',
              securityCode: 'MISSING_SECURITY_HEADER',
            ),
          );
        }
      }

      // 檢查推薦的安全標頭（只記錄警告，不阻止）
      for (final header in recommendedSecurityHeaders) {
        if (!headers.containsKey(header)) {
          // 在實際應用中，這裡可能會記錄到日誌系統
          // log.warn('Missing recommended security header: $header');
        }
      }

      return Right(headers);
    } on Exception catch (e) {
      return Left(
        SecurityFailure(
          userMessage: '安全標頭驗證失敗',
          internalMessage: 'Security headers validation error: $e',
        ),
      );
    }
  }

  /// 檢測可疑活動模式
  Either<SecurityFailure, String> detectSuspiciousActivity(String activityLog) {
    if (activityLog.isEmpty) {
      return Right(activityLog);
    }

    try {
      final lowerLog = activityLog.toLowerCase();

      // 檢查可疑的模式
      final suspiciousPatterns = [
        'multiple failed',
        'unusual api call',
        'high frequency',
        'brute force',
        'rate limit exceeded',
      ];

      for (final pattern in suspiciousPatterns) {
        if (lowerLog.contains(pattern)) {
          return Left(
            SecurityFailure(
              userMessage: '檢測到可疑活動',
              internalMessage: 'Suspicious activity pattern detected: $pattern',
              securityCode: 'SUSPICIOUS_ACTIVITY',
            ),
          );
        }
      }

      return Right(activityLog);
    } on Exception catch (e) {
      return Left(
        SecurityFailure(
          userMessage: '可疑活動檢測失敗',
          internalMessage: 'Suspicious activity detection error: $e',
        ),
      );
    }
  }
}
