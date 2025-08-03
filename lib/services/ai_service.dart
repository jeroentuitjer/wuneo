import 'logger.dart';

class AiService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      // For now, we'll use simulated mode
      // In the future, we can add real AI models
      Logger.info('AI Service initialized in simulated mode');
      _isInitialized = true;
    } catch (e) {
      Logger.error('Failed to initialize AI Service', e);
      _isInitialized = false;
    }
  }

  static Future<AiAnalysisResult> analyzeImage(String imagePath) async {
    // Always use simulated analysis for now
    return _simulateAnalysis();
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
