import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  // 1. Kimlik Bilgileri
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  // 2. Oyun Verileri (Az önce oluşturduğun sınıflar)
  final UserWallet wallet;
  final UserStats stats;
  final UserProgress progress;
  final UserEquipment equipment;
  final UserSettings settings;

  // 3. Koleksiyonlar (Planımızda olan listeler)
  final List<String> ownedItems;
  final Map<String, int> upgradeLevels;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastActiveAt,
    required this.wallet,
    required this.stats,
    required this.progress,
    required this.equipment,
    required this.settings,
    required this.ownedItems,
    required this.upgradeLevels,
  });

  //firestore'a göndermek için mapleme
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      // Alt sınıfların kendi toMap metodlarını çağırıyoruz!
      'wallet': wallet.toMap(),
      'stats': stats.toMap(),
      'progress': progress.toMap(),
      'equipment': equipment.toMap(),
      'settings': settings.toMap(),
      'ownedItems': ownedItems,
      'upgradeLevels': upgradeLevels,
    };
  }

  // Firestore'dan okurken tertemiz ve güvenli dönüşüm
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) throw Exception("Veri bulunamadı!");
    // Helper: Timestamp'i DateTime'a güvenli çevirme
    DateTime toDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.now(); // Hata varsa şimdiki zamanı ver
    }

    return UserModel(
      uid: snapshot.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: toDateTime(data['createdAt']),
      lastActiveAt: toDateTime(data['lastActiveAt']),

      // Alt sınıfların kendi fromMap metodlarını çağırıyoruz!
      wallet: UserWallet.fromMap(data['wallet'] ?? {}),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      progress: UserProgress.fromMap(data['progress'] ?? {}),
      equipment: UserEquipment.fromMap(data['equipment'] ?? {}),
      settings: UserSettings.fromMap(data['settings'] ?? {}),

      ownedItems: List<String>.from(data['ownedItems'] ?? []),
      upgradeLevels: Map<String, int>.from(data['upgradeLevels'] ?? {}),
    );
  }

  // Firebase Auth kullanıcısından başlangıç modeli oluşturma
  factory UserModel.fromFirebaseUser(auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      wallet: UserWallet(),
      stats: UserStats(),
      progress: UserProgress(),
      equipment: UserEquipment(),
      settings: UserSettings(),
      ownedItems: ['weapon_starter'],
      upgradeLevels: {},
    );
  }

  // Değişmezlik için kopyalama metodu
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    UserWallet? wallet,
    UserStats? stats,
    UserProgress? progress,
    UserEquipment? equipment,
    UserSettings? settings,
    List<String>? ownedItems,
    Map<String, int>? upgradeLevels,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      wallet: wallet ?? this.wallet,
      stats: stats ?? this.stats,
      progress: progress ?? this.progress,
      equipment: equipment ?? this.equipment,
      settings: settings ?? this.settings,
      ownedItems: ownedItems ?? this.ownedItems,
      upgradeLevels: upgradeLevels ?? this.upgradeLevels,
    );
  }
}

class UserWallet {
  final int gold;
  UserWallet({this.gold = 1500});
  Map<String, dynamic> toMap() => {'gold': gold};
  factory UserWallet.fromMap(Map<String, dynamic> map) =>
      UserWallet(gold: map['gold'] ?? 1500);

  UserWallet copyWith({int? gold}) => UserWallet(gold: gold ?? this.gold);
}

class UserStats {
  final int totalFocusMinutes;
  final int totalSessions;
  UserStats({this.totalFocusMinutes = 0, this.totalSessions = 0});
  Map<String, dynamic> toMap() => {
    'totalFocusMinutes': totalFocusMinutes,
    'totalSessions': totalSessions,
  };
  factory UserStats.fromMap(Map<String, dynamic> map) => UserStats(
    totalFocusMinutes: map['totalFocusMinutes'] ?? 0,
    totalSessions: map['totalSessions'] ?? 0,
  );

  UserStats copyWith({int? totalFocusMinutes, int? totalSessions}) => UserStats(
    totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
    totalSessions: totalSessions ?? this.totalSessions,
  );
}

class UserProgress {
  final int currentFloor;
  final int maxFloorUnlocked;
  UserProgress({this.currentFloor = 1, this.maxFloorUnlocked = 1});
  Map<String, dynamic> toMap() => {
    'currentFloor': currentFloor,
    'maxFloorUnlocked': maxFloorUnlocked,
  };
  factory UserProgress.fromMap(Map<String, dynamic> map) => UserProgress(
    currentFloor: map['currentFloor'] ?? 1,
    maxFloorUnlocked: map['maxFloorUnlocked'] ?? 1,
  );

  UserProgress copyWith({int? currentFloor, int? maxFloorUnlocked}) =>
      UserProgress(
        currentFloor: currentFloor ?? this.currentFloor,
        maxFloorUnlocked: maxFloorUnlocked ?? this.maxFloorUnlocked,
      );
}

class UserEquipment {
  final String? equippedWeaponId;
  final String? equippedArmorId;
  UserEquipment({
    this.equippedWeaponId = 'weapon_starter',
    this.equippedArmorId,
  });
  Map<String, dynamic> toMap() => {
    'equippedWeaponId': equippedWeaponId,
    'equippedArmorId': equippedArmorId,
  };
  factory UserEquipment.fromMap(Map<String, dynamic> map) => UserEquipment(
    equippedWeaponId: map['equippedWeaponId'],
    equippedArmorId: map['equippedArmorId'],
  );

  UserEquipment copyWith({String? equippedWeaponId, String? equippedArmorId}) =>
      UserEquipment(
        equippedWeaponId: equippedWeaponId ?? this.equippedWeaponId,
        equippedArmorId: equippedArmorId ?? this.equippedArmorId,
      );
}

class UserSettings {
  final int workDuration;
  final int shortBreakDuration;
  final bool soundEnabled;
  UserSettings({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.soundEnabled = true,
  });
  Map<String, dynamic> toMap() => {
    'workDuration': workDuration,
    'shortBreakDuration': shortBreakDuration,
    'soundEnabled': soundEnabled,
  };
  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    workDuration: map['workDuration'] ?? 25,
    shortBreakDuration: map['shortBreakDuration'] ?? 5,
    soundEnabled: map['soundEnabled'] ?? true,
  );

  UserSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    bool? soundEnabled,
  }) => UserSettings(
    workDuration: workDuration ?? this.workDuration,
    shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );
}
