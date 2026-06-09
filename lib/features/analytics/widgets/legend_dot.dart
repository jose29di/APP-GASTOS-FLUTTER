import 'package:flutter/material.dart';

class LegendDot extends StatelessWidget {
  const LegendDot({
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
