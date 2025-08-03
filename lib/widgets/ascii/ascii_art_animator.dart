import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/camera_analysis/camera_analysis_cubit.dart';
import '../../services/logger.dart';

class AsciiArtAnimator extends StatefulWidget {
  final String aiInput;
  final bool isProcessing;

  const AsciiArtAnimator({
    super.key,
    required this.aiInput,
    required this.isProcessing,
  });

  @override
  State<AsciiArtAnimator> createState() => _AsciiArtAnimatorState();
}

class _AsciiArtAnimatorState extends State<AsciiArtAnimator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _updateTimer;
  List<String> _currentFrame = [];
  int _frameIndex = 0;
  final Random _random = Random();

  // Animation variables from Bloc
  Map<String, double> _animationVariables = {
    'speed': 1.0,
    'intensity': 0.5,
    'complexity': 0.3,
    'brightness': 0.7,
    'contrast': 0.5,
    'waveFrequency': 1.0,
    'noiseLevel': 0.2,
    'patternDensity': 0.4,
  };

  // Person detection state
  bool _personDetected = false;
  double _personProgress = 0.0;

  // ASCII art patterns
  final List<String> _patterns = [
    '█▓▒░',
    '░▒▓█',
    '▄▀▄▀',
    '▀▄▀▄',
    '╔═╗║',
    '╚═╝║',
    '┌─┐│',
    '└─┘│',
    '◢◣◤◥',
    '◤◥◢◣',
    '▌▐▌▐',
    '▐▌▐▌',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Very slow animation: 1 frame every 10 seconds for non-distracting background
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _updateFrame();
        });
      }
    });

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer.cancel();
    super.dispose();
  }

  void _updateFrame() {
    if (!mounted) return;

    if (widget.isProcessing) {
      _generateProcessingFrame();
    } else {
      _generateArtisticFrame();
    }
  }

  void _generateProcessingFrame() {
    // Use full screen width - will be calculated in build method
    const height = 40; // Much more height for larger animation
    _currentFrame = [];

    final speed = _animationVariables['speed'] ?? 1.0;
    final intensity = _animationVariables['intensity'] ?? 0.5;
    final noiseLevel = _animationVariables['noiseLevel'] ?? 0.2;
    final waveFrequency = _animationVariables['waveFrequency'] ?? 1.0;

    for (int y = 0; y < height; y++) {
      String line = '';
      // Width will be set dynamically based on screen size
      const width = 200; // Much wider for full screen
      for (int x = 0; x < width; x++) {
        final noise = _random.nextDouble();
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0 * speed;
        final wave = (sin(time * 2 * waveFrequency + x * 0.2) +
                sin(time * 1.5 * waveFrequency + y * 0.3)) /
            2;

        if (noise < (noiseLevel + wave * intensity)) {
          line += _patterns[_frameIndex % _patterns.length][_random.nextInt(4)];
        } else {
          line += ' ';
        }
      }
      _currentFrame.add(line);
    }
    _frameIndex++;
  }

  void _generateArtisticFrame() {
    // Parse input for artistic inspiration
    final hasObjects = widget.aiInput.contains('DETECTED OBJECTS:');
    final hasConfidence = widget.aiInput.contains('CONFIDENCE:');

    if (hasObjects && hasConfidence) {
      _generateObjectBasedArt();
    } else {
      _generateAbstractArt();
    }
  }

  void _generateObjectBasedArt() {
    // Use full screen width - will be calculated in build method
    const height = 40; // Much more height for larger animation
    _currentFrame = [];

    final complexity = _animationVariables['complexity'] ?? 0.3;
    final patternDensity = _animationVariables['patternDensity'] ?? 0.4;
    final waveFrequency = _animationVariables['waveFrequency'] ?? 1.0;

    // Extract objects from input
    final lines = widget.aiInput.split('\n');
    final objects = <String>[];
    bool inObjectsSection = false;

    for (final line in lines) {
      if (line.contains('DETECTED OBJECTS:')) {
        inObjectsSection = true;
        continue;
      }
      if (line.contains('ASCII RENDERING:') || line.contains('CONFIDENCE:')) {
        break;
      }
      if (inObjectsSection && line.trim().isNotEmpty) {
        objects.add(line.trim());
      }
    }

    // Generate art based on detected objects
    for (int y = 0; y < height; y++) {
      String line = '';
      // Width will be set dynamically based on screen size
      const width = 200; // Much wider for full screen
      for (int x = 0; x < width; x++) {
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final objectIndex = (x + y) % objects.length;
        final object = objects.isNotEmpty ? objects[objectIndex] : 'object';

        // Create patterns based on object type with Bloc variables
        if (object.toLowerCase().contains('person')) {
          line += _createPersonPattern(x, y, time, complexity, patternDensity);
        } else if (object.toLowerCase().contains('car') ||
            object.toLowerCase().contains('vehicle')) {
          line +=
              _createVehiclePattern(x, y, time, waveFrequency, patternDensity);
        } else if (object.toLowerCase().contains('building') ||
            object.toLowerCase().contains('house')) {
          line +=
              _createBuildingPattern(x, y, time, complexity, patternDensity);
        } else {
          line += _createGenericPattern(x, y, time, object, patternDensity);
        }
      }
      _currentFrame.add(line);
    }
  }

  String _createPersonPattern(
      int x, int y, double time, double complexity, double density) {
    final wave = sin(time * 2 + x * 0.1 * complexity);
    final threshold = 0.5 + (density * 0.3);
    if (wave > threshold) return '█';
    if (wave > threshold * 0.7) return '▓';
    if (wave > threshold * 0.3) return '▒';
    return '░';
  }

  String _createVehiclePattern(
      int x, int y, double time, double waveFreq, double density) {
    final wave = cos(time * 1.5 * waveFreq + y * 0.2);
    final threshold = 0.5 + (density * 0.3);
    if (wave > threshold) return '▄';
    if (wave > threshold * 0.7) return '▀';
    if (wave > threshold * 0.3) return '▌';
    return '▐';
  }

  String _createBuildingPattern(
      int x, int y, double time, double complexity, double density) {
    final wave = sin(time * 0.8 + x * 0.3 * complexity);
    final threshold = 0.5 + (density * 0.3);
    if (wave > threshold) return '╔';
    if (wave > threshold * 0.7) return '╗';
    if (wave > threshold * 0.3) return '║';
    if (wave > threshold * 0.1) return '═';
    return ' ';
  }

  String _createGenericPattern(
      int x, int y, double time, String object, double density) {
    final hash = object.hashCode;
    final wave = sin(time + hash * 0.1);
    final pattern = _patterns[hash % _patterns.length];
    final charIndex = (x + y + hash) % 4;
    final threshold = 0.5 + (density * 0.3);
    return wave > threshold ? pattern[charIndex] : ' ';
  }

  void _generateAbstractArt() {
    // Use full screen width - will be calculated in build method
    const height = 40; // Much more height for larger animation
    _currentFrame = [];

    final brightness = _animationVariables['brightness'] ?? 0.7;
    final contrast = _animationVariables['contrast'] ?? 0.5;
    final intensity = _animationVariables['intensity'] ?? 0.5;

    for (int y = 0; y < height; y++) {
      String line = '';
      // Width will be set dynamically based on screen size
      const width = 200; // Much wider for full screen
      for (int x = 0; x < width; x++) {
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final wave1 = sin(time * 1.2 + x * 0.1);
        final wave2 = cos(time * 0.8 + y * 0.15);
        final combined = (wave1 + wave2) / 2 * intensity;

        final threshold = brightness + (contrast * 0.3);
        if (combined > threshold) {
          line += '█';
        } else if (combined > threshold * 0.7) {
          line += '▓';
        } else if (combined > threshold * 0.3) {
          line += '▒';
        } else if (combined > threshold * 0.1) {
          line += '░';
        } else {
          line += ' ';
        }
      }
      _currentFrame.add(line);
    }
  }

  String _generateProgressBar(double progress, int width) {
    final filledWidth = (width * progress).round();
    final emptyWidth = width - filledWidth;

    String bar = '';
    for (int i = 0; i < filledWidth; i++) {
      bar += '█';
    }
    for (int i = 0; i < emptyWidth; i++) {
      bar += '░';
    }
    return bar;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraAnalysisCubit, CameraAnalysisState>(
      listener: (context, state) {
        if (state is CameraAnalysisSuccess) {
          setState(() {
            _animationVariables = state.animationVariables;
            _personDetected = state.personDetected;
            _personProgress = state.personProgress;
          });
        }
      },
      child: Builder(
        builder: (context) {
          final brightness = _animationVariables['brightness'] ?? 0.7;
          final colorIntensity = brightness;

          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width based on available space
              final availableWidth =
                  constraints.maxWidth - 16; // Account for padding
              const charWidth = 6.0; // Approximate width of each character
              final maxChars = (availableWidth / charWidth).floor();

              // Adjust current frame to fit screen width
              final adjustedFrame = _currentFrame.map((line) {
                if (line.length > maxChars) {
                  return line.substring(0, maxChars);
                } else if (line.length < maxChars) {
                  return line.padRight(maxChars, ' ');
                }
                return line;
              }).toList();

              // Add progress bar if person is detected
              if (_personDetected) {
                final progressBar =
                    _generateProgressBar(_personProgress, maxChars);
                final progressText =
                    'PERSON DETECTED: ${(_personProgress * 100).round()}%';
                final progressLine = progressText.padRight(maxChars, ' ');

                // Insert progress bar in the middle of the animation
                final middleIndex = adjustedFrame.length ~/ 2;
                adjustedFrame.insert(middleIndex, progressBar);
                adjustedFrame.insert(middleIndex, progressLine);
                adjustedFrame.insert(middleIndex, ''); // Empty line for spacing

                // Add debug info
                Logger.debug(
                    'Person detected: $_personDetected, Progress: $_personProgress');
              }

              return Container(
                width: double.infinity,
                height: constraints.maxHeight -
                    100, // Use almost full height, leave space for status
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    adjustedFrame.join('\n'),
                    style: GoogleFonts.pressStart2p(
                      color: widget.isProcessing
                          ? Colors.yellow.withValues(alpha: colorIntensity)
                          : _personDetected
                              ? Colors.red.withValues(alpha: colorIntensity)
                              : Colors.cyan.withValues(alpha: colorIntensity),
                      fontSize: 8, // Slightly larger font
                      height: 1.0,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
