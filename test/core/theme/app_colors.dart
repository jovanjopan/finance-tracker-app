import 'package:flutter/material.dart';

/// Palet "Dusty Twilight" — dark mode (v1).
/// Disepakati sebagai tema pixel-art untuk finance tracker.
class AppColors {
  AppColors._();

  // Surface / background
  static const Color background = Color(0xFF241E2B);
  static const Color surface = Color(0xFF372E42);
  static const Color surfaceAlt = Color(0xFF2F2738); // bottom nav, elemen sekunder

  // Brand / interaktif utama
  static const Color primary = Color(0xFF9E88B5); // lavender berdebu

  // Semantik transaksi
  static const Color positive = Color(0xFF8FAE93); // income / masuk (sage)
  static const Color negative = Color(0xFFC98A72); // expense / keluar (terracotta)

  // Gamifikasi (XP, badge, CTA utama)
  static const Color accentGamify = Color(0xFFDDB05C); // mustard

  // Teks
  static const Color textPrimary = Color(0xFFF0E6D8); // krem hangat
  static const Color textSecondary = Color(0xFFC9BFCF);
  static const Color textMuted = Color(0xFF8B7F92);

  // Border / outline
  static const Color border = Color(0xFF6B5F73);
}