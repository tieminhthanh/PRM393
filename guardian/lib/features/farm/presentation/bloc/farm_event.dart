// Farm Events
abstract class FarmEvent {
  const FarmEvent();
}

// Farmer Events
class LoadFarmersEvent extends FarmEvent {
  const LoadFarmersEvent();
}

class SearchFarmersEvent extends FarmEvent {
  final String query;
  const SearchFarmersEvent(this.query);
}

class SaveFarmerEvent extends FarmEvent {
  final int userId;
  final String fullName;
  final String? village;
  final String? contactName;
  final String? contactPhone;
  final int preferredVoice;

  const SaveFarmerEvent({
    required this.userId,
    required this.fullName,
    this.village,
    this.contactName,
    this.contactPhone,
    this.preferredVoice = 1,
  });
}

class DeleteFarmerEvent extends FarmEvent {
  final int userId;
  const DeleteFarmerEvent(this.userId);
}

class LoadFarmerDetailEvent extends FarmEvent {
  final int farmerId;
  const LoadFarmerDetailEvent(this.farmerId);
}

// Farm Events
class LoadAllFarmsEvent extends FarmEvent {
  const LoadAllFarmsEvent();
}

class LoadFarmsEvent extends FarmEvent {
  final int farmerId;
  const LoadFarmsEvent(this.farmerId);
}

class LoadFarmDetailEvent extends FarmEvent {
  final int farmId;
  const LoadFarmDetailEvent(this.farmId);
}

class AddFarmEvent extends FarmEvent {
  final int farmerId;
  final String? farmName;
  final String? location;
  final double areaHectares;
  final String? cropType;
  final String? certifications;

  const AddFarmEvent({
    required this.farmerId,
    this.farmName,
    this.location,
    required this.areaHectares,
    this.cropType,
    this.certifications,
  });
}

class UpdateFarmEvent extends FarmEvent {
  final int farmId;
  final int farmerId;
  final String? farmName;
  final String? location;
  final double areaHectares;
  final String? cropType;
  final String? certifications;

  const UpdateFarmEvent({
    required this.farmId,
    required this.farmerId,
    this.farmName,
    this.location,
    required this.areaHectares,
    this.cropType,
    this.certifications,
  });
}

class DeleteFarmEvent extends FarmEvent {
  final int farmId;
  const DeleteFarmEvent(this.farmId);
}

// Image Events
class LoadFarmImagesEvent extends FarmEvent {
  final int farmId;
  const LoadFarmImagesEvent(this.farmId);
}

class AddFarmImageEvent extends FarmEvent {
  final int farmId;
  final String imageUrl;

  const AddFarmImageEvent({
    required this.farmId,
    required this.imageUrl,
  });
}

class SetPrimaryImageEvent extends FarmEvent {
  final int farmId;
  final int imageId;

  const SetPrimaryImageEvent({
    required this.farmId,
    required this.imageId,
  });
}

class DeleteFarmImageEvent extends FarmEvent {
  final int imageId;
  const DeleteFarmImageEvent(this.imageId);
}
