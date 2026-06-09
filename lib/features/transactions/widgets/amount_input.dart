import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInput extends StatelessWidget {
  const AmountInput({
    required this.controller,
    required this.color,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: .09), Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monto', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: color,
                ),
            decoration: const InputDecoration(
              prefixText: r'$ ',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
