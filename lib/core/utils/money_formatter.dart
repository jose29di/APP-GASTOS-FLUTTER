String currency(num value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final buffer = StringBuffer();

  for (var i = 0; i < parts.first.length; i++) {
    final indexFromEnd = parts.first.length - i;
    buffer.write(parts.first[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return '\$${buffer.toString()}.${parts.last}';
}
