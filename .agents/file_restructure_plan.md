# 📁 Pomodoro Knight — Dosya Yapısı Taşıma Planı

> **Kural:** `lib/game/` klasörüne kesinlikle dokunulmayacak.
> **İlke:** Feature-based, overengineering yok, proje kapsamına uygun basitlik.

---

## 1) Mevcut Yapı (Sorunlar)

```
lib/
├── main.dart
├── firebase_options.dart
├── core/                         # Genel altyapı
│   ├── constants/
│   │   ├── economy_constants.dart
│   │   ├── game_constants.dart
│   │   └── pomodoro_constants.dart
│   ├── data/
│   │   ├── mock_shop_items.dart
│   │   └── mock_upgrades.dart
│   ├── models/
│   │   ├── shop_item.dart
│   │   └── upgrade_item.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── utils/                    # ❌ BOŞ
│   └── widgets/                  # ❌ BOŞ
├── data/
│   └── repositories/             # ❌ BOŞ
├── features/                     # ❌ TAMAMEN BOŞ (yarım kalmış taşıma)
│   ├── audio/                    # boş
│   ├── auth/
│   │   ├── auth_provider.dart
│   │   ├── auth_repository.dart
│   │   └── login_screen.dart
│   ├── economy/                  # boş
│   ├── home/                     # boş
│   ├── inventory/                # boş
│   ├── navigation/               # boş
│   ├── pomodoro/                 # boş
│   ├── settings/                 # boş
│   ├── shop/
│   │   ├── tabs/                 # boş
│   │   └── widgets/              # boş
│   └── upgrades/                 # boş
├── logic/                        # Provider'lar dağınık
│   ├── audio/
│   │   ├── audio_provider.dart
│   │   └── audio_service.dart
│   ├── auth/                     # ❌ BOŞ (auth zaten features/auth'ta)
│   ├── economy/
│   │   ├── economy_provider.dart
│   │   └── economy_state.dart
│   ├── inventory/
│   │   ├── inventory_provider.dart
│   │   └── inventory_state.dart
│   ├── navigation/
│   │   └── navigation_provider.dart
│   ├── pomodoro/
│   │   └── pomodoro_provider.dart
│   └── upgrades/
│       ├── upgrade_provider.dart  # (muhtemelen boş/eski)
│       ├── upgrades_provider.dart
│       └── upgrades_state.dart
├── ui/                           # Screen'ler ayrı klasörde
│   ├── screens/
│   │   ├── auth/                 # ❌ BOŞ
│   │   ├── game_screen.dart
│   │   ├── home_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── pomodoro_screen.dart
│   │   ├── settings_screen.dart
│   │   └── shop/
│   │       ├── shop_screen.dart
│   │       ├── tabs/
│   │       │   ├── shop_tab.dart
│   │       │   └── upgrades_tab.dart
│   │       └── widgets/
│   │           ├── item_card.dart
│   │           ├── item_detail_sheet.dart
│   │           └── upgrade_card.dart
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   └── app_textfield.dart
│       ├── gold_display.dart
│       └── sound_button.dart
└── game/                         # 🔒 DOKUNMA
    ├── components/
    ├── enemy/
    ├── focus_game.dart
    └── services/
```

### Sorunların Özeti

1. `features/` klasörü oluşturulmuş ama içi boş (yarım kalmış taşıma)
2. `logic/`, `ui/screens/`, `core/` arasında aynı feature'a ait dosyalar dağınık
3. Boş klasörler var: `core/utils/`, `core/widgets/`, `data/repositories/`, `logic/auth/`, `ui/screens/auth/`
4. `features/auth` kısmen taşınmış, ama `logic/auth` boş kalmış

---

## 2) Hedef Yapı

```
lib/
├── main.dart
├── firebase_options.dart
├── core/                              # Paylaşılan altyapı (feature-bağımsız)
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── widgets/                       # Paylaşılan widget'lar
│       ├── app_button.dart
│       ├── app_textfield.dart
│       ├── gold_display.dart
│       └── sound_button.dart
├── features/
│   ├── auth/
│   │   ├── auth_provider.dart
│   │   ├── auth_repository.dart
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── pomodoro/
│   │   ├── pomodoro_constants.dart
│   │   ├── pomodoro_provider.dart
│   │   └── pomodoro_screen.dart
│   ├── shop/
│   │   ├── models/
│   │   │   └── shop_item.dart
│   │   ├── data/
│   │   │   └── mock_shop_items.dart
│   │   ├── shop_screen.dart
│   │   ├── shop_tab.dart
│   │   └── widgets/
│   │       ├── item_card.dart
│   │       └── item_detail_sheet.dart
│   ├── upgrades/
│   │   ├── models/
│   │   │   └── upgrade_item.dart
│   │   ├── data/
│   │   │   └── mock_upgrades.dart
│   │   ├── upgrades_tab.dart
│   │   ├── upgrades_provider.dart
│   │   ├── upgrades_state.dart
│   │   └── widgets/
│   │       └── upgrade_card.dart
│   ├── economy/
│   │   ├── economy_constants.dart
│   │   ├── economy_provider.dart
│   │   └── economy_state.dart
│   ├── inventory/
│   │   ├── inventory_provider.dart
│   │   └── inventory_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   ├── audio/
│   │   ├── audio_provider.dart
│   │   └── audio_service.dart
│   └── navigation/
│       └── navigation_provider.dart
└── game/                              # 🔒 DOKUNULMADI
    ├── components/
    ├── enemy/
    ├── focus_game.dart
    └── services/
```

---

## 3) Adım Adım Taşıma İşlemleri

Her adımda:

1. Dosya taşınır (`mv`)
2. Tüm `import` referansları güncellenir
3. Derleme kontrol edilir (`flutter analyze` veya IDE hata kontrolü)

### ✅ Adım 0: Boş Klasörleri Temizle

Hiçbir dosya taşımadan önce boş klasörleri sil:

```
SİLİNECEKLER:
- lib/core/utils/             (boş)
- lib/core/widgets/            (boş)  ← sonra yeniden oluşturulacak
- lib/data/repositories/       (boş)
- lib/data/                    (boş kalacak, sil)
- lib/logic/auth/              (boş)
- lib/ui/screens/auth/         (boş)
- lib/features/audio/          (boş)
- lib/features/economy/        (boş)
- lib/features/home/           (boş)
- lib/features/inventory/      (boş)
- lib/features/navigation/     (boş)
- lib/features/pomodoro/       (boş)
- lib/features/settings/       (boş)
- lib/features/shop/tabs/      (boş)
- lib/features/shop/widgets/   (boş)
- lib/features/shop/           (boş kalacak, sil)
- lib/features/upgrades/       (boş)
```

### ✅ Adım 1: Paylaşılan Widget'ları `core/widgets/` Altına Taşı

```
TAŞI: lib/ui/widgets/common/app_button.dart     → lib/core/widgets/app_button.dart
TAŞI: lib/ui/widgets/common/app_textfield.dart   → lib/core/widgets/app_textfield.dart
TAŞI: lib/ui/widgets/gold_display.dart            → lib/core/widgets/gold_display.dart
TAŞI: lib/ui/widgets/sound_button.dart            → lib/core/widgets/sound_button.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/widgets/common/app_button.dart
  yeni: package:pomodoro_knight/core/widgets/app_button.dart

  eski: package:pomodoro_knight/ui/widgets/common/app_textfield.dart
  yeni: package:pomodoro_knight/core/widgets/app_textfield.dart

  eski: package:pomodoro_knight/ui/widgets/gold_display.dart
  yeni: package:pomodoro_knight/core/widgets/gold_display.dart

  eski: package:pomodoro_knight/ui/widgets/sound_button.dart
  yeni: package:pomodoro_knight/core/widgets/sound_button.dart
```

### ✅ Adım 2: Home Feature

```
TAŞI: lib/ui/screens/home_screen.dart → lib/features/home/home_screen.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/screens/home_screen.dart
  yeni: package:pomodoro_knight/features/home/home_screen.dart
```

### ✅ Adım 3: Pomodoro Feature

```
TAŞI: lib/ui/screens/pomodoro_screen.dart     → lib/features/pomodoro/pomodoro_screen.dart
TAŞI: lib/logic/pomodoro/pomodoro_provider.dart → lib/features/pomodoro/pomodoro_provider.dart
TAŞI: lib/core/constants/pomodoro_constants.dart → lib/features/pomodoro/pomodoro_constants.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/screens/pomodoro_screen.dart
  yeni: package:pomodoro_knight/features/pomodoro/pomodoro_screen.dart

  eski: package:pomodoro_knight/logic/pomodoro/pomodoro_provider.dart
  yeni: package:pomodoro_knight/features/pomodoro/pomodoro_provider.dart

  eski: package:pomodoro_knight/core/constants/pomodoro_constants.dart
  yeni: package:pomodoro_knight/features/pomodoro/pomodoro_constants.dart
```

### ✅ Adım 4: Settings Feature

```
TAŞI: lib/ui/screens/settings_screen.dart → lib/features/settings/settings_screen.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/screens/settings_screen.dart
  yeni: package:pomodoro_knight/features/settings/settings_screen.dart
```

### ✅ Adım 5: Economy Feature

```
TAŞI: lib/logic/economy/economy_provider.dart    → lib/features/economy/economy_provider.dart
TAŞI: lib/logic/economy/economy_state.dart       → lib/features/economy/economy_state.dart
TAŞI: lib/core/constants/economy_constants.dart   → lib/features/economy/economy_constants.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/logic/economy/economy_provider.dart
  yeni: package:pomodoro_knight/features/economy/economy_provider.dart

  eski: package:pomodoro_knight/logic/economy/economy_state.dart
  yeni: package:pomodoro_knight/features/economy/economy_state.dart

  eski: package:pomodoro_knight/core/constants/economy_constants.dart
  yeni: package:pomodoro_knight/features/economy/economy_constants.dart
```

### ✅ Adım 6: Inventory Feature

```
TAŞI: lib/ui/screens/inventory_screen.dart         → lib/features/inventory/inventory_screen.dart
TAŞI: lib/logic/inventory/inventory_provider.dart  → lib/features/inventory/inventory_provider.dart
TAŞI: lib/logic/inventory/inventory_state.dart     → lib/features/inventory/inventory_state.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/screens/inventory_screen.dart
  yeni: package:pomodoro_knight/features/inventory/inventory_screen.dart

  eski: package:pomodoro_knight/logic/inventory/inventory_provider.dart
  yeni: package:pomodoro_knight/features/inventory/inventory_provider.dart

  eski: package:pomodoro_knight/logic/inventory/inventory_state.dart
  yeni: package:pomodoro_knight/features/inventory/inventory_state.dart
```

### ✅ Adım 7: Shop Feature

```
TAŞI: lib/ui/screens/shop/shop_screen.dart              → lib/features/shop/shop_screen.dart
TAŞI: lib/ui/screens/shop/tabs/shop_tab.dart             → lib/features/shop/shop_tab.dart
TAŞI: lib/ui/screens/shop/widgets/item_card.dart         → lib/features/shop/widgets/item_card.dart
TAŞI: lib/ui/screens/shop/widgets/item_detail_sheet.dart → lib/features/shop/widgets/item_detail_sheet.dart
TAŞI: lib/core/models/shop_item.dart                     → lib/features/shop/models/shop_item.dart
TAŞI: lib/core/data/mock_shop_items.dart                 → lib/features/shop/data/mock_shop_items.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/screens/shop/shop_screen.dart
  yeni: package:pomodoro_knight/features/shop/shop_screen.dart

  eski: package:pomodoro_knight/ui/screens/shop/tabs/shop_tab.dart
  yeni: package:pomodoro_knight/features/shop/shop_tab.dart

  eski: package:pomodoro_knight/ui/screens/shop/widgets/item_card.dart
  yeni: package:pomodoro_knight/features/shop/widgets/item_card.dart

  eski: package:pomodoro_knight/ui/screens/shop/widgets/item_detail_sheet.dart
  yeni: package:pomodoro_knight/features/shop/widgets/item_detail_sheet.dart

  eski: package:pomodoro_knight/core/models/shop_item.dart
  yeni: package:pomodoro_knight/features/shop/models/shop_item.dart

  eski: package:pomodoro_knight/core/data/mock_shop_items.dart
  yeni: package:pomodoro_knight/features/shop/data/mock_shop_items.dart
```

### ✅ Adım 8: Upgrades Feature

```
TAŞI: lib/ui/screens/shop/tabs/upgrades_tab.dart     → lib/features/upgrades/upgrades_tab.dart
TAŞI: lib/ui/screens/shop/widgets/upgrade_card.dart   → lib/features/upgrades/widgets/upgrade_card.dart
TAŞI: lib/logic/upgrades/upgrades_provider.dart       → lib/features/upgrades/upgrades_provider.dart
TAŞI: lib/logic/upgrades/upgrades_state.dart          → lib/features/upgrades/upgrades_state.dart
TAŞI: lib/core/models/upgrade_item.dart               → lib/features/upgrades/models/upgrade_item.dart
TAŞI: lib/core/data/mock_upgrades.dart                → lib/features/upgrades/data/mock_upgrades.dart

SİL:  lib/logic/upgrades/upgrade_provider.dart         (muhtemelen boş/eski dosya)

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/ui/screens/shop/tabs/upgrades_tab.dart
  yeni: package:pomodoro_knight/features/upgrades/upgrades_tab.dart

  eski: package:pomodoro_knight/ui/screens/shop/widgets/upgrade_card.dart
  yeni: package:pomodoro_knight/features/upgrades/widgets/upgrade_card.dart

  eski: package:pomodoro_knight/logic/upgrades/upgrades_provider.dart
  yeni: package:pomodoro_knight/features/upgrades/upgrades_provider.dart

  eski: package:pomodoro_knight/logic/upgrades/upgrades_state.dart
  yeni: package:pomodoro_knight/features/upgrades/upgrades_state.dart

  eski: package:pomodoro_knight/core/models/upgrade_item.dart
  yeni: package:pomodoro_knight/features/upgrades/models/upgrade_item.dart

  eski: package:pomodoro_knight/core/data/mock_upgrades.dart
  yeni: package:pomodoro_knight/features/upgrades/data/mock_upgrades.dart
```

### ✅ Adım 9: Audio Feature

```
TAŞI: lib/logic/audio/audio_provider.dart  → lib/features/audio/audio_provider.dart
TAŞI: lib/logic/audio/audio_service.dart   → lib/features/audio/audio_service.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/logic/audio/audio_provider.dart
  yeni: package:pomodoro_knight/features/audio/audio_provider.dart

  eski: package:pomodoro_knight/logic/audio/audio_service.dart
  yeni: package:pomodoro_knight/features/audio/audio_service.dart
```

### ✅ Adım 10: Navigation Feature

```
TAŞI: lib/logic/navigation/navigation_provider.dart → lib/features/navigation/navigation_provider.dart

IMPORT DEĞİŞİKLİKLERİ:
  eski: package:pomodoro_knight/logic/navigation/navigation_provider.dart
  yeni: package:pomodoro_knight/features/navigation/navigation_provider.dart
```

### ✅ Adım 11: Auth Düzeltme

`features/auth/` zaten doğru yerde. Sadece `main.dart`'taki eski import'ları kontrol et:

```
KONTROL ET (main.dart):
  eski: package:pomodoro_knight/ui/screens/auth/login_screen.dart     # varsa güncelle
  yeni: package:pomodoro_knight/features/auth/login_screen.dart

  eski: package:pomodoro_knight/logic/auth/auth_provider.dart         # varsa güncelle
  yeni: package:pomodoro_knight/features/auth/auth_provider.dart
```

### ✅ Adım 12: Game Screen

`game_screen.dart` game feature'ının UI'ı, ama game klasörüne dokunmuyoruz.
Bunu game'in bir parçası olarak değil, game klasörünün **dışında** bırakıyoruz:

```
TAŞI: lib/ui/screens/game_screen.dart → lib/features/home/game_screen.dart
  (Home'dan navigate edildiği için burada kalabilir, ya da ayrı bir klasör:)

  ALTERNATIF: game_screen.dart dosyası game/ klasörünün giriş noktası gibi
  davranıyorsa → lib/game/game_screen.dart olarak taşınabilir
  AMA game klasörüne dokunmama kuralına göre OLDUĞU YERDE KALMALI.

  KARAR: Olduğu yerde bırak, sadece import yolunu kontrol et.
  (Bu dosya zaten game/ içindeki focus_game.dart'ı çağırıyor.)
```

### ✅ Adım 13: game_constants.dart Kararı

```
KONTROL ET: lib/core/constants/game_constants.dart
  → Bu dosya game/ klasöründeki kodlar tarafından mı kullanılıyor?
  → Evet ise: lib/game/ altına taşımak game'e dokunmak sayılır,
    bu yüzden core/ altında bırak veya features/ altına al.
  → Hayır ise: Hangi feature kullanıyorsa oraya taşı.

  GEÇİCİ KARAR: core/ altında tut. (core/constants/game_constants.dart)
  Eğer core/constants/ altında sadece bu kalırsa → core/game_constants.dart yap.
```

### ✅ Adım 14: Eski Boş Klasörleri Temizle

Tüm taşımalar bittikten sonra:

```
SİL (boş kalan klasörler):
- lib/logic/                    (tamamı taşındı)
- lib/ui/                       (tamamı taşındı)
- lib/core/constants/           (taşınan dosyalar sonrası, boşsa sil)
- lib/core/data/                (taşındı, boş)
- lib/core/models/              (taşındı, boş)
```

### ✅ Adım 15: Son Derleme Kontrolü

```bash
cd /Users/dogualagoz/YAZILIM/Repos/Pomodoro-Knight
flutter analyze
# 0 issues beklenir
```

---

## 4) Kontrol Listesi

| #   | Adım                                          | Durum |
| --- | --------------------------------------------- | ----- |
| 0   | Boş klasörleri temizle                        | ⬜    |
| 1   | Paylaşılan widget'ları `core/widgets/`'a taşı | ⬜    |
| 2   | Home feature                                  | ⬜    |
| 3   | Pomodoro feature                              | ⬜    |
| 4   | Settings feature                              | ⬜    |
| 5   | Economy feature                               | ⬜    |
| 6   | Inventory feature                             | ⬜    |
| 7   | Shop feature                                  | ⬜    |
| 8   | Upgrades feature                              | ⬜    |
| 9   | Audio feature                                 | ⬜    |
| 10  | Navigation feature                            | ⬜    |
| 11  | Auth import düzeltmeleri                      | ⬜    |
| 12  | Game screen kararı                            | ⬜    |
| 13  | game_constants.dart kararı                    | ⬜    |
| 14  | Eski boş klasörleri temizle                   | ⬜    |
| 15  | Son derleme kontrolü (`flutter analyze`)      | ⬜    |
