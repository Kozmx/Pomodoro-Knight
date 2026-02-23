import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';
import 'package:pomodoro_knight/core/theme/app_colors.dart';
import 'package:pomodoro_knight/core/theme/app_text_styles.dart';
import 'package:pomodoro_knight/core/widgets/app_button.dart';
import 'package:pomodoro_knight/core/widgets/app_textfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Başlık
              Column(
                children: [
                  Text(
                    'POMODORO',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KNIGHT',
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Giriş Alanları - Yeni Widget'lar
              AppTextField(
                controller: _emailController,
                label: 'E-posta',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: 'Şifre',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Normal Giriş Butonu - Yeni Widget
              AppButton(
                text: 'Şövalye Girişi',
                isLoading: _isLoading,
                onPressed: () async {
                  _setLoading(true);
                  final result = await ref
                      .read(authRepositoryProvider)
                      .signInWithEmail(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                  _setLoading(false);

                  if (result == null && context.mounted) {
                    _showError(
                      context,
                      'Giriş yapılamadı. Bilgilerini kontrol et.',
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Kayıt Butonu
              TextButton(
                onPressed: () async {
                  _setLoading(true);
                  final result = await ref
                      .read(authRepositoryProvider)
                      .signUpWithEmail(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                  _setLoading(false);

                  if (result != null && context.mounted) {
                    _showError(
                      context,
                      'Kayıt başarılı! Giriş yapabilirsiniz.',
                      isError: false,
                    );
                  } else if (context.mounted) {
                    _showError(context, 'Kayıt sırasında bir hata oluştu.');
                  }
                },
                child: Text(
                  'Yeni Şövalye Oluştur',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.cardBg)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('VEYA', style: AppTextStyles.bodySmall),
                    ),
                    const Expanded(child: Divider(color: AppColors.cardBg)),
                  ],
                ),
              ),

              // Google Butonu
              AppButton(
                text: 'Google ile Devam Et',
                color: AppColors.textPrimary,
                textColor: Colors.black87,
                assetPath: 'assets/logos/pikselart_google_logo.png',
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signInWithGoogle();
                },
              ),

              const SizedBox(height: 24),

              // Misafir Butonu
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signInAnonymously();
                },
                child: Text(
                  'Misafir Şövalye Olarak Devam Et',
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
