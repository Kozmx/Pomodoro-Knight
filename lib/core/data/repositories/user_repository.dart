import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pomodoro_knight/core/data/models/user_model.dart';

class UserRepository {
  // Firestore kütüphanesine erişim izni
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // "users" koleksiyonuna tip-güvenli erişim (sadece saveUser için kullanılıyor)
  CollectionReference<UserModel> get _usersRef => _firestore
      .collection('users')
      .withConverter<UserModel>(
        fromFirestore: (snapshot, options) =>
            UserModel.fromFirestore(snapshot, options),
        toFirestore: (user, options) => user.toJson(),
      );

  // Yeni kullanıcıyı firestore'a kaydet veya mevcut olanı güncelle
  Future<void> saveUser(UserModel user) async {
    // .doc(user.uid) -> Döküman adını kullanıcının UID'si yapıyoruz
    // .set(user) -> withConverter sayesinde direkt nesneyi gönderiyoruz
    await _usersRef.doc(user.uid).set(user);
  }

  // UID ile kullanıcı verisini tek seferlik çek (Get)
  Future<UserModel?> getUser(String uid) async {
    // Converter kullanmadan ham veriyi çekiyoruz ki döküman yoksa null dönebilelim
    final docSnapshot = await _firestore.collection('users').doc(uid).get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null; // Döküman yoksa tertemiz null döner
    }

    // Veri varsa manuel olarak modele çevir
    return UserModel.fromMap(docSnapshot.data()!, docSnapshot.id);
  }

  // Kullanıcıyı canlı dinle (Stream)
  // Converter KULLANMIYORUZ çünkü converter hata fırlatırsa tüm stream ölür.
  // Bunun yerine ham veriyi alıp kendimiz çeviriyoruz.
  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint('👤 watchUser: Döküman yok veya boş (uid: $uid)');
        return null;
      }
      try {
        final user = UserModel.fromMap(snapshot.data()!, snapshot.id);
        debugPrint('👤 watchUser: Veri geldi → gold=${user.wallet.gold}');
        return user;
      } catch (e, stack) {
        debugPrint('👤 watchUser HATA: $e');
        debugPrint('👤 Stack: $stack');
        return null; // Hata olsa bile stream ölmez, null döner
      }
    });
  }

  // Altın miktarını artır (Güvenli yöntem)
  Future<void> addGold(String uid, int amount) async {
    await _firestore.collection('users').doc(uid).update({
      'wallet.gold': FieldValue.increment(amount),
    });
  }

  // Sadece altın güncelleme (harcama veya basit kazanma)
  Future<void> updateGold(String uid, int newGold) async {
    await _firestore.collection('users').doc(uid).update({
      'wallet.gold': newGold, // iç içe alanı güncelleme yöntemi
    });
  }

  // Pomodoro Bitince: Hem Gold Hem istatistikleri tek seferde güncelle
  // Bu yöntem çok güvenlidir; ya hepsi güncellenir ya hiçbiri
  Future<void> completePomodoro(
    String uid,
    int earnedGold,
    int addedMinutes,
  ) async {
    final batch = _firestore.batch();
    final userDoc = _firestore.collection('users').doc(uid);

    batch.update(userDoc, {
      'wallet.gold': FieldValue.increment(earnedGold), // Mevcut altına ekler
      'stats.totalFocusMinutes': FieldValue.increment(addedMinutes),
      'stats.totalSessions': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // Ekipman değiştirme
  Future<void> updateEquipment(
    String uid,
    String? weaponId,
    String? armorId,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'equipment.equippedWeaponId': weaponId,
      'equipment.equippedArmorId': armorId,
    });
  }

  // Satın alma işlemi (Transaction)
  // Gold düşer ve ownedItems listesine yeni item eklenir
  Future<bool> purchaseItem(String uid, int price, String itemId) async {
    return _firestore.runTransaction((transaction) async {
      final userDoc = _firestore.collection('users').doc(uid);
      final snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) return false;

      // firestore'dan o anki gerçek bakiyeyi alıyoruz
      final currentGold = snapshot.data()?['wallet']?['gold'] ?? 0;

      // yeterli para var mı kontrol et
      if (currentGold < price) return false; //yetersiz bakiye, işlemi iptal et

      // bakiyeyi düş ve eşyayı listeye ekle
      transaction.update(userDoc, {
        'wallet.gold': currentGold - price,
        'ownedItems': FieldValue.arrayUnion([
          itemId,
        ]), //listeye tekrar eklemeyi önleyerek ekler
      });
      return true;
    });
  }

  // Stat Geliştirme
  // Gold düşer ve belirttiğimiz upgrade'in seviyesi 1 artar
  Future<bool> upgradeStat(String uid, int price, String upgradeId) async {
    return _firestore.runTransaction((transaction) async {
      final userDoc = _firestore.collection('users').doc(uid);
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return false;
      final currentGold = snapshot.data()?['wallet']?['gold'] ?? 0;
      if (currentGold < price) return false;
      transaction.update(userDoc, {
        'wallet.gold': currentGold - price,
        // map içindeki dinamik anahtarı ($upgradeId) 1 artırır
        'upgradeLevels.$upgradeId': FieldValue.increment(1),
      });
      return true;
    });
  }

  // Ayarları Güncelleme
  Future<void> updateSettings(String uid, UserSettings settings) async {
    await _firestore.collection('users').doc(uid).update({
      'settings': settings.toMap(),
    });
  }

  // Debug: İstatistikleri ve altınları sıfırla
  Future<void> resetStats(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'wallet.gold': 0,
      'stats.totalFocusMinutes': 0,
      'stats.totalSessions': 0,
      'upgradeLevels': {}, // Tüm geliştirmeleri sıfırla
    });
  }
}
