import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/camera_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 相機拍攝頁面
///
/// 功能包括：
/// - 相機預覽和拍照
/// - 閃光燈控制
/// - 焦點控制
/// - 相簿選擇
/// - 掃描框架引導
class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = ref.read(cameraViewModelProvider).cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // 暫停相機
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // 恢復相機
      _initializeCamera();
    }
  }

  /// 初始化相機
  Future<void> _initializeCamera() async {
    try {
      // 請求相機權限
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showPermissionDeniedDialog();
        return;
      }

      // 獲取可用相機
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          _showNoCameraDialog();
        }
        return;
      }

      // 初始化相機 ViewModel
      await ref
          .read(cameraViewModelProvider.notifier)
          .initializeCamera(_cameras);
    } on Exception catch (e) {
      debugPrint('初始化相機失敗: $e');
    }
  }

  /// 處理拍照
  Future<void> _handleTakePicture() async {
    await ref.read(cameraViewModelProvider.notifier).takePicture();

    // 檢查是否拍照成功，如果成功則導航到下一頁
    final state = ref.read(cameraViewModelProvider);
    if (state.capturedImagePath != null) {
      _navigateToOCRProcessing(state.capturedImagePath!);
    }
  }

  /// 處理相簿選擇
  Future<void> _handlePhotoLibrary() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        _navigateToOCRProcessing(image.path);
      }
    } on Exception catch (e) {
      debugPrint('選擇相簿圖片失敗: $e');
    }
  }

  /// 導航到 OCR 處理頁面
  void _navigateToOCRProcessing(String imagePath) {
    // TODO: 實作導航到 OCR 處理頁面
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => OCRProcessingPage(imagePath: imagePath),
    // ));
  }

  /// 顯示權限被拒絕對話框
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要相機權限'),
        content: const Text('請在設定中開啟相機權限以使用拍照功能'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('前往設定'),
          ),
        ],
      ),
    );
  }

  /// 顯示沒有相機對話框
  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('沒有可用相機'),
        content: const Text('此裝置沒有可用的相機'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(cameraViewModelProvider);

          // 載入中狀態
          if (state.isLoading) {
            return _buildLoadingView();
          }

          // 錯誤狀態
          if (state.error != null) {
            return _buildErrorView(state.error!);
          }

          // 正常相機預覽
          if (state.isInitialized && state.cameraController != null) {
            return _buildCameraView(state);
          }

          // 預設狀態
          return _buildLoadingView();
        },
      ),
    );
  }

  /// 建立載入中視圖
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: AppDimensions.space4),
          Text('相機初始化中...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// 建立錯誤視圖
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.space6),
            const Text(
              '相機錯誤',
              style: AppTextStyles.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space3),
            Text(
              error,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立相機視圖
  Widget _buildCameraView(CameraState state) {
    return Stack(
      children: [
        // 相機預覽
        _buildCameraPreview(state.cameraController!),

        // 掃描框架覆蓋層
        _buildCameraOverlay(),

        // 頂部控制欄
        _buildTopControls(),

        // 底部控制欄
        _buildBottomControls(state),

        // 安全區域
        const SafeArea(child: SizedBox.shrink()),
      ],
    );
  }

  /// 建立相機預覽
  Widget _buildCameraPreview(CameraController controller) {
    return Positioned.fill(
      child: GestureDetector(
        onTapUp: (TapUpDetails details) {
          _handleFocusTap(details, controller);
        },
        child: CameraPreview(controller),
      ),
    );
  }

  /// 處理焦點點擊
  void _handleFocusTap(TapUpDetails details, CameraController controller) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPoint = renderBox.globalToLocal(details.globalPosition);
    final Offset focusPoint = Offset(
      localPoint.dx / renderBox.size.width,
      localPoint.dy / renderBox.size.height,
    );

    ref.read(cameraViewModelProvider.notifier).setFocusPoint(focusPoint);
  }

  /// 建立相機覆蓋層（掃描框架）
  Widget _buildCameraOverlay() {
    return Positioned.fill(
      key: const Key('camera_overlay'),
      child: CustomPaint(
        painter: _CameraScannerOverlayPainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 100),
            child: Text(
              '將名片放入框內',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 建立頂部控制欄
  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x80000000), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              // 關閉按鈕
              IconButton(
                key: const Key('close_camera_button'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: '關閉相機',
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立底部控制欄
  Widget _buildBottomControls(CameraState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x80000000)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 相簿按鈕
              _buildControlButton(
                key: const Key('photo_library_button'),
                icon: Icons.photo_library,
                onPressed: _handlePhotoLibrary,
                tooltip: '從相簿選擇',
              ),

              // 拍照按鈕
              _buildShutterButton(),

              // 閃光燈按鈕
              _buildControlButton(
                key: const Key('flash_toggle_button'),
                icon: _getFlashIcon(state.flashMode),
                onPressed: () => ref
                    .read(cameraViewModelProvider.notifier)
                    .toggleFlashMode(),
                tooltip: '切換閃光燈',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立控制按鈕
  Widget _buildControlButton({
    required Key key,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Semantics(
      label: tooltip,
      child: Container(
        key: key,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 24),
          tooltip: tooltip,
        ),
      ),
    );
  }

  /// 建立快門按鈕
  Widget _buildShutterButton() {
    return Semantics(
      label: '拍照',
      child: GestureDetector(
        key: const Key('camera_shutter_button'),
        onTap: _handleTakePicture,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 獲取閃光燈圖示
  IconData _getFlashIcon(FlashMode flashMode) {
    switch (flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }
}

/// 相機掃描框架覆蓋層繪製器
class _CameraScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // 計算掃描框架尺寸和位置（黃金比例）
    const aspectRatio = 1.618; // 名片的寬高比
    final frameWidth = size.width * 0.8;
    final frameHeight = frameWidth / aspectRatio;

    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2 - 50; // 稍微上移

    final frameRect = Rect.fromLTWH(
      frameLeft,
      frameTop,
      frameWidth,
      frameHeight,
    );

    // 繪製遮罩（除了掃描框架區域）
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // 繪製掃描框架邊角
    final cornerPaint = Paint()
      ..color =
          const Color(0xFFFFCC00) // 黃色框架
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerLength = 20.0;

    // 左上角
    canvas.drawLine(
      Offset(frameLeft, frameTop),
      Offset(frameLeft + cornerLength, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop),
      Offset(frameLeft, frameTop + cornerLength),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop),
      Offset(frameLeft + frameWidth - cornerLength, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop),
      Offset(frameLeft + frameWidth, frameTop + cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameHeight),
      Offset(frameLeft + cornerLength, frameTop + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameHeight),
      Offset(frameLeft, frameTop + frameHeight - cornerLength),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop + frameHeight),
      Offset(frameLeft + frameWidth - cornerLength, frameTop + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop + frameHeight),
      Offset(frameLeft + frameWidth, frameTop + frameHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
