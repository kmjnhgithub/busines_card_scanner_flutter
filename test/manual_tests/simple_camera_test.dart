import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 簡單的相機測試頁面
/// 用來隔離測試 CameraPreview 是否能正常顯示
class SimpleCameraTest extends StatefulWidget {
  const SimpleCameraTest({super.key});

  @override
  State<SimpleCameraTest> createState() => _SimpleCameraTestState();
}

class _SimpleCameraTestState extends State<SimpleCameraTest> {
  CameraController? _controller;
  bool _isInitialized = false;
  String _status = '準備初始化相機...';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _status = '檢查相機權限...';
      });

      // 請求權限
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _status = '相機權限被拒絕';
        });
        return;
      }

      setState(() {
        _status = '獲取相機列表...';
      });

      // 獲取相機
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _status = '沒有可用相機';
        });
        return;
      }

      setState(() {
        _status = '初始化相機控制器...';
      });

      // 初始化控制器
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = '相機已初始化';
        });
      }
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('簡單相機測試'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 狀態顯示
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '狀態: $_status',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '控制器: ${_controller != null ? "已創建" : "未創建"}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '初始化: ${_isInitialized ? "是" : "否"}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (_controller != null)
                  Text(
                    'AspectRatio: ${_controller!.value.aspectRatio}',
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
          // 相機預覽
          Expanded(child: _buildCameraView()),
          // 控制按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _initCamera,
                  child: const Text('重新初始化'),
                ),
                ElevatedButton(
                  onPressed: _isInitialized ? _takePicture : null,
                  child: const Text('拍照'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Container(
      color: Colors.red.withOpacity(0.1), // 紅色背景來確認容器大小
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2), // 綠色邊框
            ),
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('照片已保存: ${image.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拍照失敗: $e')));
      }
    }
  }
}

/// 測試應用程式入口
void main() {
  runApp(
    const MaterialApp(
      home: SimpleCameraTest(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
