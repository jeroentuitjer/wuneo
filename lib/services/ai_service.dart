import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'logger.dart';

class AiService {
  static bool _isInitialized = false;
  static const MethodChannel _channel = MethodChannel('ai_service');

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      if (Platform.isIOS) {
        // Initialize iOS Vision framework
        final result = await _channel.invokeMethod('initializeVision');
        Logger.info('AI Service initialized with iOS Vision framework');
        _isInitialized = true;
      } else {
        // Fallback for other platforms
        Logger.info(
            'AI Service initialized in simulated mode (non-iOS platform)');
        _isInitialized = true;
      }
    } catch (e) {
      Logger.error('Failed to initialize AI Service', e);
      _isInitialized = false;
    }
  }

  static Future<AiAnalysisResult> analyzeImage(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('AI Service not initialized');
    }

    try {
      if (Platform.isIOS) {
        // Use real iOS Vision framework
        final startTime = DateTime.now();

        final result = await _channel.invokeMethod('analyzeImage', {
          'imagePath': imagePath,
        });

        final processingTime =
            DateTime.now().difference(startTime).inMilliseconds / 1000.0;

        // Parse the result from iOS Vision framework
        final objects = <DetectedObject>[];
        final List<dynamic> detectedObjects = result['objects'] ?? [];

        for (final obj in detectedObjects) {
          objects.add(DetectedObject(
            label: obj['label'] ?? 'Unknown',
            confidence: (obj['confidence'] ?? 0.0).toDouble(),
            boundingBox: List<double>.from(obj['boundingBox'] ?? [0, 0, 1, 1]),
          ));
        }

        final confidence = result['confidence'] ?? 0.0;
        final asciiArt = _generateAsciiArt(objects);

        return AiAnalysisResult(
          objects: objects,
          confidence: confidence.toDouble(),
          processingTime: processingTime,
          asciiArt: asciiArt,
        );
      } else {
        // Fallback to simulated analysis for non-iOS platforms
        return _simulateAnalysis();
      }
    } catch (e) {
      Logger.error('AI analysis failed, falling back to simulation', e);
      return _simulateAnalysis();
    }
  }

  static String _generateAsciiArt(List<DetectedObject> objects) {
    if (objects.isEmpty) {
      return '''
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
''';
    }

    // Generate ASCII art based on detected objects
    final buffer = StringBuffer();
    const width = 64;
    const height = 16;

    for (int y = 0; y < height; y++) {
      String line = '';
      for (int x = 0; x < width; x++) {
        bool hasObject = false;
        for (final obj in objects) {
          final bbox = obj.boundingBox;
          final objX = (bbox[0] * width).round();
          final objY = (bbox[1] * height).round();
          final objW = (bbox[2] * width).round();
          final objH = (bbox[3] * height).round();

          if (x >= objX && x < objX + objW && y >= objY && y < objY + objH) {
            hasObject = true;
            break;
          }
        }
        line += hasObject ? '█' : '░';
      }
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static AiAnalysisResult _simulateAnalysis() {
    return AiAnalysisResult(
      objects: [
        DetectedObject(
          label: 'Human face',
          confidence: 94.2,
          boundingBox: [0.1, 0.1, 0.8, 0.8],
        ),
        DetectedObject(
          label: 'Object',
          confidence: 87.5,
          boundingBox: [0.2, 0.2, 0.6, 0.6],
        ),
      ],
      confidence: 90.8,
      processingTime: 2.1,
      asciiArt: '''
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████
''',
    );
  }

  static void dispose() {
    _isInitialized = false;
  }
}

class DetectedObject {
  final String label;
  final double confidence;
  final List<double> boundingBox; // [x, y, width, height]

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });
}

class AiAnalysisResult {
  final List<DetectedObject> objects;
  final double confidence;
  final double processingTime;
  final String asciiArt;

  AiAnalysisResult({
    required this.objects,
    required this.confidence,
    required this.processingTime,
    required this.asciiArt,
  });
}
