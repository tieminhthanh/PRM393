import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'digital_village.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Create tables
    var batch = db.batch();
    batch.execute('''CREATE TABLE IF NOT EXISTS Users (
      UserId TEXT PRIMARY KEY,
      PhoneNumber TEXT UNIQUE NOT NULL,
      Email TEXT UNIQUE,
      PasswordHash BLOB NOT NULL,
      RoleType TEXT NOT NULL CHECK (RoleType IN ('FARMER','SME','ADMIN')),
      DisplayName TEXT,
      IsActive INTEGER NOT NULL DEFAULT 1,
      CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''');
    batch.execute('''CREATE TABLE IF NOT EXISTS Images (
      ImageId TEXT PRIMARY KEY,
      ReferenceId TEXT NOT NULL,
      ReferenceType TEXT NOT NULL CHECK (ReferenceType IN ('USER', 'PRODUCT', 'SME', 'FARM', 'CONSULTING')),
      ImageUrl TEXT NOT NULL,
      IsPrimary INTEGER DEFAULT 0,
      DisplayOrder INTEGER DEFAULT 0,
      UploadedAt TEXT DEFAULT CURRENT_TIMESTAMP
    )''');
    batch.execute('''CREATE INDEX IF NOT EXISTS IX_Images_Reference ON Images(ReferenceType, ReferenceId)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS commerce_Products (
      ProductId TEXT PRIMARY KEY,
      SellerId TEXT NOT NULL,
      Title TEXT NOT NULL,
      Description TEXT,
      Category TEXT,
      Price REAL NOT NULL,
      Unit TEXT,
      CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (SellerId) REFERENCES Users(UserId)
    )''');
    batch.execute('''CREATE TABLE IF NOT EXISTS commerce_Carts (
      CartId TEXT PRIMARY KEY,
      UserId TEXT NOT NULL,
      UpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (UserId) REFERENCES Users(UserId)
    )''');
    batch.execute('''CREATE TABLE IF NOT EXISTS commerce_CartItems (
      CartItemId TEXT PRIMARY KEY,
      CartId TEXT NOT NULL,
      ProductId TEXT NOT NULL,
      Quantity REAL NOT NULL,
      FOREIGN KEY (CartId) REFERENCES commerce_Carts(CartId),
      FOREIGN KEY (ProductId) REFERENCES commerce_Products(ProductId)
    )''');
    batch.execute('''CREATE TABLE IF NOT EXISTS commerce_Orders (
      OrderId TEXT PRIMARY KEY,
      BuyerId TEXT NOT NULL,
      OrderTotal REAL NOT NULL,
      Status TEXT DEFAULT 'CREATED',
      CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (BuyerId) REFERENCES Users(UserId)
    )''');
    batch.execute('''CREATE TABLE IF NOT EXISTS commerce_OrderItems (
      OrderItemId TEXT PRIMARY KEY,
      OrderId TEXT NOT NULL,
      ProductId TEXT NOT NULL,
      Quantity REAL NOT NULL,
      Price REAL NOT NULL,
      FOREIGN KEY (OrderId) REFERENCES commerce_Orders(OrderId),
      FOREIGN KEY (ProductId) REFERENCES commerce_Products(ProductId)
    )''');
    await batch.commit(noResult: true);

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Insert sample users
    const users = [
      ('11111111-1111-1111-1111-111111111111', '0901000001', 'farmer1@test.com', 'vendor1', 'FARMER', 'Nguyễn Văn Trồng'),
      ('22222222-2222-2222-2222-222222222222', '0901000002', 'farmer2@test.com', 'vendor2', 'FARMER', 'Trần Thị Cấy'),
      ('33333333-3333-3333-3333-333333333333', '0901000003', 'buyer1@test.com', 'buyer1', 'FARMER', 'Lê Văn Thu'),
      ('66666666-6666-6666-6666-666666666666', '0901000006', 'sme1@test.com', 'sme1', 'SME', 'CTY Nông Sản Xanh'),
    ];

    for (var user in users) {
      try {
        await db.insert(
          'Users',
          {
            'UserId': user.$1,
            'PhoneNumber': user.$2,
            'Email': user.$3,
            'PasswordHash': UTF8.encode(user.$4),
            'RoleType': user.$5,
            'DisplayName': user.$6,
            'IsActive': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // User already exists
      }
    }

    // Insert sample products
    final products = [
      ('P001', '11111111-1111-1111-1111-111111111111', 'Xoài Cát', 'Trái cây ngon lành từ nông trại', 'Trái Cây', 50000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Xoài+Cát'),
      ('P002', '11111111-1111-1111-1111-111111111111', 'Sầu Riêng', 'Sầu riêng ngon, chín đúng độ', 'Trái Cây', 120000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Sầu+Riêng'),
      ('P003', '22222222-2222-2222-2222-222222222222', 'Bơ Sáp', 'Bơ sáp tươi từ vườn', 'Trái Cây', 40000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Bơ+Sáp'),
      ('P004', '22222222-2222-2222-2222-222222222222', 'Thanh Long', 'Thanh long đỏ tươi', 'Trái Cây', 25000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Thanh+Long'),
      ('P005', '11111111-1111-1111-1111-111111111111', 'Cà Chua', 'Cà chua tươi, chất lượng cao', 'Rau Củ', 40000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Cà+Chua'),
      ('P006', '22222222-2222-2222-2222-222222222222', 'Dưa Leo', 'Dưa leo giòn, mát lạnh', 'Rau Củ', 20000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Dưa+Leo'),
      ('P007', '11111111-1111-1111-1111-111111111111', 'Cà Rốt', 'Cà rốt cam đỏ, giàu dinh dưỡng', 'Rau Củ', 25000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Cà+Rốt'),
      ('P008', '22222222-2222-2222-2222-222222222222', 'Khoai Tây', 'Khoai tây tươi, vàng ươm', 'Rau Củ', 30000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Khoai+Tây'),
      ('P009', '11111111-1111-1111-1111-111111111111', 'Gạo ST25', 'Gạo thơm nổi tiếng, dẻo thơm', 'Ngũ Cốc', 35000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Gạo+ST25'),
      ('P010', '22222222-2222-2222-2222-222222222222', 'Cà Phê', 'Cà phê đen đậm, thơm ngon', 'Đồ uống', 150000.0, 'Kg', 'https://via.placeholder.com/300x300?text=Cà+Phê'),
    ];

    for (var product in products) {
      try {
        await db.insert(
          'commerce_Products',
          {
            'ProductId': product.$1,
            'SellerId': product.$2,
            'Title': product.$3,
            'Description': product.$4,
            'Category': product.$5,
            'Price': product.$6,
            'Unit': product.$7,
            'CreatedAt': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        
        // Insert product image
        await db.insert(
          'Images',
          {
            'ImageId': 'IMG_${product.$1}',
            'ReferenceId': product.$1,
            'ReferenceType': 'PRODUCT',
            'ImageUrl': product.$8,
            'IsPrimary': 1,
            'DisplayOrder': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // Product already exists
      }
    }

    // Insert sample cart
    try {
      await db.insert(
        'commerce_Carts',
        {
          'CartId': 'CART001',
          'UserId': '33333333-3333-3333-3333-333333333333',
          'UpdatedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      // Cart already exists
    }
  }

  // Product operations
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('commerce_Products');
    
    final products = <Product>[];
    for (var row in result) {
      final product = Product.fromMap(row);
      // Get image
      final imageResult = await db.query(
        'Images',
        where: 'ReferenceId = ? AND ReferenceType = ? AND IsPrimary = 1',
        whereArgs: [product.productId, 'PRODUCT'],
        limit: 1,
      );
      
      if (imageResult.isNotEmpty) {
        products.add(Product(
          productId: product.productId,
          sellerId: product.sellerId,
          title: product.title,
          description: product.description,
          category: product.category,
          price: product.price,
          unit: product.unit,
          imageUrl: imageResult.first['ImageUrl'] as String?,
          createdAt: product.createdAt,
        ));
      } else {
        products.add(product);
      }
    }
    return products;
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'commerce_Products',
      where: 'Category = ?',
      whereArgs: [category],
    );
    
    final products = <Product>[];
    for (var row in result) {
      final product = Product.fromMap(row);
      final imageResult = await db.query(
        'Images',
        where: 'ReferenceId = ? AND ReferenceType = ? AND IsPrimary = 1',
        whereArgs: [product.productId, 'PRODUCT'],
        limit: 1,
      );
      
      if (imageResult.isNotEmpty) {
        products.add(Product(
          productId: product.productId,
          sellerId: product.sellerId,
          title: product.title,
          description: product.description,
          category: product.category,
          price: product.price,
          unit: product.unit,
          imageUrl: imageResult.first['ImageUrl'] as String?,
          createdAt: product.createdAt,
        ));
      } else {
        products.add(product);
      }
    }
    return products;
  }

  Future<Product?> getProductById(String productId) async {
    final db = await database;
    final result = await db.query(
      'commerce_Products',
      where: 'ProductId = ?',
      whereArgs: [productId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    final product = Product.fromMap(result.first);
    final imageResult = await db.query(
      'Images',
      where: 'ReferenceId = ? AND ReferenceType = ? AND IsPrimary = 1',
      whereArgs: [product.productId, 'PRODUCT'],
      limit: 1,
    );
    
    if (imageResult.isNotEmpty) {
      return Product(
        productId: product.productId,
        sellerId: product.sellerId,
        title: product.title,
        description: product.description,
        category: product.category,
        price: product.price,
        unit: product.unit,
        imageUrl: imageResult.first['ImageUrl'] as String?,
        createdAt: product.createdAt,
      );
    }
    return product;
  }

  Future<void> createProduct(Product product) async {
    final db = await database;
    await db.insert('commerce_Products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'commerce_Products',
      product.toMap(),
      where: 'ProductId = ?',
      whereArgs: [product.productId],
    );
  }

  Future<void> deleteProduct(String productId) async {
    final db = await database;
    await db.delete(
      'commerce_Products',
      where: 'ProductId = ?',
      whereArgs: [productId],
    );
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT Category FROM commerce_Products ORDER BY Category'
    );
    return result.map((e) => e['Category'] as String).toList();
  }

  // Cart operations
  Future<Cart?> getCart(String userId) async {
    final db = await database;
    final result = await db.query(
      'commerce_Carts',
      where: 'UserId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (result.isEmpty) {
      // Create a new cart
      final cartId = 'CART_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('commerce_Carts', {
        'CartId': cartId,
        'UserId': userId,
        'UpdatedAt': DateTime.now().toIso8601String(),
      });
      return Cart(
        cartId: cartId,
        userId: userId,
        items: [],
        updatedAt: DateTime.now(),
      );
    }
    
    final cart = Cart.fromMap(result.first);
    
    // Get cart items
    final itemsResult = await db.rawQuery('''
      SELECT ci.*, p.ProductId, p.Title, p.Description, p.Category, p.Price, p.Unit, p.CreatedAt
      FROM commerce_CartItems ci
      INNER JOIN commerce_Products p ON ci.ProductId = p.ProductId
      WHERE ci.CartId = ?
    ''', [cart.cartId]);
    
    final items = <CartItem>[];
    for (var row in itemsResult) {
      final product = Product.fromMap(row);
      final imageResult = await db.query(
        'Images',
        where: 'ReferenceId = ? AND ReferenceType = ? AND IsPrimary = 1',
        whereArgs: [product.productId, 'PRODUCT'],
        limit: 1,
      );
      
      if (imageResult.isNotEmpty) {
        final productWithImage = Product(
          productId: product.productId,
          sellerId: product.sellerId,
          title: product.title,
          description: product.description,
          category: product.category,
          price: product.price,
          unit: product.unit,
          imageUrl: imageResult.first['ImageUrl'] as String?,
          createdAt: product.createdAt,
        );
        items.add(CartItem(
          cartItemId: row['CartItemId'] as String,
          cartId: row['CartId'] as String,
          productId: row['ProductId'] as String,
          quantity: (row['Quantity'] as num).toDouble(),
          product: productWithImage,
        ));
      } else {
        items.add(CartItem(
          cartItemId: row['CartItemId'] as String,
          cartId: row['CartId'] as String,
          productId: row['ProductId'] as String,
          quantity: (row['Quantity'] as num).toDouble(),
          product: product,
        ));
      }
    }
    
    return Cart(
      cartId: cart.cartId,
      userId: cart.userId,
      items: items,
      updatedAt: cart.updatedAt,
    );
  }

  Future<void> addToCart(String cartId, String productId, double quantity) async {
    final db = await database;
    
    // Check if item already exists in cart
    final existing = await db.query(
      'commerce_CartItems',
      where: 'CartId = ? AND ProductId = ?',
      whereArgs: [cartId, productId],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Update quantity
      final currentQuantity = (existing.first['Quantity'] as num).toDouble();
      await db.update(
        'commerce_CartItems',
        {'Quantity': currentQuantity + quantity},
        where: 'CartItemId = ?',
        whereArgs: [existing.first['CartItemId']],
      );
    } else {
      // Insert new item
      final cartItemId = 'CARTITEM_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('commerce_CartItems', {
        'CartItemId': cartItemId,
        'CartId': cartId,
        'ProductId': productId,
        'Quantity': quantity,
      });
    }
    
    // Update cart updated time
    await db.update(
      'commerce_Carts',
      {'UpdatedAt': DateTime.now().toIso8601String()},
      where: 'CartId = ?',
      whereArgs: [cartId],
    );
  }

  Future<void> updateCartItem(String cartItemId, double quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
    } else {
      await db.update(
        'commerce_CartItems',
        {'Quantity': quantity},
        where: 'CartItemId = ?',
        whereArgs: [cartItemId],
      );
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final db = await database;
    await db.delete(
      'commerce_CartItems',
      where: 'CartItemId = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> clearCart(String cartId) async {
    final db = await database;
    await db.delete(
      'commerce_CartItems',
      where: 'CartId = ?',
      whereArgs: [cartId],
    );
  }

  // Order operations
  Future<List<Order>> getOrders(String userId) async {
    final db = await database;
    final result = await db.query(
      'commerce_Orders',
      where: 'BuyerId = ?',
      whereArgs: [userId],
      orderBy: 'CreatedAt DESC',
    );
    return result.map((map) => Order.fromMap(map)).toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    final db = await database;
    final result = await db.query(
      'commerce_Orders',
      where: 'OrderId = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Order.fromMap(result.first);
  }

  Future<String> createOrder(String userId, List<CartItem> items) async {
    final db = await database;
    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
    final totalAmount = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    
    await db.transaction((txn) async {
      // Create order
      await txn.insert('commerce_Orders', {
        'OrderId': orderId,
        'BuyerId': userId,
        'OrderTotal': totalAmount,
        'Status': 'CREATED',
        'CreatedAt': DateTime.now().toIso8601String(),
      });
      
      // Create order items
      for (var item in items) {
        final orderItemId = 'ORDERITEM_${DateTime.now().millisecondsSinceEpoch}_${item.productId}';
        await txn.insert('commerce_OrderItems', {
          'OrderItemId': orderItemId,
          'OrderId': orderId,
          'ProductId': item.productId,
          'Quantity': item.quantity,
          'Price': item.product?.price ?? 0,
        });
      }
    });
    
    return orderId;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final db = await database;
    await db.update(
      'commerce_Orders',
      {'Status': status},
      where: 'OrderId = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT oi.*, p.ProductId, p.Title, p.Description, p.Category, p.Price as ProductPrice, p.Unit, p.CreatedAt
      FROM commerce_OrderItems oi
      INNER JOIN commerce_Products p ON oi.ProductId = p.ProductId
      WHERE oi.OrderId = ?
    ''', [orderId]);
    
    final orderItems = <OrderItem>[];
    for (var row in result) {
      final product = Product.fromMap(row);
      final imageResult = await db.query(
        'Images',
        where: 'ReferenceId = ? AND ReferenceType = ? AND IsPrimary = 1',
        whereArgs: [product.productId, 'PRODUCT'],
        limit: 1,
      );
      
      if (imageResult.isNotEmpty) {
        final productWithImage = Product(
          productId: product.productId,
          sellerId: product.sellerId,
          title: product.title,
          description: product.description,
          category: product.category,
          price: product.price,
          unit: product.unit,
          imageUrl: imageResult.first['ImageUrl'] as String?,
          createdAt: product.createdAt,
        );
        orderItems.add(OrderItem(
          orderItemId: row['OrderItemId'] as String,
          orderId: row['OrderId'] as String,
          productId: row['ProductId'] as String,
          quantity: (row['Quantity'] as num).toDouble(),
          price: (row['Price'] as num).toDouble(),
          product: productWithImage,
        ));
      } else {
        orderItems.add(OrderItem(
          orderItemId: row['OrderItemId'] as String,
          orderId: row['OrderId'] as String,
          productId: row['ProductId'] as String,
          quantity: (row['Quantity'] as num).toDouble(),
          price: (row['Price'] as num).toDouble(),
          product: product,
        ));
      }
    }
    return orderItems;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}

class UTF8 {
  static List<int> encode(String string) {
    return string.codeUnits;
  }
}
