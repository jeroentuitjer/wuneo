import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/ai_service.dart';
import '../services/camera_service.dart';
import '../services/weather_service.dart';
import '../services/logger.dart';
import '../cubits/camera_analysis/camera_analysis_cubit.dart';
import '../widgets/ascii/ascii_art_animator.dart';
import '../widgets/ascii/ascii_clock.dart';
import '../widgets/ascii/weather_animator.dart';

class StartProgramPage extends StatelessWidget {
  const StartProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cameraService = CameraService();
        final cubit = CameraAnalysisCubit(cameraService: cameraService);

        // Set up callback to notify cubit when images are captured
        cameraService.setImageCaptureCallback((imagePath) {
          cubit.onImageCaptured(imagePath);
        });

        return cubit;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ASCII Clock in top left
              const AsciiClock(),
              const SizedBox(height: 20),

              // Program content area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnalysisInterface(),
                      ],
                    ),
                  ),
                ),
              ),

              // Weather animator at the bottom
              const SizedBox(height: 10),
              const WeatherAnimator(),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisInterface extends StatefulWidget {
  const AnalysisInterface({super.key});

  @override
  State<AnalysisInterface> createState() => _AnalysisInterfaceState();
}

class _AnalysisInterfaceState extends State<AnalysisInterface> {
  final CameraService _cameraService = CameraService();
  String _output = 'INITIALIZING SYSTEM...\n\nLoading TensorFlow Lite...';
  bool _isProcessing = false;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    try {
      await AiService.initialize();
      await WeatherService.initialize();
      await _cameraService.checkEnvironment();

      if (_cameraService.isSimulator) {
        setState(() {
          _output = '''
SIMULATOR MODE DETECTED
══════════════════════════════════════════════

Running in iOS Simulator.
Local analysis is available.

Tap to perform image analysis.
''';
        });
      } else if (!_cameraService.isInitialized) {
        setState(() {
          _output = '''
CAMERA PERMISSION REQUIRED
══════════════════════════════════════════════

This app needs camera access to perform
local image analysis.

Camera will automatically capture small photos
every 10 seconds for analysis.

Please grant camera permission to continue.
''';
        });
      } else {
        setState(() {
          _output =
              'SYSTEM READY\n\nLocal TensorFlow Lite model loaded.\nAutomatic photo capture active (every 10s).\nTap to analyze latest photo.';
        });
      }
    } catch (e) {
      Logger.error('Failed to initialize system', e);
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() {
      _permissionRequested = true;
      _output =
          'REQUESTING CAMERA PERMISSION...\n\nPlease allow camera access.';
    });

    await _cameraService.requestCameraPermission();

    if (_cameraService.isInitialized) {
      setState(() {
        _output =
            'SYSTEM READY\n\nLocal TensorFlow Lite model loaded.\nAutomatic photo capture active (every 10s).\nTap to analyze latest photo.';
        _permissionRequested = false;
      });
    } else {
      setState(() {
        _output = '''
PERMISSION DENIED
══════════════════════════════════════════════

Camera access was denied.
Please enable camera access in Settings:
Settings > Privacy & Security > Camera > Wuneo

Or tap the button below to try again.
''';
        _permissionRequested = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    AiService.dispose();
    WeatherService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraAnalysisCubit, CameraAnalysisState>(
      builder: (context, state) {
        // Update output based on state
        if (state is CameraAnalysisSuccess) {
          if (state.isProcessing) {
            _output = 'ANALYZING LATEST PHOTO...\n\nRunning local analysis...';
            _isProcessing = true;
          } else if (state.lastAnalysis != null) {
            final analysis = state.lastAnalysis!;
            final objectsText = analysis.objects
                .map((obj) =>
                    '• ${obj.label} (confidence: ${obj.confidence.toStringAsFixed(1)}%)')
                .join('\n');

            _output = '''
ANALYSIS COMPLETE
══════════════════════════════════════════════

DETECTED OBJECTS:
$objectsText

ASCII RENDERING:
${analysis.asciiArt}

CONFIDENCE: ${analysis.confidence.toStringAsFixed(1)}%
PROCESSING TIME: ${analysis.processingTime.toStringAsFixed(1)}s
LOCAL ANALYSIS: ACTIVE
AUTO CAPTURE: ACTIVE (10s intervals)
ANIMATION VARIABLES: ${state.animationVariables.length} active
''';
            _isProcessing = false;
          }
        } else if (state is CameraAnalysisError) {
          _output = 'ERROR: Analysis failed\n\n${state.message}';
          _isProcessing = false;
        }

        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ASCII Art Animator - takes most of the space
              Expanded(
                flex: 8, // Give most space to animation
                child: AsciiArtAnimator(
                  aiInput: _output,
                  isProcessing: _isProcessing,
                ),
              ),
              const SizedBox(height: 10),

              // Add permission request button when needed
              if (!_cameraService.isInitialized && !_cameraService.isSimulator)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _permissionRequested ? null : _requestCameraPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _permissionRequested
                          ? 'REQUESTING...'
                          : 'GRANT CAMERA PERMISSION',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
