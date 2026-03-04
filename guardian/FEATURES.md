# Nông Thôn Số - Digital Village Agricultural Commerce

Ứng dụng thương mại nông sản hoàn chỉnh tích hợp SQLite, cho phép người dùng xem danh sách sản phẩm, thêm vào giỏ hàng, thanh toán và theo dõi đơn hàng.

## Tính Năng Chính

### 1. **Quản Lý Sản Phẩm** ✅
- **Hiển thị danh sách sản phẩm**: Danh sách tất cả sản phẩm nông sản với hình ảnh, tên, danh mục, giá
- **Lọc theo danh mục**: Phân loại sản phẩm theo: Trái Cây, Rau Củ, Ngũ Cốc, Gia Vị, v.v.
- **Chi tiết sản phẩm**: Xem thông tin chi tiết, mô tả, chọn số lượng, thêm vào giỏ hàng
- **30 sản phẩm mẫu**: Xoài Cát, Sầu Riêng, Bơ Sáp, Thanh Long, Cà Chua, Dưa Leo, Cà Rốt, Khoai Tây, Gạo ST25, Cà Phê...

### 2. **Giỏ Hàng** ✅
- **Thêm sản phẩm**: Quản lý số lượng khi thêm vào giỏ
- **Chỉnh sửa đơn hàng**: Tăng/giảm số lượng hoặc xóa sản phẩm
- **Tính toán tự động**: Cập nhật tổng tiền theo thay đổi
- **Hiển thị chi tiết**: Ảnh sản phẩm, tên, đơn giá, số lượng, thành tiền

### 3. **Thanh Toán** ✅
- **Quy trình thanh toán**: Xem tóm tắt đơn hàng, địa chỉ giao hàng, phương thức thanh toán
- **Phương thức thanh toán**: VNPAY (có thể mở rộng)
- **Tính phí vận chuyển**: Tự động tính tổng tiền với phí vận chuyển
- **Xác nhận đơn hàng**: Đặt hàng và nhận mã đơn hàng

### 4. **Quản Lý Đơn Hàng** ✅
- **Xem danh sách đơn hàng**: Hiển thị tất cả đơn hàng của khách hàng
- **Trạng thái đơn hàng**: CREATED, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
- **Chi tiết đơn hàng**: Xem sản phẩm, số lượng, giá, ngày đặt hàng, trạng thái
- **Lịch sử đơn hàng**: Lưu trữ đầy đủ thông tin cho mỗi đơn hàng

### 5. **Cơ Sở Dữ Liệu SQLite** ✅
- **Bảng sản phẩm**: commerce_Products
- **Bảng người dùng**: Users
- **Bảng hình ảnh**: Images (polymorphic, hỗ trợ hình ảnh cho sản phẩm)
- **Bảng giỏ hàng**: commerce_Carts, commerce_CartItems
- **Bảng đơn hàng**: commerce_Orders, commerce_OrderItems
- **Dữ liệu mẫu**: 30 sản phẩm, 4 người dùng, giỏ hàng mẫu

## Cấu Trúc Project

```
lib/
├── main.dart                          # Entry point
├── models/
│   ├── product.dart                   # Model sản phẩm
│   ├── cart.dart                      # Model giỏ hàng
│   ├── cart_item.dart                 # Model mục giỏ hàng
│   ├── order.dart                     # Model đơn hàng
│   └── order_item.dart                # Model mục đơn hàng
├── services/
│   └── database_service.dart          # Dịch vụ SQLite
└── screens/
    ├── product_list_screen.dart       # Danh sách sản phẩm
    ├── product_detail_screen.dart     # Chi tiết sản phẩm
    ├── cart_screen.dart               # Giỏ hàng
    ├── checkout_screen.dart           # Thanh toán
    ├── order_success_screen.dart      # Xác nhận thành công
    ├── order_detail_screen.dart       # Chi tiết đơn hàng
    └── orders_list_screen.dart        # Danh sách đơn hàng
```

## Cài Đặt & Chạy

### Yêu cầu
- Flutter 3.10.4+
- Dart 3.0.0+

### Bước 1: Cài đặt Dependencies
```bash
cd guardian
flutter pub get
```

### Bước 2: Chạy ứng dụng
```bash
flutter run
```

Ứng dụng sẽ:
1. Khởi tạo cơ sở dữ liệu SQLite
2. Tạo tất cả các bảng
3. Thêm 30 sản phẩm mẫu
4. Mở ứng dụng trên thiết bị/emulator

## Luồng Sử Dụng

### 1. Xem Sản Phẩm
```
Trang Chủ → Danh Sách Sản Phẩm → Lọc Danh Mục → Chọn Sản Phẩm
```

### 2. Thêm Vào Giỏ Hàng
```
Chi Tiết Sản Phẩm → Chọn Số Lượng → Thêm Vào Giỏ Hàng
```

### 3. Thanh Toán
```
Giỏ Hàng → Xem Chi Tiết → Thanh Toán → Xác Nhận Đơn Hàng → Thành Công
```

### 4. Xem Đơn Hàng
```
Trang Chủ → Tab Đơn Hàng → Chọn Đơn Hàng → Xem Chi Tiết
```

## Sản Phẩm Mẫu

| STT | Tên Sản Phẩm | Danh Mục | Giá (đ) | Đơn Vị |
|-----|------------|---------|--------|-------|
| 1 | Xoài Cát | Trái Cây | 50,000 | Kg |
| 2 | Sầu Riêng | Trái Cây | 120,000 | Kg |
| 3 | Bơ Sáp | Trái Cây | 40,000 | Kg |
| 4 | Thanh Long | Trái Cây | 25,000 | Kg |
| 5 | Cà Chua | Rau Củ | 40,000 | Kg |
| 6 | Dưa Leo | Rau Củ | 20,000 | Kg |
| 7 | Cà Rốt | Rau Củ | 25,000 | Kg |
| 8 | Khoai Tây | Rau Củ | 30,000 | Kg |
| 9 | Gạo ST25 | Ngũ Cốc | 35,000 | Kg |
| 10 | Cà Phê | Đồ Uống | 150,000 | Kg |

## Dependencies

```yaml
sqflite: ^2.3.0              # SQLite database
path: ^1.8.3                 # Path utilities
intl: ^0.19.0                # Internationalization
image_picker: ^1.0.0         # Pick images
cached_network_image: ^3.3.0 # Cache images
```

## Database Schema

### Users
- UserId (PRIMARY KEY)
- PhoneNumber (UNIQUE)
- Email (UNIQUE)
- PasswordHash
- RoleType (FARMER, SME, ADMIN)
- DisplayName
- IsActive
- CreatedAt

### commerce_Products
- ProductId (PRIMARY KEY)
- SellerId (FOREIGN KEY)
- Title
- Description
- Category
- Price
- Unit
- CreatedAt

### commerce_Carts
- CartId (PRIMARY KEY)
- UserId (FOREIGN KEY)
- UpdatedAt

### commerce_Orders
- OrderId (PRIMARY KEY)
- BuyerId (FOREIGN KEY)
- OrderTotal
- Status
- CreatedAt

### Images
- ImageId (PRIMARY KEY)
- ReferenceId
- ReferenceType (POLYMORPHIC)
- ImageUrl
- IsPrimary
- DisplayOrder

## Các Tính Năng Có Thể Mở Rộng

1. **Xác Thực Người Dùng**
   - Đăng ký/Đăng nhập
   - Quản lý hồ sơ người dùng
   - Mật khẩu an toàn

2. **Thanh Toán Nâng Cao**
   - Tích hợp VNPAY API
   - Hỗ trợ nhiều phương thức thanh toán
   - Lịch sử giao dịch

3. **Quản Lý Bán Hàng**
   - Thêm sản phẩm mới
   - Quản lý kho
   - Theo dõi doanh số

4. **Đánh Giá & Bình Luận**
   - Đánh giá sản phẩm
   - Bình luận của khách hàng
   - Hình ảnh đánh giá

5. **Thông Báo**
   - Thông báo đơn hàng
   - Promotions & Discount
   - Cập nhật sản phẩm mới

6. **Tìm Kiếm Nâng Cao**
   - Tìm kiếm theo từ khóa
   - Sắp xếp theo giá
   - Lọc theo nhiều tiêu chí

## Tài Khoản Demo

Để test các chức năng:
- **User ID**: 33333333-3333-3333-3333-333333333333 (Người mua)
- **Seller ID**: 11111111-1111-1111-1111-111111111111, 22222222-2222-2222-2222-222222222222

## Hỗ Trợ & Liên Hệ

Để báo cáo lỗi hoặc yêu cầu tính năng, vui lòng tạo issue trong repository.

## Giấy Phép

Dự án này được cấp phép theo MIT License.

---

**Version**: 1.0.0
**Ngày phát hành**: March 2026
**Tác giả**: Digital Village Team
