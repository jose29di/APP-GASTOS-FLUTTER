import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/theme/app_colors.dart';
import 'package:gastos_erp_tracker/core/utils/money_formatter.dart';

class BarComparisonChart extends StatelessWidget {
  const BarComparisonChart({
    required this.deductible,
    required this.nonDeductible,
    super.key,
  });

  final double deductible;
  final double nonDeductible;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarComparisonPainter(
        deductible: deductible,
        nonDeductible: nonDeductible,
        textColor: Theme.of(context).colorScheme.onSurface,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
      ),
      size: Size.infinite,
    );
  }
}

class BarComparisonPainter extends CustomPainter {
  BarComparisonPainter({
    required this.deductible,
    required this.nonDeductible,
    required this.textColor,
    required this.gridColor,
  });

  final double deductible;
  final double nonDeductible;
  final Color textColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(deductible, nonDeductible);
    final chartHeight = size.height - 34;
    final barWidth = size.width * .22;
    final gap = size.width * .14;
    final x1 = size.width * .22;
    final x2 = x1 + barWidth + gap;
    final paint = Paint()..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    void drawBar(double x, double value, Color color, String label) {
      final height = chartHeight * (value / maxValue);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - height, barWidth, height),
        const Radius.circular(8),
      );
      paint.color = color;
      canvas.drawRRect(rect, paint);
      _drawText(canvas, label, Offset(x + barWidth / 2, chartHeight + 10), 12);
      _drawText(canvas, currency(value), Offset(x + barWidth / 2, chartHeight - height - 18), 12);
    }

    drawBar(x1, deductible, AppColors.income, 'Deducible');
    drawBar(x2, nonDeductible, AppColors.expense, 'No deducible');
  }

  void _drawText(Canvas canvas, String text, Offset center, double size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: textColor, fontSize: size, fontWeight: FontWeight.w700)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant BarComparisonPainter oldDelegate) {
    return oldDelegate.deductible != deductible || oldDelegate.nonDeductible != nonDeductible;
  }
}
