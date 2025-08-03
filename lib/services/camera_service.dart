import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'logger.dart';

class CameraService {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isSimulator = false;
  Timer? _captureTimer;
  Timer? _cleanupTimer;
  final List<String> _capturedImages = [];

  // Callback for when images are captured
  Function(String)? onImageCaptured;

  bool get isInitialized => _isInitialized;
  bool get isSimulator => _isSimulator;
  CameraController? get cameraController => _cameraController;

  // Set callback for image capture events
  void setImageCaptureCallback(Function(String) callback) {
    onImageCaptured = callback;
  }

  Future<void> checkEnvironment() async {
    // Check if we're in simulator by trying to get cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _isSimulator = true;
    } else {
      await checkCameraPermission();
    }
  }

  Future<void> checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status == PermissionStatus.granted) {
      await initializeCamera();
    }
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      await initializeCamera();
    }
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.low, // Use lowest resolution for smallest file size
      );

      try {
        await _cameraController!.initialize();
        _isInitialized = true;
        _startAutomaticCapture();
      } catch (e) {
        Logger.error('Camera initialization failed', e);
        _isInitialized = false;
      }
    } else {
      _isInitialized = false;
    }
  }

  void _startAutomaticCapture() {
    // Capture photo every 10 seconds
    _captureTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isInitialized && !_isSimulator) {
        _capturePhoto();
      }
    });

    // Cleanup photos every minute
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _cleanupPhotos();
    });
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController != null && _isInitialized) {
        final image = await _cameraController!.takePicture();
        _capturedImages.add(image.path);
        Logger.debug('Captured photo: ${image.path}');

        // Notify callback if set
        onImageCaptured?.call(image.path);

        // Keep only the last 6 photos (1 minute worth at 10-second intervals)
        if (_capturedImages.length > 6) {
          final oldImage = _capturedImages.removeAt(0);
          await _deleteFile(oldImage);
        }
      }
    } catch (e) {
      Logger.error('Failed to capture photo', e);
    }
  }

  Future<void> _cleanupPhotos() async {
    Logger.debug('Cleaning up ${_capturedImages.length} photos...');
    for (final imagePath in _capturedImages) {
      await _deleteFile(imagePath);
    }
    _capturedImages.clear();
    Logger.debug('Photo cleanup completed');
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.debug('Deleted: $filePath');
      }
    } catch (e) {
      Logger.error('Failed to delete file $filePath', e);
    }
  }

  Future<String?> captureImage() async {
    if (_isSimulator) {
      // Simulate image capture in simulator
      await Future.delayed(const Duration(seconds: 1));
      return 'simulated_image.jpg';
    } else if (_cameraController != null && _isInitialized) {
      // Use the most recent captured photo if available
      if (_capturedImages.isNotEmpty) {
        return _capturedImages.last;
      } else {
        // Capture a new photo if none available
        final image = await _cameraController!.takePicture();
        return image.path;
      }
    } else {
      throw Exception('Camera not available');
    }
  }

  void dispose() {
    _captureTimer?.cancel();
    _cleanupTimer?.cancel();
    _cleanupPhotos(); // Clean up any remaining photos
    _cameraController?.dispose();
  }
}
