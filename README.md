# 🌏 Nusantara GPS (Mobile)

Aplikasi mobile berbasis Flutter untuk sistem pelacakan kendaraan Nusantara GPS. Terhubung ke backend di `lacak.nusantaragps.com`.

---

## 🚀 Persiapan Project

### 1) Clone Repository

```bash
git clone -b dev https://gitlab.com/profile-image/colaboration/nusantara-gps/nusantara-mobile-apps.git
cd nusantara-mobile-apps
```

---

### 2) Install Dependencies

Pastikan Flutter SDK sudah terinstal. Cek versi:

```bash
flutter --version
```

Lalu jalankan:

```bash
flutter pub get
```

---

### 3) Buat File Konfigurasi Lokal

File konfigurasi **tidak disertakan di Git** karena berisi data sensitif. Buat file baru di:

```
lib/core/config/app_config.dart
```

Isi dengan template berikut:

```dart
class AppConfig {
  static const String baseUrl = 'https://lacak.nusantaragps.com';
  static const String traccarUrl = 'traccar-url-here';
  static const String apiKey = 'your-api-key-here';
}
```

> ⚠️ **Jangan pernah commit file ini ke Git!**
> File ini sudah ditambahkan ke `.gitignore`.

---

### 4) Inisialisasi Hive Box di `main.dart`

Beberapa fitur menggunakan Hive untuk penyimpanan lokal. Pastikan semua box diinisialisasi sebelum `runApp()`:

```dart
await Hive.openBox('poi_images');
await Hive.openBox('geofence_events'); // Untuk event geofence lokal
```

---

### 5) Jalankan Aplikasi

```bash
flutter run
```

---

### 6) Build Release (Opsional)

```bash
flutter build apk --release
```

Output APK berada di:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧱 Struktur Project

```
lib/
├─ core/
│  ├─ app/
│  ├─ config/             --> app_config.dart (tidak di-commit ke Git)
│  ├─ di/                 --> Dependency injection dengan GetIt
│  ├─ navigation/
│  ├─ service/            --> Background service (alert polling, dll)
│  └─ utils/
├─ data/
│  ├─ datasources/        --> Raw API request ke backend
│  ├─ models/             --> DTO dan model data
│  └─ repositories/       --> Implementasi repository
├─ domain/
│  ├─ entities/           --> Entitas domain
│  └─ interfaces/         --> Abstract class repository
├─ presentation/
│  ├─ screens/
│  │  ├─ 01_splash/
│  │  ├─ 02_auth/
│  │  ├─ 03_shell/
│  │  ├─ 04_maps/         --> Peta utama + overlay tracking kendaraan
│  │  ├─ 05_vehicle/
│  │  ├─ 06_poi/          --> Manajemen Point of Interest
│  │  ├─ 07_geofence/     --> Manajemen area geofence
│  │  ├─ 08_report/
│  │  ├─ 09_profile/
│  │  ├─ 10_about/
│  │  └─ 11_alert/        --> Layar alert (tab Hardware + Geofence)
│  │     └─ widgets/      --> Komponen widget yang dipecah kecil-kecil
│  └─ widgets/            --> Widget umum / reusable
└─ main.dart
```

---

## 📦 Modul Utama

### 🗺️ POI (Point of Interest)

Modul untuk mengelola titik-titik lokasi penting yang ditampilkan di peta.

- **Icon cache**: `PoiIconCache` (singleton menggunakan Dio) mengunduh dan menyimpan ikon marker di memori, kemudian ditampilkan via `BitmapDescriptor.bytes()` dengan ukuran DPI-aware.
- **Upload foto**: Backend PHP mengharapkan dua bagian multipart dengan nama field `mphoto` — satu berisi teks (meniru `$_POST`) dan satu berisi file biner (meniru `$_FILES`).
- **Perhatian field**: Saat membuat/edit POI, gunakan nama field `micon` dan `mphoto` (bukan `icon`/`photo`) agar sesuai dengan ekspektasi backend.

---

### 🔷 Geofence

Modul untuk membuat dan mengelola area virtual (geofence) pada peta.

- Model mendukung field `inout` untuk menentukan arah trigger: masuk (`enter`), keluar (`exit`), atau keduanya.
- `GeofenceDrawManager` memisahkan `initDrawMode()` (hanya ubah mode) dari `setDrawMode()` (reset penuh) untuk mencegah bug penghapusan state yang tidak disengaja.
- `GeofenceCard` menampilkan tipe alert dan bentuk area geofence.

---

### 🔔 Alert & Notifikasi

Layar alert menampilkan dua sumber peringatan secara terpisah dalam dua tab:

| Tab                | Sumber                                 | Penyimpanan                                                     |
| ------------------ | -------------------------------------- | --------------------------------------------------------------- |
| **Hardware** | API `listalert` dari backend         | Diambil langsung via API                                        |
| **Geofence** | Event geofence yang dipicu di sisi app | Disimpan lokal di Hive box `geofence_events` (maks. 100 item) |

**Komponen widget layar alert** (di `lib/presentation/screens/11_alert/widgets/`):

```
alert_hardware_tab.dart
alert_geofence_tab.dart
alert_card.dart
geofence_event_card.dart
alert_icon.dart
alert_tab_badge.dart
alert_empty_view.dart
alert_error_view.dart
```

**Background service**: `alert_polling_service.dart` berjalan di isolate terpisah. Semua fungsi yang dipanggil dari background harus berupa **top-level function** (bukan instance method) karena keterbatasan anotasi `@pragma('vm:entry-point')`.

---

## ⚙️ Catatan Teknis Penting

- **Background isolate**: Fungsi yang dijalankan dari background service wajib berupa top-level function, bukan method dari sebuah class.
- **Hive initialization**: Tambahkan inisialisasi box `geofence_events` di `main.dart` setelah box `poi_images` yang sudah ada.
- **Jangan commit** `lib/core/config/app_config.dart` — sudah ada di `.gitignore`.
- Pastikan environment dan kredensial API sesuai dengan backend yang dituju (staging/production).
- Jika muncul error `missing AppConfig`, pastikan file `app_config.dart` sudah dibuat sesuai template di atas.
