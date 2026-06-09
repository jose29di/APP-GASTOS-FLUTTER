import 'package:flutter/material.dart';

class DateHeader extends StatelessWidget {
  const DateHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
}
