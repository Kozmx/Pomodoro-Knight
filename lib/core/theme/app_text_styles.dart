import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // DISPLAY -- Sadece ana başlıklar
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Pixelmania',
    fontSize: 20,
    color: AppColors.textPrimary,
  );

  // TITLE -- Kart başlıkları, modal başlıkları için kalın Minecraftia
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // BODY -- Okuma metinleri
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 10,
    color: AppColors.textSecondary,
  );

  // LABEL -- Butonlar, etiketler
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // --- ÖZEL ---
  static const TextStyle goldText = TextStyle(
    fontFamily: 'Minecraftia',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
  );
}
