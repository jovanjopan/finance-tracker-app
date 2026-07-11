import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.height = 48,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final double height;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;
  static const double _depth = 4;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final fillColor = isDisabled ? AppColors.textMuted : (widget.color ?? AppColors.accentGamify);

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        height: widget.height + _depth,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: _depth,
              height: widget.height,
              child: Container(color: AppColors.background),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _isPressed ? _depth : 0,
              height: widget.height,
              child: Container(
                color: fillColor,
                alignment: Alignment.center,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}