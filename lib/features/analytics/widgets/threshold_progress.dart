import 'package:flutter/material.dart';

class ThresholdProgress extends StatelessWidget {
  const ThresholdProgress({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
    super.key,
  });

  final String label;
  final double value;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(amount, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            minHeight: 10,
            color: color,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
