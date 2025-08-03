import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'widgets/ascii/ascii_logo.dart';

class IconGenerator extends StatefulWidget {
  const IconGenerator({super.key});

  @override
  State<IconGenerator> createState() => _IconGeneratorState();
}

class _IconGeneratorState extends State<IconGenerator> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RepaintBoundary(
            key: _globalKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const AsciiLogo(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> generateIcons() async {
    // Define iOS icon sizes
    final iconSizes = [
      20,
      29,
      40,
      58,
      60,
      76,
      80,
      87,
      120,
      152,
      167,
      180,
      1024
    ];

    for (final size in iconSizes) {
      await generateIcon(size);
    }
  }

  Future<void> generateIcon(int size) async {
    // Wait for the widget to be built
    await Future.delayed(const Duration(milliseconds: 100));

    // Capture the widget as an image
    final boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Save to iOS assets folder
    final directory =
        Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName = 'Icon-App-${size}x$size@1x.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    debugPrint('Generated: $fileName');
  }
}
