import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.large = false,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(large ? 18 : 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    value,
                    style: (large ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w900, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
