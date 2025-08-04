import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AsciiClock extends StatefulWidget {
  const AsciiClock({super.key});

  @override
  State<AsciiClock> createState() => _AsciiClockState();
}

class _AsciiClockState extends State<AsciiClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _asciiDigits(String digits) {
    const ascii = [
      [
        ' __  ',
        '|  | ',
        '|  | ',
        '|  | ',
        '|__| ',
      ], // 0
      [
        '     ',
        '   | ',
        '   | ',
        '   | ',
        '   | ',
      ], // 1
      [
        ' __  ',
        '   | ',
        ' __| ',
        '|    ',
        '|__  ',
      ], // 2
      [
        ' __  ',
        '   | ',
        ' __| ',
        '   | ',
        ' __| ',
      ], // 3
      [
        '     ',
        '|  | ',
        '|__| ',
        '   | ',
        '   | ',
      ], // 4
      [
        ' __  ',
        '|    ',
        '|__  ',
        '   | ',
        ' __| ',
      ], // 5
      [
        ' __  ',
        '|    ',
        '|__  ',
        '|  | ',
        '|__| ',
      ], // 6
      [
        ' __  ',
        '   | ',
        '   | ',
        '   | ',
        '   | ',
      ], // 7
      [
        ' __  ',
        '|  | ',
        '|__| ',
        '|  | ',
        '|__| ',
      ], // 8
      [
        ' __  ',
        '|  | ',
        '|__| ',
        '   | ',
        ' __| ',
      ], // 9
      [
        '     ',
        '  .  ',
        '     ',
        '  .  ',
        '     ',
      ], // :
    ];

    List<String> lines = List.generate(5, (_) => '');
    for (var char in digits.split('')) {
      int idx;
      if (char == ':') {
        idx = 10;
      } else {
        idx = int.parse(char);
      }
      for (int i = 0; i < 5; i++) {
        lines[i] += '${ascii[idx][i]}  ';
      }
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    try {
      final timeStr =
          _now.toLocal().toIso8601String().substring(11, 19); // HH:mm:ss
      final asciiTime = _asciiDigits(timeStr.substring(0, 8));

      return Text(
        asciiTime,
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 8,
          height: 1.1,
          fontFamily: 'monospace',
        ),
      );
    } catch (e) {
      // Fallback if clock fails
      return Text(
        'CLOCK ERROR',
        style: TextStyle(
          color: Colors.red,
          fontSize: 8,
          fontFamily: 'monospace',
        ),
      );
    }
  }
}
