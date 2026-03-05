// =============================================================
// database_helper.dart
// SQLite Database Manager cho PRM393
// Không lạm dụng static
// =============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'migrations.dart';

// =============================================================
// DATABASE CONFIG
// =============================================================

class DatabaseConfig {
  final String name;
  final int version;

  const DatabaseConfig({required this.name, required this.version});
}

const databaseConfig = DatabaseConfig(name: 'prm393.db', version: 1);

// =============================================================
// DATABASE PROVIDER
// =============================================================

class DatabaseProvider {
  DatabaseProvider({required this.config});

  final DatabaseConfig config;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, config.name);

    return openDatabase(
      path,
      version: config.version,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute("PRAGMA encoding = 'UTF-8';");
      },
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> reset() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, config.name);

    await close();
    await deleteDatabase(path);

    _database = await _open();
  }
}

// =============================================================
// DATABASE SERVICE
// Generic CRUD helper
// =============================================================

class DatabaseService {
  DatabaseService(this.provider);

  final DatabaseProvider provider;

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await provider.database;

    return db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool distinct = false,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await provider.database;

    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryById(
    String table,
    String idColumn,
    int id,
  ) async {
    final result = await query(
      table,
      where: '$idColumn = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await provider.database;

    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await provider.database;

    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> count(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await provider.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $table'
      '${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await provider.database;
    return db.rawQuery(sql, args);
  }

  Future<void> rawExecute(String sql, [List<dynamic>? args]) async {
    final db = await provider.database;
    await db.execute(sql, args);
  }

  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    final db = await provider.database;

    final batch = db.batch();

    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }
}

// =============================================================
// DOMAIN QUERIES (Repository style)
// =============================================================

class DomainQueries {
  DomainQueries(this.db);

  final DatabaseService db;

  Future<List<Map<String, dynamic>>> getProductsWithSeller() {
    return db.rawQuery('''
      SELECT
        p.ProductId,
        p.Title,
        p.Price,
        p.Unit,
        p.Category,
        u.DisplayName AS SellerName
      FROM commerce_Products p
      JOIN Users u ON p.SellerId = u.UserId
      ORDER BY p.CreatedAt DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getFarmsByFarmer(int farmerId) {
    return db.rawQuery(
      '''
      SELECT f.*, i.ImageUrl AS FarmImageUrl
      FROM iot_Farms f
      LEFT JOIN Images i ON i.ReferenceId = f.FarmId
        AND i.ReferenceType = 'FARM' AND i.IsPrimary = 1
      WHERE f.FarmerId = ?
    ''',
      [farmerId],
    );
  }

  Future<List<Map<String, dynamic>>> getDevicesWithLatestReading(int farmId) {
    return db.rawQuery(
      '''
      SELECT d.*, r.MetricType, r.MetricValue, r.RecordedAt
      FROM iot_IoTDevices d
      LEFT JOIN iot_IoTSensorReadings r ON r.DeviceId = d.DeviceId
        AND r.ReadingId = (
          SELECT MAX(ReadingId) 
          FROM iot_IoTSensorReadings
          WHERE DeviceId = d.DeviceId
        )
      WHERE d.FarmId = ?
    ''',
      [farmId],
    );
  }

  Future<List<Map<String, dynamic>>> getOrdersByBuyer(int buyerId) {
    return db.rawQuery(
      '''
      SELECT o.*, oi.ProductId, oi.Quantity, oi.Price,
             p.Title AS ProductTitle
      FROM commerce_Orders o
      JOIN commerce_OrderItems oi ON oi.OrderId = o.OrderId
      JOIN commerce_Products   p  ON p.ProductId = oi.ProductId
      WHERE o.BuyerId = ?
      ORDER BY o.CreatedAt DESC
    ''',
      [buyerId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications(int userId) {
    return db.query(
      'Notifications',
      where: 'UserId = ? AND IsRead = 0',
      whereArgs: [userId],
      orderBy: 'CreatedAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getBookingsByFarm(int farmId) {
    return db.rawQuery(
      '''
      SELECT b.*, m.MachineType, m.BasePricePerHour,
             u.DisplayName AS BookerName
      FROM logistics_MachineBookings b
      JOIN logistics_AgriMachines m ON m.MachineId = b.MachineId
      JOIN Users u ON u.UserId = b.BookerId
      WHERE b.FarmId = ?
      ORDER BY b.StartTime DESC
    ''',
      [farmId],
    );
  }

  Future<String?> getPrimaryImage(String referenceType, int referenceId) async {
    final result = await db.query(
      'Images',
      columns: ['ImageUrl'],
      where: 'ReferenceType = ? AND ReferenceId = ? AND IsPrimary = 1',
      whereArgs: [referenceType, referenceId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['ImageUrl'] as String?;
  }
}
