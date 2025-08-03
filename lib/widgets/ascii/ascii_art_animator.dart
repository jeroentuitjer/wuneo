import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import '../../services/logger.dart';
import '../../services/ascii_art_service.dart';

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
  String _currentAsciiArt = '';
  int _frameIndex = 0;
  final Random _random = Random();

  // Color animation variables
  List<Color> _colorPalette = [];
  int _colorIndex = 0;
  double _colorShift = 0.0;

  // Photo counter (simplified)
  int _photosAnalyzed = 0;
  int _totalPhotosCaptured = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Initialize color palette
    _initializeColorPalette();

    // Initialize ASCII art service
    _initializeAsciiArtService();

    // Update colors and ASCII art
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _updateColors();
          _updateAsciiArt();
        });
      }
    });

    _animationController.repeat();
  }

  void _initializeColorPalette() {
    _colorPalette = [
      Colors.cyan,
      Colors.pink,
      Colors.yellow,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.lime,
      Colors.deepPurple,
    ];
  }

  Future<void> _initializeAsciiArtService() async {
    await AsciiArtService.initialize();
    AsciiArtService.instance.startPeriodicUpdates();
    _updateAsciiArt();
  }

  void _updateColors() {
    _colorShift += 0.05; // Faster color change
    if (_colorShift >= 1.0) {
      _colorShift = 0.0;
      _colorIndex = (_colorIndex + 1) % _colorPalette.length;
    }
  }

  void _updateAsciiArt() {
    final newAsciiArt = AsciiArtService.instance.getCurrentAsciiArt();
    if (newAsciiArt.isNotEmpty) {
      setState(() {
        _currentAsciiArt = newAsciiArt;
        _photosAnalyzed++;
        _totalPhotosCaptured++;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer.cancel();
    AsciiArtService.instance.stopPeriodicUpdates();
    super.dispose();
  }

  Color _getCurrentColor() {
    // Create smooth color transitions
    final baseColor = _colorPalette[_colorIndex];
    final nextColor = _colorPalette[(_colorIndex + 1) % _colorPalette.length];

    // Interpolate between colors for smooth transitions
    return Color.lerp(baseColor, nextColor, _colorShift) ?? baseColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Get animation progress for color changes
        final animationProgress = _animationController.value;

        final colorIntensity = 0.8;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Use full screen width without padding
            final availableWidth = constraints.maxWidth;
            const charWidth = 6.0;
            final maxChars = (availableWidth / charWidth).floor();

            // Split ASCII art into lines
            final asciiLines = _currentAsciiArt.split('\n');

            // Adjust ASCII art to fit screen width and use full height
            final adjustedLines = asciiLines.map((line) {
              if (line.length > maxChars) {
                return line.substring(0, maxChars);
              } else if (line.length < maxChars) {
                return line.padRight(maxChars, ' ');
              }
              return line;
            }).toList();

            // Use full available height
            final availableHeight = constraints.maxHeight;
            const charHeight = 12.0; // Approximate height of each character
            final maxLines = (availableHeight / charHeight).floor();

            // Adjust to fit screen height
            if (adjustedLines.length > maxLines) {
              // Take middle section to fit screen
              final startIndex = (adjustedLines.length - maxLines) ~/ 2;
              final endIndex = startIndex + maxLines;
              final displayLines = adjustedLines.sublist(startIndex, endIndex);
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    displayLines.join('\n'),
                    style: GoogleFonts.pressStart2p(
                      color: widget.isProcessing
                          ? Colors.yellow.withValues(alpha: colorIntensity)
                          : _getCurrentColor()
                              .withValues(alpha: colorIntensity),
                      fontSize: 8,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            } else {
              // Pad with empty lines to fill screen
              final paddingLines = maxLines - adjustedLines.length;
              final emptyLines =
                  List.generate(paddingLines, (index) => ' ' * maxChars);
              final displayLines = [...adjustedLines, ...emptyLines];

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    displayLines.join('\n'),
                    style: GoogleFonts.pressStart2p(
                      color: widget.isProcessing
                          ? Colors.yellow.withValues(alpha: colorIntensity)
                          : _getCurrentColor()
                              .withValues(alpha: colorIntensity),
                      fontSize: 8,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
