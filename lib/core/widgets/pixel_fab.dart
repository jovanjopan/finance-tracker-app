import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class PixelFab extends StatefulWidget {
  const PixelFab({super.key, required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  State<PixelFab> createState() => _PixelFabState();
}

class _PixelFabState extends State<PixelFab> {
  bool _isPressed = false;
  static const double _depth = 4;
  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        width: _size,
        height: _size + _depth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: _depth,
              height: _size,
              child: Container(color: AppColors.background),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _isPressed ? _depth : 0,
              height: _size,
              child: Container(
                color: AppColors.accentGamify,
                alignment: Alignment.center,
                child: Icon(widget.icon, color: AppColors.background),
              ),
            ),
          ],
        ),
      ),
    );
  }
}