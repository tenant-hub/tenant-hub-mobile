# Project Context

## 1. Genel Proje Tanımı & Amaç

**Tenant Hub**, gayrimenkul kiralama süreçlerini yönetmek için geliştirilmiş bir yönetim uygulamasıdır. Sistem; gayrimenkul, kiralama, ödeme, kullanıcı, rol ve yetki yönetimini tek bir platformda sunar.

**Temel işlevler:**
- Gayrimenkul kaydı ve takibi (kiracı ve ev sahibi atamasıyla birlikte)
- Kiralama sözleşmesi yönetimi
- Ödeme takibi
- Kullanıcı, rol ve yetki yönetimi (RBAC)

**Kardeş projeler:**
- `tenant-hub-service` — Spring Boot backend
- `tenant-hub-web` — React web uygulaması

---

## 2. Kullanıcı Rolleri & İzinler

Yetkilendirme **JWT tabanlı RBAC** ile sağlanır. JWT payload'ındaki `roles[]` ve `permissions[]` dizileri decode edilerek menü görünürlüğü ve buton erişimi kontrol edilir.

### İzin Konvansiyonu
`{KAYNAK}_{EYLEM}` formatı kullanılır. Örnek: `REAL_ESTATE_READ`, `USER_CREATE`

### Tanımlı İzinler

| Kaynak | İzinler |
|---|---|
| Kullanıcılar | `USER_READ`, `USER_CREATE`, `USER_UPDATE`, `USER_DELETE` |
| Roller | `ROLES_READ`, `ROLES_CREATE`, `ROLES_UPDATE`, `ROLES_DELETE` |
| Yetkiler | `PERMISSION_READ`, `PERMISSION_CREATE`, `PERMISSION_UPDATE`, `PERMISSION_DELETE` |
| Gayrimenkuller | `REAL_ESTATE_READ`, `REAL_ESTATE_CREATE`, `REAL_ESTATE_UPDATE`, `REAL_ESTATE_DELETE` |
| Kiralamalar | `RENT_READ`, `RENT_CREATE`, `RENT_UPDATE`, `RENT_DELETE` |
| Ödemeler | `PAYMENT_READ`, `PAYMENT_CREATE`, `PAYMENT_UPDATE`, `PAYMENT_DELETE` |
| Kiracılar | `TENANT_READ` |

---

## 3. Mimari Kararlar & Prensipler

- **Monorepo değil** — frontend ve backend ayrı repository'lerde
- **API-first** — tüm veri backend REST API üzerinden gelir, uygulama saf UI katmanıdır
- **JWT Auth** — accessToken `flutter_secure_storage`'da, refreshToken `httpOnly cookie`'de (dio_cookie_manager) saklanır
- **Token yenileme** — 401 hatası alındığında Dio interceptor otomatik refresh dener; başarısızsa `/login`'e yönlendirir
- **Server-side pagination** — tüm listeleme ekranlarında Spring Data `Page` formatı kullanılır (`content`, `totalElements`, `totalPages`, `size`, `number`)
- **Permission-based UI** — menü öğeleri ve aksiyon butonları `PermissionGuard` widget'ı ve `hasPermission()` ile koşullu render edilir
- **Platform-safe API URL** — `dart:io` kullanılmaz; `kIsWeb` + `defaultTargetPlatform` ile Android emülatör (`10.0.2.2`) ve diğer platformlar ayrıştırılır
- **Feature-first klasör yapısı** — her domain kendi `data/`, `domain/`, `presentation/` katmanlarına sahiptir

---

## 4. Bileşenler

### 4.1 Database

> Bu repo yalnızca mobil uygulama kodunu barındırır; database katmanı `tenant-hub-service` repository'sinde yönetilmektedir.

---

### 4.2 Backend

> Bu repo yalnızca mobil uygulama kodunu barındırır; backend katmanı `tenant-hub-service` repository'sinde yönetilmektedir.
>
> Uygulamanın iletişim kurduğu API hakkında bilgi için bkz. **Bölüm 3 — Mimari Kararlar & Prensipler**.

---

### 4.3 Web Frontend

> Bu repo yalnızca mobil uygulama kodunu barındırır; web frontend katmanı `tenant-hub-web` repository'sinde geliştirilmektedir.

---

### 4.4 Mobile

#### Teknoloji Stack'i

| Araç | Versiyon | Açıklama |
|---|---|---|
| Flutter | 3.41.4 | UI framework |
| Dart | ^3.6.0 | Programlama dili |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod code generation |
| Freezed | ^2.5.8 | Immutable model generation |
| json_serializable | ^6.9.4 | JSON serialization |
| Dio | ^5.7.0 | HTTP client |
| dio_cookie_manager | ^3.1.1 | Cookie yönetimi (refresh token) |
| GoRouter | ^14.8.1 | Declarative routing |
| flutter_secure_storage | ^9.2.4 | JWT token güvenli saklama |
| jwt_decoder | ^2.0.1 | JWT payload parse |
| intl | ^0.20.2 | Tarih/para birimi formatlama |

#### Mimari Notlar

**Dizin yapısı:**
```
lib/
├── main.dart                        # Giriş noktası, ProviderScope
├── app.dart                         # GoRouter tanımı, auth redirect guard
├── core/
│   ├── constants/
│   │   ├── api_constants.dart       # Base URL + endpoint sabitleri
│   │   ├── app_colors.dart          # Renk paleti
│   │   └── permission_keys.dart     # İzin sabitleri
│   ├── network/
│   │   ├── dio_client.dart          # Dio instance + auth interceptor + 401 refresh
│   │   └── api_exceptions.dart      # Hata tipleri
│   ├── storage/
│   │   └── secure_storage_service.dart  # flutter_secure_storage wrapper
│   └── utils/
│       └── jwt_utils.dart           # JWT decode yardımcıları
├── features/
│   ├── auth/                        # Login, AuthProvider, AuthRepository, AuthUser
│   ├── users/                       # CRUD + UserRole atama BottomSheet
│   ├── roles/                       # CRUD + RolePermission atama BottomSheet
│   ├── permissions/                 # CRUD
│   ├── real_estates/                # CRUD
│   ├── rents/                       # CRUD
│   ├── payments/                    # CRUD
│   ├── dashboard/                   # Özet istatistik kartları
│   ├── tenants/                     # Placeholder
│   └── settings/                    # Placeholder
└── shared/
    ├── models/
    │   └── page_response.dart       # Generic PageResponse<T>
    └── widgets/
        ├── app_drawer.dart          # Navigasyon drawer (izin bazlı menü)
        ├── status_chip.dart         # ACTIVE/INACTIVE chip
        ├── permission_guard.dart    # İzin bazlı widget gizleme
        ├── confirm_dialog.dart      # Silme onay diyaloğu
        └── empty_state_widget.dart  # Boş liste durumu
```

**Feature katman pattern'i (tüm modüllerde tekrar eden yapı):**
```
features/{module}/
├── data/
│   └── {module}_repository.dart    # Dio ile API çağrıları, PageResponse dönüşü
├── domain/
│   └── {module}_model.dart         # @freezed + @JsonSerializable immutable model
└── presentation/
    ├── {module}_provider.dart       # StateNotifier + StateNotifierProvider
    └── {module}_page.dart           # ListView / DataTable UI
```

**CRUD sayfa pattern'i (tüm modüllerde tekrar eden yapı):**
1. Scaffold + AppBar + FAB ("Yeni Ekle", `canCreate` ile koşullu)
2. `ListView.builder` — sunucu taraflı sayfalama (`page`, `size` parametreleri)
3. Her kart → düzenle / sil ikonları (`canUpdate`, `canDelete` ile koşullu)
4. Create/Edit `AlertDialog` veya `showModalBottomSheet` — form validasyonu
5. İlişki yönetimi gereken modüllerde ayrı BottomSheet (User→Role, Role→Permission)
6. Hata yönetimi: `DioException` → `ApiException` dönüşümü

**Yetkilendirme pattern'i (her sayfada):**
```dart
final canCreate = ref.watch(authProvider.select((s) => s.hasPermission('RESOURCE_CREATE')));
final canUpdate = ref.watch(authProvider.select((s) => s.hasPermission('RESOURCE_UPDATE')));
final canDelete = ref.watch(authProvider.select((s) => s.hasPermission('RESOURCE_DELETE')));
// Veya PermissionGuard widget'ı ile:
PermissionGuard(permission: 'RESOURCE_CREATE', child: FloatingActionButton(...))
```

**Tema:**
- Accent rengi: `#4F46E5` (indigo)
- Material 3, `ColorScheme.fromSeed` ile indigo seed
- AppDrawer: koyu indigo header, izin bazlı menü öğeleri
- Font: sistem varsayılanı

---

## 5. Mevcut Modüller & Özellikler

| Modül | Durum | Açıklama |
|---|---|---|
| Auth (Login/Logout) | ✅ Tamamlandı | JWT login, httpOnly refresh cookie, token yenileme interceptor |
| Dashboard | ✅ Tamamlandı | Gayrimenkul, kullanıcı, kiralama, ödeme toplam sayıları |
| Kullanıcılar | ✅ Tamamlandı | CRUD + User-Role BottomSheet + izin koşullu butonlar |
| Roller | ✅ Tamamlandı | CRUD + Role-Permission BottomSheet + izin koşullu butonlar |
| Yetkiler | ✅ Tamamlandı | CRUD + izin koşullu butonlar |
| Gayrimenkuller | ✅ Tamamlandı | CRUD + kiracı/ev sahibi seçimi + izin koşullu butonlar |
| Kiralama | ✅ Tamamlandı | CRUD + gayrimenkul seçimi + para birimi + izin koşullu butonlar |
| Ödemeler | ✅ Tamamlandı | CRUD + kiralama seçimi + para birimi + izin koşullu butonlar |
| Kiracılar | 🔲 Placeholder | Henüz geliştirilmedi |
| Ayarlar | 🔲 Placeholder | Henüz geliştirilmedi |
