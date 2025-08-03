import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AsciiLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const AsciiLogo({
    super.key,
    this.fontSize = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Colors.grey[400]!;

    return Column(
      children: [
        // WUNEO ASCII Art - Aligned Version
        Text(
          '██     ██ ██   ██ ██   ██ ███████ ██████',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
        Text(
          '██  █  ██ ██   ██ ███  ██ ██      ██    ██',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
        Text(
          '██ ███ ██ ██   ██ ████ ██ █████   ██    ██',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
        Text(
          '████ ██ ██   ██ ██ ████ ██      ██    ██',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
        Text(
          ' ██ ██  ██████  ██  ███ ███████  ██████',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(height: 10),
        // Cool border
        Text(
          '╔══════════════════════════════════════════════╗',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize - 2,
          ),
        ),
        Text(
          '║           WUNEO SYSTEM v1.0                ║',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize - 2,
          ),
        ),
        Text(
          '║         EXP COMPUTING PLATFORM              ║',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize - 2,
          ),
        ),
        Text(
          '╚══════════════════════════════════════════════╝',
          style: GoogleFonts.pressStart2p(
            color: textColor,
            fontSize: fontSize - 2,
          ),
        ),
      ],
    );
  }
}
