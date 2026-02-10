# 🏰 Pomodoro Knight — Mimari Plan v3 (MVP + Sonrası)

## 📌 Proje Özeti

Pomodoro tekniğiyle çalışarak gold kazanıp, silah/zırh satın alıp, oyunda canavarlarla savaşma.

**Sen** = Uygulama tarafı | **Arkadaşın** = Oyun (Flame) tarafı | **Ben** = Mentor (yol gösteriyorum, sen kodluyorsun)

---

## 🎯 MVP Nedir?

**Yayınlanabilir minimum ürün**: Uygulamayı açıp kullanabilecek, temel döngüyü (çalış → kazan → satın al → savaş) yaşayabilecek bir versiyon.

### MVP'de OLACAKLAR

- ✅ Google + Apple Sign-In
- ✅ Pomodoro Timer (çalışınca gold kazanma)
- ✅ Shop (silah/zırh satın alma)
- ✅ Inventory (kuşanma/değiştirme)
- ✅ Upgrades (stat yükseltme)
- ✅ Firestore'da kullanıcı verisi (gold, inventory, upgrades)
- ✅ Theme sistemi (tutarlı görünüm)
- ✅ GoRouter + Auth guard

### MVP'de OLMAYACAKLAR (Post-MVP)

- ❌ Leaderboard
- ❌ Profil ekranı
- ❌ Session log (geçmiş pomodoro kayıtları)
- ❌ dailyStats / grafik ekranı
- ❌ Streak sistemi
- ❌ Cloud Functions ile güvenlik
- ❌ Offline-first (Hive cache sync)

---

## 🗄️ Firestore Şeması

### MVP Şeması (Basit + Yeterli)

```
firestore/
│
├── users/{uid}                          # Ana kullanıcı dokümanı
│   ├── displayName: "Doğu"
│   ├── email: "dogu@mail.com"
│   ├── photoUrl: "..."
│   ├── createdAt: Timestamp
│   ├── lastActiveAt: Timestamp
│   │
│   ├── wallet:
│   │   └── gold: 1500
│   │
│   ├── stats:
│   │   ├── totalFocusMinutes: 420
│   │   └── totalSessions: 28
│   │
│   ├── progress:
│   │   ├── currentFloor: 5
│   │   └── maxFloorUnlocked: 5
│   │
│   ├── equipment:
│   │   ├── equippedWeaponId: "weapon_flame"
│   │   └── equippedArmorId: "armor_2"
│   │
│   ├── ownedItems: ["weapon_starter", "weapon_flame", "armor_1", "armor_2"]
│   │
│   ├── upgradeLevels:
│   │   ├── coin_boost: 3
│   │   ├── damage_boost: 2
│   │   └── health_boost: 1
│   │
│   └── settings:
│       ├── workDuration: 25
│       ├── shortBreakDuration: 5
│       └── soundEnabled: true
│
└── itemTemplates/{templateId}           # Global item katalogu (read-only)
    ├── name: "Flame Blade"
    ├── type: "weapon"
    ├── description: "+15% Crit Chance"
    ├── price: 350
    ├── iconName: "local_fire_department"
    ├── colorHex: "#FF9800"
    ├── stats:
    │   ├── damage: 15
    │   ├── attackSpeed: 1.2
    │   ├── critBonus: 0.15
    │   ├── specialEffect: "Burn: 3 dmg/sec for 2s"
    │   ├── defense: 0
    │   └── health: 0
    └── sortOrder: 2
```

> [!NOTE]
> **MVP'de neden sub-collection yok?** `ownedItems` listesi tek bir doküman alanı olarak tutuluyor. 10-20 item için bu yeterli ve çok daha basit. Post-MVP'de inventory büyürse sub-collection'a taşınabilir.

### Post-MVP'de Eklenecekler

```
├── users/{uid}/sessions/{sessionId}     # Pomodoro geçmişi
├── users/{uid}/dailyStats/{YYYY-MM-DD}  # Günlük istatistikler
├── users/{uid}/inventory/{itemId}       # Detaylı item instance'ları
├── leaderboard/{uid}                    # Sıralama tablosu
└── users/{uid}/transactions/{txId}      # Audit log (anti-cheat)
```

### MVP Yazma Kuralları

**Pomodoro bitince** (tek batch write):

1. `users/{uid}` → `wallet.gold` += earnedGold
2. `users/{uid}` → `stats.totalFocusMinutes` += minutes, `stats.totalSessions` += 1

**Silah satın alınca** (tek batch write):

1. `users/{uid}` → `wallet.gold` -= price
2. `users/{uid}` → `ownedItems` listesine templateId ekle

**Upgrade alınca** (tek transaction):

1. `users/{uid}` → `wallet.gold` -= price + `upgradeLevels.X` += 1

---

## 🏗️ Klasör Yapısı

```
lib/
├── main.dart                          # Firebase init + ProviderScope
├── app.dart                           # [YENİ] MaterialApp.router + GoRouter
├── firebase_options.dart
│
├── core/
│   ├── constants/                     # Mevcut sabitler
│   ├── theme/
│   │   ├── app_colors.dart            # [YENİ]
│   │   ├── app_text_styles.dart       # [YENİ]
│   │   └── app_theme.dart             # [YENİ]
│   ├── router/
│   │   └── app_router.dart            # [YENİ]
│   └── utils/
│
├── data/
│   ├── models/
│   │   ├── user_model.dart            # [YENİ] toJson/fromJson
│   │   └── item_template.dart         # [YENİ] toJson/fromJson
│   └── repositories/
│       ├── auth_repository.dart       # [YENİ]
│       ├── user_repository.dart       # [YENİ]
│       └── item_template_repository.dart # [YENİ]
│
├── logic/                             # Mevcut Riverpod providers (refactor)
│   ├── auth/auth_provider.dart        # [YENİ]
│   ├── audio/                         # Korunacak
│   ├── economy/                       # Refactor → Firestore sync
│   ├── inventory/                     # Refactor → Firestore sync
│   ├── pomodoro/                      # Refactor → state ayrı dosya
│   ├── shop/shop_provider.dart        # [YENİ] itemTemplates çeker
│   └── upgrades/                      # Refactor → Firestore sync
│
├── ui/
│   ├── screens/
│   │   ├── auth/login_screen.dart     # [YENİ]
│   │   ├── home_screen.dart
│   │   ├── pomodoro_screen.dart
│   │   ├── shop_page/
│   │   └── settings_screen.dart
│   └── widgets/
│
└── game/                              # 🎮 DOKUNULMAYACAK
```

---

## 🗺️ MVP Yol Haritası (8 Adım)

| #   | Adım                            | Ne                                                                     | Tahmini  |
| --- | ------------------------------- | ---------------------------------------------------------------------- | -------- |
| 1   | **Theme Sistemi**               | `AppColors` + `AppTextStyles` + `AppTheme`. Hardcoded renkleri temizle | 1-2 saat |
| 2   | **Firebase Auth**               | Google + Apple Sign-In. Login ekranı. `AuthProvider`                   | 2-3 saat |
| 3   | **GoRouter**                    | Route tanımları + auth guard                                           | 1 saat   |
| 4   | **Firestore Modelleri**         | `UserModel` + `ItemTemplate` — `toJson/fromJson`                       | 1-2 saat |
| 5   | **Repository Katmanı**          | `UserRepository` + `ItemTemplateRepository` + `AuthRepository`         | 2-3 saat |
| 6   | **Economy + Pomodoro Refactor** | Firestore sync. Gold kazanma → Firestore'a yaz                         | 2-3 saat |
| 7   | **Shop & Inventory Refactor**   | `itemTemplates` Firestore'dan çek. Satın al → batch write              | 2-3 saat |
| 8   | **Upgrades Refactor**           | Firestore sync. Transaction ile gold - upgrade atomic                  | 1-2 saat |

**Toplam MVP tahmini: ~13-19 saat**

---

## 🚀 Post-MVP Yol Haritası

| #   | Özellik                      | Açıklama                                                          |
| --- | ---------------------------- | ----------------------------------------------------------------- |
| P1  | **Session Log**              | Her pomodoro'yu `sessions` sub-collection'a kaydet. Geçmiş ekranı |
| P2  | **dailyStats + Grafikler**   | Günlük istatistik dokümanları. Haftalık/aylık grafik ekranı       |
| P3  | **Leaderboard**              | `leaderboard/{uid}` koleksiyonu. Top N listesi                    |
| P4  | **Profil Ekranı**            | İstatistikler, equipped item gösterimi, başarılar                 |
| P5  | **Streak Sistemi**           | Ardışık gün takibi, streak bonusu                                 |
| P6  | **Offline-First**            | Hive cache + Firestore sync (internet yokken çalışma)             |
| P7  | **Cloud Functions**          | Server-side gold doğrulama, anti-cheat                            |
| P8  | **Inventory Sub-Collection** | Item sayısı artarsa ownedItems → sub-collection'a taşı            |

---

## ⚔️ Korunacak Oyun API'si

Arkadaşın bunları kullanıyor — **dış arayüz değişmemeli**:

```dart
ref.watch(upgradesProvider).damageMultiplier
ref.watch(upgradesProvider).attackSpeedMultiplier
ref.watch(upgradesProvider).maxHealthBonus
ref.watch(upgradesProvider).defenseMultiplier
ref.watch(upgradesProvider).criticalChance
ref.watch(upgradesProvider).coinMultiplier
ref.watch(inventoryProvider).equippedWeapon
ref.watch(inventoryProvider).equippedArmor
ref.watch(economyProvider).gold
```

---

## ✅ Başlangıç Noktası

Onaylarsan **Adım 1: Theme Sistemi** ile başlıyoruz. Sana şunları anlatacağım:

- Hangi dosyaları oluşturacaksın
- İçlerine ne yazacaksın
- Neden böyle yapıyoruz
- Mevcut hangi dosyalardaki renkleri değiştireceksin
