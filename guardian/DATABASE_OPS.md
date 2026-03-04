# 🗄️ Database Operations Guide

## Các Phương Thức Trong DatabaseService

### 1. Products Operations

#### Get All Products
```dart
List<Product> products = await dbService.getAllProducts();
// Trả về: Danh sách tất cả sản phẩm với hình ảnh
```

#### Get Products by Category
```dart
List<Product> products = await dbService.getProductsByCategory('Trái Cây');
// Trả về: Sản phẩm trong danh mục đó
```

#### Get Single Product
```dart
Product? product = await dbService.getProductById('P001');
// Trả về: Chi tiết sản phẩm hoặc null
```

#### Get All Categories
```dart
List<String> categories = await dbService.getCategories();
// Trả về: ['Trái Cây', 'Rau Củ', 'Ngũ Cốc', 'Đồ Uống']
```

#### Create New Product
```dart
Product newProduct = Product(
  productId: 'P011',
  sellerId: '11111111-1111-1111-1111-111111111111',
  title: 'Dâu Tây',
  description: 'Dâu tây tươi từ nông trại',
  category: 'Trái Cây',
  price: 60000,
  unit: 'Kg',
  imageUrl: 'https://example.com/image.jpg',
  createdAt: DateTime.now(),
);

await dbService.createProduct(newProduct);
```

#### Update Product
```dart
await dbService.updateProduct(updatedProduct);
```

#### Delete Product
```dart
await dbService.deleteProduct('P001');
```

---

### 2. Cart Operations

#### Get or Create Cart
```dart
String userId = '33333333-3333-3333-3333-333333333333';
Cart? cart = await dbService.getCart(userId);
// Nếu không có, tự động tạo cart mới
```

#### Add to Cart
```dart
await dbService.addToCart(
  'CART001',     // cartId
  'P001',        // productId
  5.0,           // quantity
);
// Nếu sản phẩm đã có, tăng số lượng
```

#### Update Cart Item
```dart
await dbService.updateCartItem(
  'CARTITEM001',  // cartItemId
  10.0,           // newQuantity (nếu <= 0 thì xóa)
);
```

#### Remove from Cart
```dart
await dbService.removeFromCart('CARTITEM001');
```

#### Clear Cart
```dart
await dbService.clearCart('CART001');
```

---

### 3. Order Operations

#### Get All Orders
```dart
String userId = '33333333-3333-3333-3333-333333333333';
List<Order> orders = await dbService.getOrders(userId);
// Trả về: Danh sách các đơn hàng của user, sắp xếp theo ngày mới nhất
```

#### Get Single Order
```dart
Order? order = await dbService.getOrderById('ORDER_123456');
// Trả về: Chi tiết đơn hàng hoặc null
```

#### Get Order Items
```dart
List<OrderItem> items = await dbService.getOrderItems('ORDER_123456');
// Trả về: Tất cả sản phẩm trong đơn hàng
```

#### Create Order
```dart
String userId = '33333333-3333-3333-3333-333333333333';
Cart? cart = await dbService.getCart(userId);

// Create order from cart items
String orderId = await dbService.createOrder(userId, cart!.items);
// Trả về: Mã đơn hàng mới tạo
```

#### Update Order Status
```dart
await dbService.updateOrderStatus('ORDER_123456', 'PROCESSING');
// Status có thể là: CREATED, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
```

---

## Mô Phỏng Quy Trình Thanh Toán

```dart
// 1. Lấy giỏ hàng của user
Cart? cart = await dbService.getCart(userId);

// 2. Kiểm tra giỏ có sản phẩm
if (cart == null || cart.items.isEmpty) {
  print('Giỏ hàng trống');
  return;
}

// 3. Tạo đơn hàng
String orderId = await dbService.createOrder(userId, cart.items);
print('Đơn hàng created: $orderId');

// 4. Xóa giỏ hàng
await dbService.clearCart(cart.cartId);

// 5. Xem chi tiết đơn hàng
Order? order = await dbService.getOrderById(orderId);
List<OrderItem> items = await dbService.getOrderItems(orderId);

// 6. Cập nhật trạng thái (giả lập)
await dbService.updateOrderStatus(orderId, 'CONFIRMED');
await dbService.updateOrderStatus(orderId, 'PROCESSING');
await dbService.updateOrderStatus(orderId, 'SHIPPED');
await dbService.updateOrderStatus(orderId, 'DELIVERED');
```

---

## SQL Queries Được Sử Dụng

### Join Products với Images
```sql
SELECT p.*, i.ImageUrl
FROM commerce_Products p
LEFT JOIN Images i 
  ON p.ProductId = i.ReferenceId 
  AND i.ReferenceType = 'PRODUCT'
  AND i.IsPrimary = 1
WHERE p.Category = ?
```

### Get Cart với Items
```sql
SELECT ci.*, p.*
FROM commerce_CartItems ci
INNER JOIN commerce_Products p ON ci.ProductId = p.ProductId
WHERE ci.CartId = ?
```

### Get Order Items
```sql
SELECT oi.*, p.*
FROM commerce_OrderItems oi
INNER JOIN commerce_Products p ON oi.ProductId = p.ProductId
WHERE oi.OrderId = ?
```

---

## Database Constraints

### Foreign Keys (Bật)
```sql
PRAGMA foreign_keys = ON;
```

### Unique Constraints
- `Users.PhoneNumber` - UNIQUE
- `Users.Email` - UNIQUE
- `commerce_ProductBatches.BatchCode` - UNIQUE
- `SMEProfiles.TaxCode` - UNIQUE

### Check Constraints
- `Users.RoleType` IN ('FARMER','SME','ADMIN')
- `RoleType` và `ReferenceType` (Polymorphic)
- `iot_IoTDevices.BatteryLevel` BETWEEN 0 AND 100

---

## Dữ Liệu Mẫu Ban Đầu

### 4 Users
```
Farmer 1: 11111111-1111-1111-1111-111111111111
Farmer 2: 22222222-2222-2222-2222-222222222222
Buyer:    33333333-3333-3333-3333-333333333333
SME:      66666666-6666-6666-6666-666666666666
```

### 10 Products
```
P001-P010: Xoài, Sầu, Bơ, Thanh Long, Cà Chua, Dưa, Cà Rốt, Khoai, Gạo, Cà Phê
```

### 1 Cart
```
CART001: Thuộc Buyer (User 33333...)
```

---

## Error Handling

```dart
try {
  List<Product> products = await dbService.getAllProducts();
} catch (e) {
  print('Error: $e');
  // Xử lý lỗi
}
```

---

## Performance Tips

1. **Pagination** - Thêm LIMIT và OFFSET cho danh sách dài
   ```dart
   // TODO: Thêm pagination
   ```

2. **Lazy Loading** - Tải ảnh khi scroll
   ```dart
   // Đã dùng cached_network_image
   ```

3. **Batch Operations** - Sử dụng transaction
   ```dart
   await db.transaction((txn) async {
     // Multiple operations
   });
   ```

4. **Indexing** - Đã có index trên Images
   ```sql
   CREATE INDEX IX_Images_Reference 
   ON Images(ReferenceType, ReferenceId);
   ```

---

## Debugging Database

### 1. Xem Database trên Device
```bash
# Android
adb shell
sqlite3 /data/data/com.example.guardian/databases/digital_village.db

# iOS (Xcode Device Organizer)
# macOS (Finder)
```

### 2. Export Database
```bash
adb pull /data/data/com.example.guardian/databases/digital_village.db
```

### 3. Raw SQL Query
```dart
// Sử dụng rawQuery để test SQL
final result = await db.rawQuery(
  'SELECT * FROM commerce_Products WHERE Price > ?',
  [50000]
);
```

---

## Migration (Nếu Cần)

Hiện tại database version = 1. Để nâng cấp:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Thêm bảng hoặc cột mới
    await db.execute('ALTER TABLE commerce_Products ADD COLUMN NewColumn TEXT');
  }
}

// Sửa trong _initDatabase()
return openDatabase(
  path,
  version: 2,  // Tăng version
  onUpgrade: _onUpgrade,
);
```

---

## Backup & Restore

```dart
// Export database
File dbFile = File(await getDatabasesPath() + '/digital_village.db');
await dbFile.copy('/sdcard/backup/digital_village.db');

// Import database
File backupFile = File('/sdcard/backup/digital_village.db');
await backupFile.copy(await getDatabasesPath() + '/digital_village.db');
```

---

**Happy Database Operations! 🗄️**
