import 'package:flutter/material.dart';
import 'dart:async';

class AsciiClock extends StatefulWidget {
  const AsciiClock({super.key});

  @override
  State<AsciiClock> createState() => _AsciiClockState();
}

class _AsciiClockState extends State<AsciiClock> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final now = _now.toLocal();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      return Text(
        timeStr,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2.0,
        ),
        textAlign: TextAlign.center,
      );
    } catch (e) {
      return const Text(
        '--:--',
        style: TextStyle(
          color: Colors.red,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2.0,
        ),
        textAlign: TextAlign.center,
      );
    }
  }
}
