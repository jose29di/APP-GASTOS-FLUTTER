import 'package:flutter/material.dart';

class ChartSegment {
  const ChartSegment(this.color, this.value, {this.label});

  final Color color;
  final double value;
  final String? label;
}
