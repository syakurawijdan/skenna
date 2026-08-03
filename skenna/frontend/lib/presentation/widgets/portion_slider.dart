import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PortionSlider extends StatelessWidget {
  const PortionSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.thumbColor,
    this.enabled = true,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color thumbColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final range = max - min;
    final fraction = range <= 0 ? 0.0 : (value - min) / range;
    final divisions = range > 0 ? (range * 2).round() : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const thumbRadius = 12.0;
        const horizontalPadding = 16.0;
        final usableWidth = trackWidth - horizontalPadding * 2;
        final thumbX = horizontalPadding + usableWidth * fraction;
        const boxW = 36.0;
        const boxH = 32.0;
        final boxLeft = (thumbX - boxW / 2).clamp(0.0, trackWidth - boxW);

        return SizedBox(
          height: boxH + 8 + thumbRadius * 2 + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: boxLeft,
                top: 0,
                child: Container(
                  width: boxW,
                  height: boxH,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _formatValue(value),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: thumbX - 5,
                top: boxH,
                child: CustomPaint(
                  painter: _TrianglePainter(color: thumbColor),
                  size: const Size(10, 6),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: thumbColor,
                    thumbColor: thumbColor,
                    inactiveTrackColor: const Color(0xFFD7DCE8),
                    overlayColor: thumbColor.withValues(alpha: 0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: thumbRadius,
                    ),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: Slider(
                      value: value.clamp(min, math.max(min, max)),
                      min: min,
                      max: math.max(min, max),
                      divisions: divisions,
                      onChanged: (v) => onChanged((v * 2).round() / 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
