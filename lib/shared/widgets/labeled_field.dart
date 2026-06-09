import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/shared/widgets/section_title.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
