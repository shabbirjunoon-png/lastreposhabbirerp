import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E1B4B);
  static const Color tint = Color(0xFF4F46E5);
  static const Color background = Color(0xFFF8FAFC);
  static const Color foreground = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);
  static const Color secondary = Color(0xFFEEF2FF);
  static const Color secondaryForeground = Color(0xFF1E1B4B);
  static const Color muted = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color accent = Color(0xFFFBBF24);
  static const Color accentForeground = Color(0xFF1E1B4B);
  static const Color success = Color(0xFF16A34A);
  static const Color successForeground = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Color(0xFFE2E8F0);
  static const Color supplierAvatar = Color(0xFF7C2D12);

  static const double radius = 14.0;

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static BoxShadow get elevatedShadow => BoxShadow(
        color: Colors.black.withOpacity(0.10),
        blurRadius: 20,
        offset: const Offset(0, 4),
      );
}
