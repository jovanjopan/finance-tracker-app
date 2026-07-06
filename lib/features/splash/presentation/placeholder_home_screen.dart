import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: _PlaceholderText(),
      ),
    );
  }
}

class _PlaceholderText extends StatelessWidget {
  const _PlaceholderText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Onboarding & Dashboard belum dibuat',
      textAlign: TextAlign.center,
      style: GoogleFonts.vt323(
        fontSize: 22,
        color: AppColors.textPrimary,
      ),
    );
  }
}