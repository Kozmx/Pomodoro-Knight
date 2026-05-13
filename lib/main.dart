import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/theme/app_theme.dart';
import 'package:pomodoro_knight/firebase_options.dart';
import 'package:pomodoro_knight/features/home/presentation/home_screen.dart';
import 'package:pomodoro_knight/core/data/models/user_model.dart';
import 'package:pomodoro_knight/features/auth/presentation/user_provider.dart';
import 'package:pomodoro_knight/features/auth/presentation/login_screen.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pomodoro_knight/game/services/game_audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Google sign-in'i başlat
  await GoogleSignIn.instance.initialize();
  await Hive.initFlutter();
  await Hive.openBox('game_data');
  
  // Ses servisini başlat (müziği burada çalma, oyuna girince çalacak)
  final audioService = GameAudioService();
  await audioService.initialize();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Knight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user != null) {
          _ensureUserDocument(ref, user);
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Hata: $e'))),
    );
  }

  // Kullanıcı Firestore'da yoksa oluşturur
  Future<void> _ensureUserDocument(WidgetRef ref, var firebaseUser) async {
    final repo = ref.read(userRepositoryProvider);
    // Önce kullanıcıyı çekmeyi dene
    final existingUser = await repo.getUser(firebaseUser.uid);

    // Eğer Firestore'da kaydı yoksa yeni döküman oluştur
    if (existingUser == null) {
      final newUser = UserModel.fromFirebaseUser(firebaseUser);
      await repo.saveUser(newUser);
    }
  }
}
