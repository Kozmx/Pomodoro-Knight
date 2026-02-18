import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/data/repositories/auth_repository.dart';

// Repository'nin kendisini sağla (Tüm uygulama boyunca tek instance)
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

// Auth durumunu dinle (giriş yapılmış mı yapılmamış mı ?)
// Bu stream kullanıcı giriş/çıkış yaptıkça otomatik güncellenir
final authStateProvider = StreamProvider((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Google ile giriş yapma aksiyonu. Buton basıldığında çağrılacak
final signInWithGoogleProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.signInWithGoogle();
});

// Çıkış yapma aksiyonu
final signOutProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.signOut();
});
