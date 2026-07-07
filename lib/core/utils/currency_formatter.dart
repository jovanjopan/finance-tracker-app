class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount) {
    final isNegative = amount < 0;
    final rounded = amount.abs().round();
    final raw = rounded.toString();
    final buffer = StringBuffer();
    final length = raw.length;

    for (var i = 0; i < length; i++) {
      buffer.write(raw[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${isNegative ? '-' : ''}Rp $buffer';
  }
}