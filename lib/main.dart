import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/theme/app_theme.dart';
import 'package:pomodoro_knight/firebase_options.dart';
import 'package:pomodoro_knight/ui/screens/home_screen.dart';
import 'package:pomodoro_knight/ui/screens/auth/login_screen.dart';
import 'package:pomodoro_knight/logic/auth/auth_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Google sign-in'i başlat
  await GoogleSignIn.instance.initialize();
  // Hive'ı başlat
  await Hive.initFlutter();
  await Hive.openBox('game_data');
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
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      ),
      error: (e, trace) =>
          Scaffold(body: Center(child: Text('Bir hata oluştu: $e'))),
    );
  }
}
