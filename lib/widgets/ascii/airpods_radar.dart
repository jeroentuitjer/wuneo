import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;
import 'dart:math';

class AirpodsRadar extends StatefulWidget {
  final List<blue.ScanResult> airpodsDevices;

  const AirpodsRadar({
    super.key,
    required this.airpodsDevices,
  });

  @override
  State<AirpodsRadar> createState() => _AirpodsRadarState();
}

class _AirpodsRadarState extends State<AirpodsRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Set<String> _seenDevices = {};
  int _totalSeen = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSeenDevices() {
    final currentDevices = widget.airpodsDevices
        .where((device) => device.device.platformName.isNotEmpty)
        .map((device) => device.device.platformName)
        .toSet();

    final newDevices = currentDevices.difference(_seenDevices);
    if (newDevices.isNotEmpty) {
      setState(() {
        _seenDevices.addAll(newDevices);
        _totalSeen += newDevices.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateSeenDevices();

    return Stack(
      children: [
        // Radar background with scan animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: RadarPainter(
                airpodsDevices: widget.airpodsDevices,
                scanAngle: _controller.value * 2 * pi,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Device list overlay
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.greenAccent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${widget.airpodsDevices.where((d) => d.device.platformName.isNotEmpty).length}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Total Seen: $_totalSeen',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                // Terminal-style log of seen devices
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    border:
                        Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEVICE LOG:',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ..._seenDevices.take(8).map((deviceName) => Text(
                              '> $deviceName',
                              style: TextStyle(
                                color: Colors.greenAccent.withOpacity(0.8),
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                            )),
                        if (_seenDevices.length > 8)
                          Text(
                            '> ... +${_seenDevices.length - 8} more',
                            style: TextStyle(
                              color: Colors.greenAccent.withOpacity(0.6),
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RadarPainter extends CustomPainter {
  final List<blue.ScanResult> airpodsDevices;
  final double scanAngle;

  RadarPainter({
    required this.airpodsDevices,
    required this.scanAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        size.width < size.height ? size.width / 2 - 50 : size.height / 2 - 50;

    // Draw radar circles
    final circlePaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, circlePaint);
    }

    // Draw subtle radar sweep
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.greenAccent.withOpacity(0.1),
          Colors.greenAccent.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(scanAngle);

    final sweepPath = Path()
      ..moveTo(0, 0)
      ..lineTo(radius * cos(0), radius * sin(0))
      ..arcToPoint(
        Offset(radius * cos(pi / 6), radius * sin(pi / 6)),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(0, 0);

    canvas.drawPath(sweepPath, sweepPaint);
    canvas.restore();

    // Draw devices
    final devices = airpodsDevices
        .where((device) => device.device.platformName.isNotEmpty)
        .toList();

    for (final device in devices) {
      final deviceName = device.device.platformName;
      final rssi = device.rssi;

      // Calculate position based on RSSI (signal strength)
      final distNorm = (rssi + 100) / 50; // Normalize RSSI to 0-1
      final clampedDist = distNorm.clamp(0.1, 1.0);

      // Random angle for visual distribution
      final angle = (deviceName.hashCode % 360) * pi / 180;
      final dx = center.dx + radius * clampedDist * cos(angle);
      final dy = center.dy + radius * clampedDist * sin(angle);

      // Determine color based on RSSI
      Color dotColor;
      double dotSize;

      if (rssi > -50) {
        dotColor = Colors.green;
        dotSize = 8;
      } else if (rssi > -60) {
        dotColor = Colors.cyan;
        dotSize = 6;
      } else if (rssi > -70) {
        dotColor = Colors.yellow;
        dotSize = 4;
      } else {
        dotColor = Colors.red;
        dotSize = 3;
      }

      // Draw device dot with subtle glow
      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(dx, dy), dotSize + 2, glowPaint);
      canvas.drawCircle(Offset(dx, dy), dotSize, Paint()..color = dotColor);

      // Draw device name
      final textPainter = TextPainter(
        text: TextSpan(
          text: deviceName,
          style: TextStyle(
            color: dotColor,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(dx + dotSize + 5, dy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.airpodsDevices != airpodsDevices ||
        oldDelegate.scanAngle != scanAngle;
  }
}
