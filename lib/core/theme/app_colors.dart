import 'package:flutter/material.dart';

abstract class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F0F16);
  static const Color surface = Color(0xFF171722);
  static const Color surfaceLight = Color(0xFF212130);
  static const Color surfaceBorder = Color(0xFF2A2A3D);

  // Accents
  static const Color indigoAccent = Color(0xFF6366F1);
  static const Color violetAccent = Color(0xFF8B5CF6);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color roseAccent = Color(0xFFF43F5E);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color amberAccent = Color(0xFFF59E0B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [indigoAccent, violetAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowingBorderGradient = LinearGradient(
    colors: [Color(0x666366F1), Color(0x338B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Provider colors
  static const Color groqBrand = Color(0xFFF97316); // Orange accent for Groq
  static const Color nvidiaBrand = Color(0xFF76B900); // NVIDIA green
}
