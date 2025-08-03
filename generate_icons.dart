import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lib/services/logger.dart';

void main() async {
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Generate icons
  await generateIcons();

  // Update Contents.json
  await updateContentsJson();

  Logger.info('iOS app icons generated successfully!');
  exit(0);
}

Future<void> generateIcons() async {
  final iconSizes = [
    {'size': 20, 'scale': 1},
    {'size': 20, 'scale': 2},
    {'size': 20, 'scale': 3},
    {'size': 29, 'scale': 1},
    {'size': 29, 'scale': 2},
    {'size': 29, 'scale': 3},
    {'size': 40, 'scale': 1},
    {'size': 40, 'scale': 2},
    {'size': 40, 'scale': 3},
    {'size': 60, 'scale': 2},
    {'size': 60, 'scale': 3},
    {'size': 76, 'scale': 1},
    {'size': 76, 'scale': 2},
    {'size': 83.5, 'scale': 2},
    {'size': 1024, 'scale': 1},
  ];

  for (final iconConfig in iconSizes) {
    await generateIcon(
        iconConfig['size'] as double, iconConfig['scale'] as int);
  }
}

Future<void> generateIcon(double size, int scale) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final actualSize = (size * scale).round();

  // Create a white background
  final paint = Paint()..color = Colors.white;
  canvas.drawRect(
      Rect.fromLTWH(0, 0, actualSize.toDouble(), actualSize.toDouble()), paint);

  // Create ASCII art text
  final textStyle = GoogleFonts.pressStart2p(
    color: Colors.black,
    fontSize: actualSize / 20,
  );

  // WUNEO ASCII Art
  final lines = [
    '██     ██ ██   ██ ██   ██ ███████ ██████',
    '██  █  ██ ██   ██ ███  ██ ██      ██    ██',
    '██ ███ ██ ██   ██ ████ ██ █████   ██    ██',
    '████ ██ ██   ██ ██ ████ ██      ██    ██',
    ' ██ ██  ██████  ██  ███ ███████  ██████',
  ];

  double yOffset = actualSize * 0.1;
  for (final line in lines) {
    final textSpan = TextSpan(text: line, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final xOffset = (actualSize - textPainter.width) / 2;
    textPainter.paint(canvas, Offset(xOffset, yOffset));
    yOffset += textPainter.height + 2;
  }

  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(actualSize, actualSize);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Save to iOS assets folder
  final directory = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final fileName = 'Icon-App-${size.toInt()}x${size.toInt()}@${scale}x.png';
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);

  Logger.info('Generated: $fileName');
}

Future<void> updateContentsJson() async {
  const contentsJson = '''
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

  final directory = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  final file = File('${directory.path}/Contents.json');
  await file.writeAsString(contentsJson);

  Logger.info('Updated Contents.json');
}
