import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:video_record_task/controllers.dart';
import '../session_model.dart';

class VideoCallScreen extends StatefulWidget {
  final SessionModel session;

  const VideoCallScreen({super.key, required this.session});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _cameraController;
  late VideoCallController controller;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VideoCallController(widget.session));
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint('❌ No cameras available');
        return;
      }

      _currentCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0;
      }

      await _setupCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('❌ Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      final camera = _cameras[cameraIndex];
      debugPrint(
          '📷 Setting up camera: ${camera.name} (${camera.lensDirection})');

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      debugPrint('✅ Camera initialized successfully');

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error setting up camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      Get.snackbar(
        'No Other Camera',
        'Only one camera is available',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _isCameraInitialized = false;
    });

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

    await _setupCamera(_currentCameraIndex);

    final direction =
        _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front
            ? 'Front'
            : 'Back';

    Get.snackbar(
      'Camera Switched',
      'Using $direction camera',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black54,
      colorText: Colors.white,
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Obx(() {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          !controller.isVideoOff.value) {
        return CameraPreview(_cameraController!);
      }

      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(
            Icons.videocam_off,
            size: 40,
            color: Colors.white54,
          ),
        ),
      );
    });
  }

  Widget _buildCameraSwitchButton() {
    return Obx(() {
      if (!controller.isVideoOff.value && _isCameraInitialized) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.cameraswitch,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _switchCamera,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main video view
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.blueAccent],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.session.patientName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.session.patientName,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Connected',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Small self-view
            Positioned(
              top: 20,
              right: 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildCameraView(),
                ),
              ),
            ),

            // Camera switch button
            if (_cameras.length > 1)
              Positioned(
                top: 25,
                right: 25,
                child: _buildCameraSwitchButton(),
              ),

            // Timer
            Positioned(
              top: 20,
              left: 20,
              child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
            ),

            // Control buttons
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(
                        icon: controller.isMuted.value
                            ? Icons.mic_off
                            : Icons.mic,
                        onPressed: controller.toggleMute,
                        backgroundColor: controller.isMuted.value
                            ? Colors.red
                            : Colors.white24,
                      ),
                      if (_cameras.length > 1)
                        CircularButton(
                          icon: Icons.cameraswitch,
                          onPressed: _switchCamera,
                          backgroundColor: Colors.white24,
                        ),
                      CircularButton(
                        icon: Icons.call_end,
                        onPressed: controller.endCall,
                        backgroundColor: Colors.red,
                        size: 64,
                      ),
                      CircularButton(
                        icon: controller.isVideoOff.value
                            ? Icons.videocam_off
                            : Icons.videocam,
                        onPressed: controller.toggleVideo,
                        backgroundColor: controller.isVideoOff.value
                            ? Colors.red
                            : Colors.white24,
                      ),
                    ],
                  )),
            ),

            // Camera status indicator
            if (!_isCameraInitialized)
              Positioned(
                top: 100,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Initializing camera...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double size;

  const CircularButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.white24,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
        iconSize: size * 0.5,
      ),
    );
  }
}
