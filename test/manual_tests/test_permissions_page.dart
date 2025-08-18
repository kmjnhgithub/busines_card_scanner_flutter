import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 測試權限頁面 - 用來確保權限請求正確觸發
class TestPermissionsPage extends StatefulWidget {
  const TestPermissionsPage({super.key});

  @override
  State<TestPermissionsPage> createState() => _TestPermissionsPageState();
}

class _TestPermissionsPageState extends State<TestPermissionsPage> {
  String _cameraStatus = 'Unknown';
  String _photosStatus = 'Unknown';
  String _photosAddStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final photosAddStatus = await Permission.photosAddOnly.status;

    setState(() {
      _cameraStatus = cameraStatus.toString();
      _photosStatus = photosStatus.toString();
      _photosAddStatus = photosAddStatus.toString();
    });
  }

  Future<void> _requestCameraPermission() async {
    debugPrint('Requesting camera permission...');
    final status = await Permission.camera.request();
    debugPrint('Camera permission status: $status');

    setState(() {
      _cameraStatus = status.toString();
    });

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _requestPhotosPermission() async {
    debugPrint('Requesting photos permission...');
    final status = await Permission.photos.request();
    debugPrint('Photos permission status: $status');

    setState(() {
      _photosStatus = status.toString();
    });

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _requestPhotosAddPermission() async {
    debugPrint('Requesting photos add permission...');
    final status = await Permission.photosAddOnly.request();
    debugPrint('Photos add permission status: $status');

    setState(() {
      _photosAddStatus = status.toString();
    });

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('測試權限'), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '權限狀態測試',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 相機權限
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '相機權限',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('狀態: $_cameraStatus'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _requestCameraPermission,
                      child: const Text('請求相機權限'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 相簿權限
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '相簿權限',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('狀態: $_photosStatus'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _requestPhotosPermission,
                      child: const Text('請求相簿權限'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 相簿新增權限
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '相簿新增權限',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('狀態: $_photosAddStatus'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _requestPhotosAddPermission,
                      child: const Text('請求相簿新增權限'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 打開設定
            ElevatedButton(
              onPressed: openAppSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('打開應用程式設定'),
            ),

            const SizedBox(height: 20),

            // 重新檢查
            ElevatedButton(
              onPressed: _checkPermissions,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('重新檢查權限狀態'),
            ),
          ],
        ),
      ),
    );
  }
}
