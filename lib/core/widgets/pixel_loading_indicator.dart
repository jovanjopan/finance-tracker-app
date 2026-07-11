import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PixelLoadingIndicator extends StatefulWidget {
  const PixelLoadingIndicator({super.key, this.color});

  final Color? color;

  @override
  State<PixelLoadingIndicator> createState() => _PixelLoadingIndicatorState();
}

class _PixelLoadingIndicatorState extends State<PixelLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = index / 3;
            final opacity = 0.35 + 0.65 * ((math.sin((value + phase) * math.pi * 2) + 1) / 2);
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
              child: Opacity(
                opacity: opacity,
                child: Container(width: 8, height: 8, color: color),
              ),
            );
          }),
        );
      },
    );
  }
}