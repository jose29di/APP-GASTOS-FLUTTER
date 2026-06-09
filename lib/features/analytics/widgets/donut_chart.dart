import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/features/analytics/models/chart_segment.dart';

class DonutChart extends StatelessWidget {
  const DonutChart({required this.segments, super.key});

  final List<ChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DonutPainter(segments, Theme.of(context).colorScheme.surfaceContainerHighest),
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.segments, this.track);

  final List<ChartSegment> segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    paint.color = track;
    canvas.drawArc(rect.deflate(12), 0, math.pi * 2, false, paint);

    var start = -math.pi / 2;
    for (final segment in segments) {
      paint.color = segment.color;
      final sweep = math.pi * 2 * segment.value;
      canvas.drawArc(rect.deflate(12), start, sweep - .04, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => oldDelegate.segments != segments;
}
