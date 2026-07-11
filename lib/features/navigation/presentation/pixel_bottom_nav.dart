import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class PixelBottomNavItem {
  const PixelBottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class PixelBottomNav extends StatelessWidget {
  const PixelBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<PixelBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(items.length, (index) {
          final isActive = index == currentIndex;
          final item = items[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isActive) {
                  HapticFeedback.selectionClick();
                  onTap(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accentGamify : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isActive ? AppColors.background : AppColors.textMuted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.vt323(
                        fontSize: 13,
                        color: isActive ? AppColors.background : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}