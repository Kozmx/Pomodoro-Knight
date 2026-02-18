import 'package:flutter/material.dart';
import 'package:pomodoro_knight/core/theme/app_colors.dart';
import 'package:pomodoro_knight/core/theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final String? assetPath;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.assetPath,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                children: [
                  // Sol taraftaki İkon / Asset
                  if (assetPath != null || icon != null)
                    SizedBox(
                      width: 40, // İkon için ayrılan alan
                      child: Align(
                        alignment: Alignment.center,
                        child: assetPath != null
                            ? Image.asset(assetPath!, height: 28)
                            : Icon(icon, size: 18),
                      ),
                    ),

                  // Orta kısım: Tam merkezlenmiş metin
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top:
                            4, // Sadece yazıyı aşağı it (pixel font düzeltmesi)
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: textColor ?? AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Sağ taraftaki "Hayalet" boşluk (Dengeleme için)
                  if (assetPath != null || icon != null)
                    const SizedBox(width: 40),
                ],
              ),
      ),
    );
  }
}
