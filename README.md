# ScamShield Mobile

Flutter app for Android and iOS. The Dart package name is `scamshield_mobile`.

## Chạy project

Dùng Flutter SDK đi kèm Dart 3.12 trở lên. Mở Android Emulator hoặc kết nối thiết bị, sau đó chạy từ thư mục project:

```powershell
flutter pub get
flutter run
```

Chạy iOS trên macOS có Xcode. Kiểm tra mã nguồn bằng `flutter analyze` và `flutter test`.

## Cấu trúc

| Thư mục | Nội dung |
| --- | --- |
| `lib/app/` | Widget gốc và cấu hình ứng dụng |
| `lib/core/theme/` | Theme dùng chung |
| `lib/data/models/` | Kiểu dữ liệu của ứng dụng |
| `lib/data/services/` | Gọi API hoặc truy cập dữ liệu cục bộ |
| `lib/data/repositories/` | Cung cấp dữ liệu cho ViewModel |
| `lib/ui/home/` | Màn hình khởi động |
| `lib/ui/shared/` | Widget dùng chung giữa các tính năng |

Mỗi tính năng có thư mục riêng trong `lib/ui/`. Khi màn hình có trạng thái cần quản lý, đặt `*_viewmodel.dart` cạnh màn hình và dùng Provider để cung cấp ViewModel cho widget.
