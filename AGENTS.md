# Hướng dẫn phát triển ScamShield Mobile

ScamShield Mobile là ứng dụng Flutter cho Android và iOS. Tên package Dart là `scamshield_mobile`.

## Cấu trúc mã nguồn

- `lib/app/` cấu hình ứng dụng, theme và điều hướng cấp ứng dụng.
- `lib/core/` chứa theme và các thành phần dùng chung ngoài phạm vi từng tính năng.
- `lib/ui/<tính_năng>/` chứa màn hình, widget và trạng thái riêng của tính năng. Đặt widget dùng chung giữa các tính năng trong `lib/ui/shared/`.
- `lib/data/` chứa model, repository và service. Khi tích hợp backend, đặt gọi API trong service và truy cập dữ liệu qua repository.
- Dùng `setState` cho trạng thái giao diện cục bộ như tab đang chọn. Dùng Provider với ViewModel khi nhiều widget cần dùng chung trạng thái hoặc khi tính năng cần điều phối dữ liệu bất đồng bộ.

## UI Flutter

- Để màn hình phụ trách bố cục và điều hướng. Tách các phần có trách nhiệm rõ ràng như biểu mẫu, danh sách cảnh báo và menu thành widget riêng. Tái sử dụng widget hiện có khi phù hợp.
- Tách kiểm tra đầu vào và xử lý nghiệp vụ khỏi widget để có thể kiểm thử riêng. Giải phóng controller do widget tạo trong `dispose`.
- Dùng `AppTheme` cho màu và style dùng chung. Khi chuyển UI từ web, đối chiếu mã nguồn web và giữ nhận diện ScamShield VN với navy, xanh dương và nền tím xám nhạt. Tránh màu xanh lá trong giao diện.
- Viết nhãn và thông báo bằng tiếng Việt có dấu. Kiểm tra bố cục trên màn hình hẹp và khi bàn phím mở nếu thay đổi biểu mẫu.
- Chỉ hiển thị kết quả đánh giá rủi ro khi có dữ liệu từ dịch vụ phân tích. Kiểm tra định dạng đầu vào chỉ xác nhận dữ liệu hợp lệ.

## Kiểm tra thay đổi

- Đặt tên file Dart bằng `snake_case`, kiểu bằng `UpperCamelCase` và biến, hàm bằng `lowerCamelCase`. Giữ thay đổi trong phạm vi yêu cầu.
- Với thay đổi Dart, chạy `dart format` trên các file đã sửa và `flutter analyze`. Chạy kiểm thử liên quan trong `test/` khi thay đổi hành vi.
- Với thay đổi UI, kiểm tra trên emulator hoặc thiết bị nếu có. Ghi rõ bước nào chưa chạy được hoặc kết quả nào chưa xác minh.
