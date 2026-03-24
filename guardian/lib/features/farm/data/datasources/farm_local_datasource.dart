// Farm Local Data Source
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/domain/entities/farm_image.dart';
import 'package:guardian/core/database/database_helper.dart';

abstract class FarmLocalDataSource {
  /// Lấy danh sách các nông dân
  Future<List<Farmer>> getAllFarmers();

  /// Lấy thông tin nông dân theo UserID
  Future<Farmer?> getFarmerById(int userId);

  /// Thêm/Cập nhật nông dân
  Future<int> saveFarmer(Farmer farmer);

  /// Xóa nông dân
  Future<bool> deleteFarmer(int userId);

  /// Tìm nông dân theo tên
  Future<List<Farmer>> searchFarmersByName(String query);

  // =========== FARM OPERATIONS ===========

  /// Lấy danh sách tất cả trang trại
  Future<List<Farm>> getAllFarms();

  /// Lấy danh sách trang trại của một nông dân
  Future<List<Farm>> getFarmsByFarmerId(int farmerId);

  /// Lấy thông tin chi tiết của trang trại
  Future<Farm?> getFarmById(int farmId);

  /// Thêm trang trại mới
  Future<int> addFarm(Farm farm);

  /// Cập nhật trang trại
  Future<bool> updateFarm(Farm farm);

  /// Xóa trang trại
  Future<bool> deleteFarm(int farmId);

  // =========== IMAGE OPERATIONS ===========

  /// Lấy ảnh của trang trại
  Future<List<FarmImage>> getImagesByFarmId(int farmId);

  /// Thêm ảnh
  Future<int> addImage(FarmImage image);

  /// Cập nhật ảnh chính
  Future<bool> setPrimaryImage(int farmId, int imageId);

  /// Xóa ảnh
  Future<bool> deleteImage(int imageId);
}

class FarmLocalDataSourceImpl implements FarmLocalDataSource {
  final DatabaseService dbService;

  FarmLocalDataSourceImpl(this.dbService);

  // ========== FARMER OPERATIONS ==========

  @override
  Future<List<Farmer>> getAllFarmers() async {
    final db = await dbService.provider.database;

    const query = '''
      SELECT UserId, FullName, Village, ContactName, ContactPhone, PreferredVoice
      FROM FarmerProfiles
      ORDER BY FullName ASC
    ''';

    final results = await db.rawQuery(query);

    return results
        .map((row) => Farmer(
              userId: row['UserId'] as int,
              fullName: row['FullName'] as String,
              village: row['Village'] as String?,
              contactName: row['ContactName'] as String?,
              contactPhone: row['ContactPhone'] as String?,
              preferredVoice: row['PreferredVoice'] as int? ?? 1,
            ))
        .toList();
  }

  @override
  Future<Farmer?> getFarmerById(int userId) async {
    final db = await dbService.provider.database;

    const query = '''
      SELECT UserId, FullName, Village, ContactName, ContactPhone, PreferredVoice
      FROM FarmerProfiles
      WHERE UserId = ?
    ''';

    final results = await db.rawQuery(query, [userId]);

    if (results.isEmpty) return null;

    final row = results.first;
    return Farmer(
      userId: row['UserId'] as int,
      fullName: row['FullName'] as String,
      village: row['Village'] as String?,
      contactName: row['ContactName'] as String?,
      contactPhone: row['ContactPhone'] as String?,
      preferredVoice: row['PreferredVoice'] as int? ?? 1,
    );
  }

  @override
  Future<int> saveFarmer(Farmer farmer) async {
    final db = await dbService.provider.database;

    // Kiểm tra nông dân đã tồn tại chưa
    final existing = await db.query(
      'FarmerProfiles',
      where: 'UserId = ?',
      whereArgs: [farmer.userId],
    );

    if (existing.isNotEmpty) {
      // Update
      await db.update(
        'FarmerProfiles',
        {
          'FullName': farmer.fullName,
          'Village': farmer.village,
          'ContactName': farmer.contactName,
          'ContactPhone': farmer.contactPhone,
          'PreferredVoice': farmer.preferredVoice,
        },
        where: 'UserId = ?',
        whereArgs: [farmer.userId],
      );
      return farmer.userId;
    } else {
      // Insert
      return await db.insert('FarmerProfiles', {
        'UserId': farmer.userId,
        'FullName': farmer.fullName,
        'Village': farmer.village,
        'ContactName': farmer.contactName,
        'ContactPhone': farmer.contactPhone,
        'PreferredVoice': farmer.preferredVoice,
      });
    }
  }

  @override
  Future<bool> deleteFarmer(int userId) async {
    final db = await dbService.provider.database;

    final result = await db.delete(
      'FarmerProfiles',
      where: 'UserId = ?',
      whereArgs: [userId],
    );

    return result > 0;
  }

  @override
  Future<List<Farmer>> searchFarmersByName(String query) async {
    final db = await dbService.provider.database;

    const baseQuery = '''
      SELECT UserId, FullName, Village, ContactName, ContactPhone, PreferredVoice
      FROM FarmerProfiles
      WHERE FullName LIKE ?
      ORDER BY FullName ASC
    ''';

    final results = await db.rawQuery(baseQuery, ['%$query%']);

    return results
        .map((row) => Farmer(
              userId: row['UserId'] as int,
              fullName: row['FullName'] as String,
              village: row['Village'] as String?,
              contactName: row['ContactName'] as String?,
              contactPhone: row['ContactPhone'] as String?,
              preferredVoice: row['PreferredVoice'] as int? ?? 1,
            ))
        .toList();
  }

  // ========== FARM OPERATIONS ==========

  @override  Future<List<Farm>> getAllFarms() async {
    final db = await dbService.provider.database;

    const query = '''
      SELECT f.FarmId, f.FarmerId, p.FullName AS FarmerName, f.FarmName, f.Location, f.AreaHectares, f.CropType, f.Certifications
      FROM iot_Farms f
      LEFT JOIN FarmerProfiles p ON f.FarmerId = p.UserId
      ORDER BY f.FarmName ASC
      LIMIT 1000
    ''';

    final results = await db.rawQuery(query);

    return results
        .map((row) => Farm(
              farmId: row['FarmId'] as int,
              farmerId: row['FarmerId'] as int,
              farmerName: row['FarmerName'] as String?,
              farmName: row['FarmName'] as String?,
              location: row['Location'] as String?,
              areaHectares: (row['AreaHectares'] as num?)?.toDouble() ?? 0.0,
              cropType: row['CropType'] as String?,
              certifications: row['Certifications'] as String?,
            ))
        .toList();
  }

  @override  Future<List<Farm>> getFarmsByFarmerId(int farmerId) async {
    final db = await dbService.provider.database;

    const query = '''
      SELECT f.FarmId, f.FarmerId, p.FullName AS FarmerName, f.FarmName, f.Location, f.AreaHectares, f.CropType, f.Certifications
      FROM iot_Farms f
      LEFT JOIN FarmerProfiles p ON f.FarmerId = p.UserId
      WHERE f.FarmerId = ?
      ORDER BY f.FarmName ASC
    ''';

    final results = await db.rawQuery(query, [farmerId]);

    return results
        .map((row) => Farm(
              farmId: row['FarmId'] as int,
              farmerId: row['FarmerId'] as int,
              farmerName: row['FarmerName'] as String?,
              farmName: row['FarmName'] as String?,
              location: row['Location'] as String?,
              areaHectares: (row['AreaHectares'] as num?)?.toDouble() ?? 0.0,
              cropType: row['CropType'] as String?,
              certifications: row['Certifications'] as String?,
            ))
        .toList();
  }

  @override
  Future<Farm?> getFarmById(int farmId) async {
    final db = await dbService.provider.database;

    const query = '''
      SELECT f.FarmId, f.FarmerId, p.FullName AS FarmerName, f.FarmName, f.Location, f.AreaHectares, f.CropType, f.Certifications
      FROM iot_Farms f
      LEFT JOIN FarmerProfiles p ON f.FarmerId = p.UserId
      WHERE f.FarmId = ?
    ''';

    final results = await db.rawQuery(query, [farmId]);

    if (results.isEmpty) return null;

    final row = results.first;
    return Farm(
      farmId: row['FarmId'] as int,
      farmerId: row['FarmerId'] as int,
      farmerName: row['FarmerName'] as String?,
      farmName: row['FarmName'] as String?,
      location: row['Location'] as String?,
      areaHectares: (row['AreaHectares'] as num?)?.toDouble() ?? 0.0,
      cropType: row['CropType'] as String?,
      certifications: row['Certifications'] as String?,
    );
  }

  @override
  Future<int> addFarm(Farm farm) async {
    final db = await dbService.provider.database;

    return await db.insert('iot_Farms', {
      'FarmerId': farm.farmerId,
      'FarmName': farm.farmName,
      'Location': farm.location,
      'AreaHectares': farm.areaHectares,
      'CropType': farm.cropType,
      'Certifications': farm.certifications,
    });
  }

  @override
  Future<bool> updateFarm(Farm farm) async {
    final db = await dbService.provider.database;

    final result = await db.update(
      'iot_Farms',
      {
        'FarmName': farm.farmName,
        'Location': farm.location,
        'AreaHectares': farm.areaHectares,
        'CropType': farm.cropType,
        'Certifications': farm.certifications,
      },
      where: 'FarmId = ?',
      whereArgs: [farm.farmId],
    );

    return result > 0;
  }

  @override
  Future<bool> deleteFarm(int farmId) async {
    final db = await dbService.provider.database;

    final result = await db.delete(
      'iot_Farms',
      where: 'FarmId = ?',
      whereArgs: [farmId],
    );

    return result > 0;
  }

  // ========== IMAGE OPERATIONS ==========

  @override
  Future<List<FarmImage>> getImagesByFarmId(int farmId) async {
    final db = await dbService.provider.database;

    const query = '''
      SELECT ImageId, ReferenceId, ReferenceType, ImageUrl, IsPrimary, DisplayOrder, UploadedAt
      FROM Images
      WHERE ReferenceId = ? AND ReferenceType = 'FARM'
      ORDER BY DisplayOrder ASC
    ''';

    final results = await db.rawQuery(query, [farmId]);

    return results
        .map((row) => FarmImage(
              imageId: row['ImageId'] as int,
              referenceId: row['ReferenceId'] as int,
              referenceType: row['ReferenceType'] as String,
              imageUrl: row['ImageUrl'] as String,
              isPrimary: row['IsPrimary'] as int? ?? 0,
              displayOrder: row['DisplayOrder'] as int? ?? 0,
              uploadedAt: row['UploadedAt'] as String?,
            ))
        .toList();
  }

  @override
  Future<int> addImage(FarmImage image) async {
    final db = await dbService.provider.database;

    return await db.insert('Images', {
      'ReferenceId': image.referenceId,
      'ReferenceType': image.referenceType,
      'ImageUrl': image.imageUrl,
      'IsPrimary': image.isPrimary,
      'DisplayOrder': image.displayOrder,
    });
  }

  @override
  Future<bool> setPrimaryImage(int farmId, int imageId) async {
    final db = await dbService.provider.database;

    // Bỏ primary từ ảnh cũ
    await db.update(
      'Images',
      {'IsPrimary': 0},
      where: 'ReferenceId = ? AND ReferenceType = ?',
      whereArgs: [farmId, 'FARM'],
    );

    // Đặt primary cho ảnh mới
    final result = await db.update(
      'Images',
      {'IsPrimary': 1},
      where: 'ImageId = ?',
      whereArgs: [imageId],
    );

    return result > 0;
  }

  @override
  Future<bool> deleteImage(int imageId) async {
    final db = await dbService.provider.database;

    final result = await db.delete(
      'Images',
      where: 'ImageId = ?',
      whereArgs: [imageId],
    );

    return result > 0;
  }
}
