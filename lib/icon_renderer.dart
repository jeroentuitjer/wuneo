import 'package:flutter/material.dart';
import 'widgets/ascii/ascii_logo.dart';

class IconRenderer extends StatefulWidget {
  const IconRenderer({super.key});

  @override
  State<IconRenderer> createState() => _IconRendererState();
}

class _IconRendererState extends State<IconRenderer> {
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
}
