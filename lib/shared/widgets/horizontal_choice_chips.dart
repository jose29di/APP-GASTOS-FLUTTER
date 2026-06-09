import 'package:flutter/material.dart';

class HorizontalChoiceChips extends StatelessWidget {
  const HorizontalChoiceChips({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.leadingIcons = const {},
    super.key,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, IconData> leadingIcons;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: leadingIcons[value] == null ? null : Icon(leadingIcons[value], size: 18),
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
