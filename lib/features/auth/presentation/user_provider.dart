import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_knight/core/data/models/user_model.dart';
import 'package:pomodoro_knight/core/data/repositories/user_repository.dart';
import 'package:pomodoro_knight/features/auth/presentation/auth_provider.dart';

// UserRepository örneğini sağlayan provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Firestore'dan kullanıcı verisini canlı (stream) olarak çeken provider
final userProvider = StreamProvider<UserModel?>((ref) {
  // Giriş yapmış kullanıcının UID'sini izle.
  final user = ref.watch(authStateProvider).value;

  if (user == null) {
    return Stream.value(null);
  }

  // Firestore dökümanını canlı olarak dinle
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
});

// Kullanıcının altın miktarını (gold) filtreleyerek sağlayan provider
// Bu sayede sadece altın değiştiğinde GoldDisplay widget'ı yeniden çizilir.
final userGoldProvider = Provider<int>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.wallet.gold ?? 0,
    orElse: () => 0,
  );
});

// Kullanıcının donanımlı ekipmanlarını sağlayan provider
final equippedItemsProvider = Provider<UserEquipment?>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.equipment,
    orElse: () => null,
  );
});
