import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';

/// Menganimasikan perubahan nilai uang dari angka lama ke angka baru
/// (count-up/count-down), bukan langsung berganti instan.
class AnimatedCurrencyText extends StatelessWidget {
  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  final double value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, animatedValue, child) {
        return Text(CurrencyFormatter.format(animatedValue), style: style);
      },
    );
  }
}