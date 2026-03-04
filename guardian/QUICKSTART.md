# Hướng Dẫn Cài Đặt Nhanh

## 🚀 Bắt Đầu Nhanh (5 Phút)

### 1. Cài Đặt Flutter (Lần Đầu)
```bash
# Tải từ https://flutter.dev/docs/get-started/install
# Sau đó chạy:
flutter doctor
```

### 2. Clone & Cài Đặt Project
```bash
cd guardian
flutter pub get
```

### 3. Chạy Ứng Dụng

**Trên Emulator Android:**
```bash
flutter run
```

**Trên iOS (macOS only):**
```bash
flutter run -d macos
```

**Trên Web:**
```bash
flutter run -d chrome
```

## 📱 Danh Sách Thiết Bị Khả Dụng

```bash
flutter devices
```

## 🐛 Debug & Troubleshoot

### Lỗi: Device không

 được tìm thấy
```bash
# Android
flutter devices
adb devices

# Hoặc reset
adb kill-server
adb devices
```

### Lỗi: Dependencies không cài được
```bash
flutter clean
flutter pub get
```

### Lỗi: Build fail
```bash
flutter clean
flutter pub cache repair
flutter pub get
flutter run
```

### Xem Log
```bash
flutter logs
```

## 📋 Danh Sách Phím Tắt (Khi Ứng Dụng Chạy)

| Phím | Chức Năng |
|------|----------|
| `r` | Hot Reload |
| `R` | Full Restart |
| `q` | Quit |
| `p` | Performance Diagnostics |
| `w` | Show Widget Errors |

## 📂 File Cấu Hình Quan Trọng

- `pubspec.yaml` - Dependencies
- `analysis_options.yaml` - Linting rules
- `android/build.gradle.kts` - Android config
- `ios/Podfile` - iOS config

## 💾 Database

Database tự động được tạo tại:
- **Android**: `/data/data/com.example.guardian/databases/digital_village.db`
- **iOS**: Trong app's Documents folder
- **Windows/Mac**: Tại `%APPDATA%` hoặc `~/Library`

## 🎨 Tùy Chỉnh

### Đổi Tên App
1. Mở `pubspec.yaml`
2. Đổi `name: guardian` thành tên mới

### Đổi Icon & Splash
1. Thay thế `android/app/src/main/res/mipmap-*/ic_launcher.png`
2. Thay thế `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`

## 📦 Built-in Packages

Dự án đã cài đặt:
- `sqflite` - SQLite Database
- `cached_network_image` - Image Caching
- `intl` - Localization
- `path` - Path Utilities

## ✨ Tính Năng Sẵn Sàng Test

✅ **Sản Phẩm:**
- 10 sản phẩm mẫu
- Lọc theo danh mục
- Chi tiết sản phẩm

✅ **Giỏ Hàng:**
- Thêm/sửa/xóa sản phẩm
- Tính toán tổng tiền tự động

✅ **Thanh Toán:**
- Quy trình thanh toán đầy đủ
- Mã đơn hàng tạo tự động

✅ **Đơn Hàng:**
- Danh sách đơn hàng
- Chi tiết đơn hàng
- Trạng thái đơn hàng

## 🔐 Tài Khoản Demo

```
User ID: 33333333-3333-3333-3333-333333333333 (Buyer)
Seller 1: 11111111-1111-1111-1111-111111111111
Seller 2: 22222222-2222-2222-2222-222222222222
```

## 📞 Liên Hệ Hỗ Trợ

- 📧 Email: support@digitalvillage.vn
- 💬 Chat: Messenger
- 🐛 Issues: GitHub

---

**Vui lòng tham khảo `FEATURES.md` cho danh sách đầy đủ tính năng.**
