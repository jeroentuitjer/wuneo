import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'logger.dart';
import 'dart:math';
import 'dart:async';

class AsciiArtService {
  static AsciiArtService? _instance;
  static bool _isInitialized = false;

  String _currentAsciiArt = '';
  Timer? _updateTimer;
  CameraController? _cameraController;
  bool _isSimulator = false;
  int _currentPhotoIndex = 0;

  final List<String> _asciiChars = [
    '█',
    '▓',
    '▒',
    '░',
    '▄',
    '▀',
    '▌',
    '▐',
    '◢',
    '◣',
    '◤',
    '◥'
  ];

  static AsciiArtService get instance {
    _instance ??= AsciiArtService._internal();
    return _instance!;
  }

  AsciiArtService._internal();

  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      await instance._initializeCamera();
      Logger.debug('AsciiArtService initialized');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _isSimulator = true;
        Logger.debug('Running in simulator - using asset image');
      } else {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.low,
        );
        await _cameraController!.initialize();
        Logger.debug('Camera initialized for real photo capture');
      }
    } catch (e) {
      _isSimulator = true;
      Logger.error('Camera initialization failed, using simulator mode', e);
    }
  }

  void startPeriodicUpdates() {
    _updateTimer?.cancel();
    // Capture and convert photo every 30 seconds for more visible changes
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _captureAndConvertPhoto();
    });
    // Capture initial photo immediately
    _captureAndConvertPhoto();
  }

  void stopPeriodicUpdates() {
    _updateTimer?.cancel();
  }

  Future<void> _captureAndConvertPhoto() async {
    try {
      if (_isSimulator) {
        // Use asset image in simulator mode (when camera is not available)
        _currentAsciiArt = await _loadAssetImageAsciiArt();
        Logger.debug('Generated Eiffel Tower ASCII art (simulator mode)');
      } else {
        // Capture real photo and convert when camera is available
        final photoPath = await _capturePhoto();
        if (photoPath != null) {
          _currentAsciiArt = await _convertPhotoToAscii(photoPath);
          Logger.debug('Converted real photo to ASCII art');
        }
      }
    } catch (e) {
      Logger.error('Failed to capture and convert photo', e);
      // Fallback to asset image if camera fails
      _currentAsciiArt = await _loadAssetImageAsciiArt();
    }
  }

  Future<String?> _capturePhoto() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        return image.path;
      }
    } catch (e) {
      Logger.error('Failed to capture photo', e);
    }
    return null;
  }

  Future<String> _loadAssetImageAsciiArt() async {
    try {
      // Load the asset image
      final ByteData data =
          await rootBundle.load('assets/eiffeltoren_parijs.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode asset image');
      }

      // Resize image for ASCII conversion
      final resizedImage = img.copyResize(image, width: 200, height: 80);

      // Convert to ASCII
      final asciiLines = <String>[];

      for (int y = 0; y < resizedImage.height; y++) {
        String line = '';
        for (int x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          final brightness = _calculateBrightness(pixel);
          final asciiChar = _brightnessToAscii(brightness);
          line += asciiChar;
        }
        asciiLines.add(line);
      }

      return asciiLines.join('\n');
    } catch (e) {
      Logger.error('Failed to load asset image', e);
      return _generateDummyPhotoAsciiArt();
    }
  }

  Future<String> _convertPhotoToAscii(String photoPath) async {
    try {
      // Read the image file
      final imageFile = File(photoPath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image for ASCII conversion - make it much larger for fullscreen
      final resizedImage = img.copyResize(image, width: 200, height: 80);

      // Convert to ASCII
      final asciiLines = <String>[];

      for (int y = 0; y < resizedImage.height; y++) {
        String line = '';
        for (int x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          final brightness = _calculateBrightness(pixel);
          final asciiChar = _brightnessToAscii(brightness);
          line += asciiChar;
        }
        asciiLines.add(line);
      }

      return asciiLines.join('\n');
    } catch (e) {
      Logger.error('Failed to convert photo to ASCII', e);
      return _generateDummyPhotoAsciiArt();
    }
  }

  double _calculateBrightness(img.Pixel pixel) {
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    return (r * 0.299 + g * 0.587 + b * 0.114) / 255.0;
  }

  String _brightnessToAscii(double brightness) {
    // Improved character mapping for better contrast
    if (brightness < 0.05) return '█';
    if (brightness < 0.1) return '▓';
    if (brightness < 0.15) return '▒';
    if (brightness < 0.2) return '░';
    if (brightness < 0.25) return '▄';
    if (brightness < 0.3) return '▀';
    if (brightness < 0.35) return '▌';
    if (brightness < 0.4) return '▐';
    if (brightness < 0.45) return '·';
    if (brightness < 0.5) return '.';
    if (brightness < 0.6) return ' ';
    return ' ';
  }

  String _generateDummyPhotoAsciiArt() {
    // Create a realistic ASCII art representation of a dummy photo
    final now = DateTime.now();
    final timeSeed = now.millisecondsSinceEpoch;
    final random = Random(timeSeed);

    const height = 80; // Much larger for fullscreen
    const width = 200; // Much wider for fullscreen
    final lines = <String>[];

    // Create a more structured ASCII art that looks like a photo
    for (int y = 0; y < height; y++) {
      String line = '';
      for (int x = 0; x < width; x++) {
        // Create different zones to simulate a photo
        final centerX = width / 2;
        final centerY = height / 2;
        final distanceFromCenter =
            sqrt(pow(x - centerX, 2) + pow(y - centerY, 2));

        // Sky area (top)
        if (y < height * 0.3) {
          final skyNoise = random.nextDouble();
          final skyPattern = sin(x * 0.02 + timeSeed * 0.0001) * 0.3 + 0.5;
          if (skyNoise < skyPattern) {
            if (skyNoise < 0.3) {
              line += '░';
            } else if (skyNoise < 0.6) {
              line += '▒';
            } else {
              line += ' ';
            }
          } else {
            line += ' ';
          }
        }
        // Building/object area (middle)
        else if (y < height * 0.7) {
          final buildingNoise = random.nextDouble();
          final buildingPattern = sin(x * 0.1 + timeSeed * 0.001) * 0.5 + 0.5;

          if (buildingNoise < buildingPattern) {
            if (buildingNoise < 0.3) {
              line += '█';
            } else if (buildingNoise < 0.6) {
              line += '▓';
            } else {
              line += '▒';
            }
          } else {
            line += ' ';
          }
        }
        // Ground area (bottom)
        else {
          final groundNoise = random.nextDouble();
          final groundPattern = cos(x * 0.05 + timeSeed * 0.002) * 0.3 + 0.7;

          if (groundNoise < groundPattern) {
            if (groundNoise < 0.4) {
              line += '▄';
            } else if (groundNoise < 0.7) {
              line += '▀';
            } else {
              line += '░';
            }
          } else {
            line += ' ';
          }
        }
      }
      lines.add(line);
    }

    return lines.join('\n');
  }

  String getCurrentAsciiArt() {
    return _currentAsciiArt;
  }

  void dispose() {
    stopPeriodicUpdates();
    _cameraController?.dispose();
  }
}
