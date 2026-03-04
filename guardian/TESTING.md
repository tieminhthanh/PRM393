# Hướng Dẫn Test Ứng Dụng

## 1. Chuẩn Bị Test

### Bước 1: Cài đặt Flutter
```bash
flutter --version  # Kiểm tra version
flutter pub get     # Cài đặt dependencies
```

### Bước 2: Khởi động Emulator hoặc kết nối Device
```bash
flutter devices    # Liệt kê thiết bị
flutter run        # Chạy ứng dụng
```

## 2. Test Các Tính Năng Sản Phẩm

### Test 2.1: Xem Danh Sách Sản Phẩm
**Bước:**
1. Mở ứng dụng
2. Chọn tab "Sản Phẩm" (ở dưới)
3. Cuộn xuống xem danh sách sản phẩm

**Kết quả dự kiến:**
- ✅ Hiển thị 10 sản phẩm
- ✅ Mỗi sản phẩm có hình ảnh (placeholder), tên, danh mục, giá
- ✅ Hình ảnh từ endpoint https://via.placeholder.com

### Test 2.2: Lọc Sản Phẩm Theo Danh Mục
**Bước:**
1. Trên danh sách sản phẩm, xem chip các danh mục ở trên cùng
2. Nhấn "Tất cả" → hiển thị tất cả sản phẩm
3. Nhấn "Trái Cây" → hiển thị chỉ sản phẩm Trái Cây
4. Nhấn "Rau Củ" → hiển thị chỉ sản phẩm Rau Củ
5. Nhấn "Ngũ Cốc" → hiển thị chỉ sản phẩm Ngũ Cốc

**Kết quả dự kiến:**
- ✅ Lọc hoạt động chính xác cho từng danh mục
- ✅ Chip được highlight khi được chọn

### Test 2.3: Xem Chi Tiết Sản Phẩm
**Bước:**
1. Nhấn vào một sản phẩm (ví dụ: Xoài Cát)
2. Xem trang chi tiết sản phẩm

**Kết quả dự kiến:**
- ✅ Hiển thị hình ảnh lớn
- ✅ Hiển thị tên sản phẩm, danh mục, mô tả
- ✅ Hiển thị giá: "50000 đ / Kg"
- ✅ Có selector để chọn số lượng (1-N)

## 3. Test Giỏ Hàng

### Test 3.1: Thêm Sản Phẩm Vào Giỏ Hàng
**Bước:**
1. Ở trang chi tiết sản phẩm (Xoài Cát)
2. Chọn số lượng = 5
3. Nhấn nút "Thêm Vào Giỏ Hàng"

**Kết quả dự kiến:**
- ✅ Hiển thị thông báo: "Đã thêm 5 Kg vào giỏ hàng"
- ✅ Có thể thêm nhiều sản phẩm khác

### Test 3.2: Xem Giỏ Hàng
**Bước:**
1. Nhấn icon giỏ hàng ở góc trên phải (hoặc vào /cart)
2. Xem danh sách sản phẩm trong giỏ

**Kết quả dự kiến:**
- ✅ Hiển thị tất cả sản phẩm đã thêm
- ✅ Mỗi sản phẩm có: hình ảnh, tên, giá, số lượng
- ✅ Hiển thị thành tiền: số lượng × giá

### Test 3.3: Chỉnh Sửa Số Lượng Trong Giỏ
**Bước:**
1. Ở giỏ hàng, nhấn icon "-" để giảm số lượng
2. Nhấn icon "+" để tăng số lượng

**Kết quả dự kiến:**
- ✅ Số lượng thay đổi
- ✅ Thành tiền cập nhật tự động
- ✅ Tổng tiền cập nhật lại

### Test 3.4: Xóa Sản Phẩm Khỏi Giỏ
**Bước:**
1. Ở giỏ hàng, nhấn icon xóa (trash icon)

**Kết quả dự kiến:**
- ✅ Sản phẩm bị xóa
- ✅ Tổng tiền cập nhật

### Test 3.5: Xem Tổng Tiền
**Bước:**
1. Kiểm tra tổng tiền ở cuối giỏ hàng

**Kết quả dự kiến:**
- ✅ Tổng tiền = Sum(giá × số lượng) cho tất cả sản phẩm
- ✅ Hiển thị đúng: "VVV,VVV đ"

## 4. Test Thanh Toán

### Test 4.1: Tiến Tới Thanh Toán
**Bước:**
1. Ở giỏ hàng, nhấn "Thanh Toán"

**Kết quả dự kiến:**
- ✅ Chuyển tới trang thanh toán

### Test 4.2: Xem Tóm Tắt Đơn Hàng
**Bước:**
1. Xem phần "Đơn Hàng" trên trang thanh toán

**Kết quả dự kiến:**
- ✅ Hiển thị tất cả sản phẩm trong giỏ
- ✅ Hiển thị số lượng × giá cho mỗi sản phẩm

### Test 4.3: Xem Địa Chỉ Giao Hàng
**Bước:**
1. Xem phần "Địa Chỉ Giao Hàng"

**Kết quả dự kiến:**
- ✅ Hiển thị thông tin: Tên, SĐT, Địa chỉ

### Test 4.4: Xem Phương Thức Thanh Toán
**Bước:**
1. Xem phần "Phương Thức Thanh Toán"

**Kết quả dự kiến:**
- ✅ Hiển thị VNPAY được chọn (nút radio checked)

### Test 4.5: Xem Tính Toán Tiền
**Bước:**
1. Xem phần tính toán: Tạm tính, Phí vận chuyển, Tổng tiền

**Kết quả dự kiến:**
- ✅ Tạm tính = Tổng tiền sản phẩm
- ✅ Phí vận chuyển = 0đ (không tính)
- ✅ Tổng tiền = Tạm tính + Phí

### Test 4.6: Đặt Hàng
**Bước:**
1. Nhấn "Đặt Hàng"

**Kết quả dự kiến:**
- ✅ Hiển thị loading spinner
- ✅ Chuyển tới trang "Đặt Hàng Thành Công"

## 5. Test Xác Nhận Đơn Hàng

### Test 5.1: Xem Thông Báo Thành Công
**Bước:**
1. Xem trang "Đặt Hàng Thành Công"

**Kết quả dự kiến:**
- ✅ Hiển thị biểu tượng ✓ màu xanh
- ✅ Hiển thị thông báo "Đặt Hàng Thành Công!"
- ✅ Hiển thị mã đơn hàng (có thể copy)

### Test 5.2: Xem Chi Tiết Đơn Hàng
**Bước:**
1. Nhấn "Xem Chi Tiết Đơn Hàng"

**Kết quả dự kiến:**
- ✅ Chuyển tới trang chi tiết đơn hàng

### Test 5.3: Quay Về Trang Chủ
**Bước:**
1. Nhấn "Quay Về Trang Chủ"

**Kết quả dự kiến:**
- ✅ Chuyển tới trang chủ
- ✅ Giỏ hàng được xóa sạch

## 6. Test Quản Lý Đơn Hàng

### Test 6.1: Xem Danh Sách Đơn Hàng
**Bước:**
1. Từ trang chủ, nhấn tab "Đơn Hàng"

**Kết quả dự kiến:**
- ✅ Hiển thị danh sách các đơn hàng đã tạo
- ✅ Mỗi đơn hiển thị: Mã đơn, Ngày đặt, Trạng thái, Tổng tiền

### Test 6.2: Xem Chi Tiết Đơn Hàng
**Bước:**
1. Nhấn vào một đơn hàng từ danh sách

**Kết quả dự kiến:**
- ✅ Hiển thị chi tiết đơn hàng
- ✅ Hiển thị mã đơn hàng, trạng thái, ngày đặt
- ✅ Hiển thị tất cả sản phẩm trong đơn
- ✅ Hiển thị tổng tiền

## 7. Test Database

### Test 7.1: Kiểm Tra Dữ Liệu Ban Đầu
**Cách kiểm tra:**
1. Dùng Android Studio / Xcode để kết nối database
2. hoặc dùng công cụ: `adb shell`

```bash
adb shell
sqlite3 /data/data/com.example.guardian/databases/digital_village.db
SELECT COUNT(*) FROM commerce_Products;  # Kết quả: 10
SELECT COUNT(*) FROM Users;              # Kết quả: 4
```

**Kết quả dự kiến:**
- ✅ 10 sản phẩm
- ✅ 4 người dùng
- ✅ 30 hình ảnh

## 8. Test Hiệu Năng

### Test 8.1: Tốc Độ Tải Sản Phẩm
- ✅ Danh sách sản phẩm tải trong < 1 giây

### Test 8.2: Tốc Độ Tìm Kiếm/Lọc
- ✅ Lọc danh mục < 500ms

### Test 8.3: Tốc Độ Tạo Đơn Hàng
- ✅ Đặt hàng hoàn tất < 1 giây

## 9. Test Edge Cases

### Test 9.1: Giỏ Hàng Trống
**Bước:**
1. Xóa tất cả sản phẩm khỏi giỏ
2. Vào tab "Giỏ Hàng"

**Kết quả dự kiến:**
- ✅ Hiển thị thông báo "Giỏ hàng trống"
- ✅ Nút "Thanh Toán" bị disable

### Test 9.2: Không Có Đơn Hàng
**Bước:**
1. User mới/chưa có đơn hàng vào tab "Đơn Hàng"

**Kết quả dự kiến:**
- ✅ Hiển thị thông báo "Không có đơn hàng nào"

### Test 9.3: Số Lượng Âm
**Bước:**
1. Cố gắng nhập số lượng âm

**Kết quả dự kiến:**
- ✅ Không chấp nhận số lượng <= 0

### Test 9.4: Hình Ảnh Không Tải
**Bước:**
1. Mất kết nối internet
2. Xem danh sách sản phẩm

**Kết quả dự kiến:**
- ✅ Hiển thị icon placeholder thay vì lỗi

## 10. Test Giao Diện

### Test 10.1: Responsive Design
- ✅ Ứng dụng hoạt động tốt trên: 
  - Di động (5", 6", 6.5")
  - Tablet (7", 10")

### Test 10.2: Dark Mode (nếu cần)
- ✅ Giao diện sáng/tối nhất quán

### Test 10.3: Định Hướng Màn Hình
- ✅ Ngang & dọc đều hoạt động

## 11. Yêu Cầu Test

Sau khi hoàn tất tất cả test, hãy kiểm tra:

- [ ] Tất cả sản phẩm hiển thị đúng
- [ ] Lọc danh mục hoạt động
- [ ] Thêm/sửa/xóa giỏ hàng hoạt động
- [ ] Thanh toán hoàn tất thành công
- [ ] Xem đơn hàng đã tạo
- [ ] Chi tiết đơn hàng đầy đủ
- [ ] Không có crash/error
- [ ] Giao diện đẹp trên mọi kích thước

## 12. Báo Cáo Lỗi

Nếu tìm thấy lỗi:
1. Ghi lại bước tái hiện
2. Chụp screenshot
3. Kiểm tra log: `flutter logs`
4. Báo cáo chi tiết

---

**Happy Testing! 🎉**
