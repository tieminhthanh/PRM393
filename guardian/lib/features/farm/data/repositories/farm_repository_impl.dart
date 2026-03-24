// Farm Repository Implementation
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/domain/entities/farm_image.dart';
import 'package:guardian/features/farm/data/datasources/farm_local_datasource.dart';

abstract class FarmRepository {
  /// Lấy danh sách nông dân
  Future<List<Farmer>> getAllFarmers();

  /// Lấy nông dân theo ID
  Future<Farmer?> getFarmerById(int userId);

  /// Lưu nông dân
  Future<int> saveFarmer(Farmer farmer);

  /// Xóa nông dân
  Future<bool> deleteFarmer(int userId);

  /// Tìm nông dân
  Future<List<Farmer>> searchFarmers(String query);

  // =========== FARM ===========
  Future<List<Farm>> getAllFarms();
  Future<List<Farm>> getFarmsByFarmerId(int farmerId);
  Future<Farm?> getFarmById(int farmId);
  Future<int> addFarm(Farm farm);
  Future<bool> updateFarm(Farm farm);
  Future<bool> deleteFarm(int farmId);

  // =========== IMAGE ===========
  Future<List<FarmImage>> getImagesByFarmId(int farmId);
  Future<int> addImage(FarmImage image);
  Future<bool> setPrimaryImage(int farmId, int imageId);
  Future<bool> deleteImage(int imageId);
}

class FarmRepositoryImpl implements FarmRepository {
  final FarmLocalDataSource localDataSource;

  FarmRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Farmer>> getAllFarmers() async {
    try {
      return await localDataSource.getAllFarmers();
    } catch (e) {
      throw Exception('Failed to get farmers: $e');
    }
  }

  @override
  Future<Farmer?> getFarmerById(int userId) async {
    try {
      return await localDataSource.getFarmerById(userId);
    } catch (e) {
      throw Exception('Failed to get farmer: $e');
    }
  }

  @override
  Future<int> saveFarmer(Farmer farmer) async {
    try {
      return await localDataSource.saveFarmer(farmer);
    } catch (e) {
      throw Exception('Failed to save farmer: $e');
    }
  }

  @override
  Future<bool> deleteFarmer(int userId) async {
    try {
      return await localDataSource.deleteFarmer(userId);
    } catch (e) {
      throw Exception('Failed to delete farmer: $e');
    }
  }

  @override
  Future<List<Farmer>> searchFarmers(String query) async {
    try {
      return await localDataSource.searchFarmersByName(query);
    } catch (e) {
      throw Exception('Failed to search farmers: $e');
    }
  }

  @override
  Future<List<Farm>> getAllFarms() async {
    try {
      return await localDataSource.getAllFarms();
    } catch (e) {
      throw Exception('Failed to get all farms: $e');
    }
  }

  @override
  Future<List<Farm>> getFarmsByFarmerId(int farmerId) async {
    try {
      return await localDataSource.getFarmsByFarmerId(farmerId);
    } catch (e) {
      throw Exception('Failed to get farms: $e');
    }
  }

  @override
  Future<Farm?> getFarmById(int farmId) async {
    try {
      return await localDataSource.getFarmById(farmId);
    } catch (e) {
      throw Exception('Failed to get farm: $e');
    }
  }

  @override
  Future<int> addFarm(Farm farm) async {
    try {
      return await localDataSource.addFarm(farm);
    } catch (e) {
      throw Exception('Failed to add farm: $e');
    }
  }

  @override
  Future<bool> updateFarm(Farm farm) async {
    try {
      return await localDataSource.updateFarm(farm);
    } catch (e) {
      throw Exception('Failed to update farm: $e');
    }
  }

  @override
  Future<bool> deleteFarm(int farmId) async {
    try {
      return await localDataSource.deleteFarm(farmId);
    } catch (e) {
      throw Exception('Failed to delete farm: $e');
    }
  }

  @override
  Future<List<FarmImage>> getImagesByFarmId(int farmId) async {
    try {
      return await localDataSource.getImagesByFarmId(farmId);
    } catch (e) {
      throw Exception('Failed to get images: $e');
    }
  }

  @override
  Future<int> addImage(FarmImage image) async {
    try {
      return await localDataSource.addImage(image);
    } catch (e) {
      throw Exception('Failed to add image: $e');
    }
  }

  @override
  Future<bool> setPrimaryImage(int farmId, int imageId) async {
    try {
      return await localDataSource.setPrimaryImage(farmId, imageId);
    } catch (e) {
      throw Exception('Failed to set primary image: $e');
    }
  }

  @override
  Future<bool> deleteImage(int imageId) async {
    try {
      return await localDataSource.deleteImage(imageId);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
