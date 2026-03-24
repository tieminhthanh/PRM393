// Farm States
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/domain/entities/farm_image.dart';

abstract class FarmState {
  const FarmState();
}

// Initial State
class FarmInitialState extends FarmState {
  const FarmInitialState();
}

// Loading State
class FarmLoadingState extends FarmState {
  const FarmLoadingState();
}

// Farmer States
class FarmersLoadedState extends FarmState {
  final List<Farmer> farmers;
  const FarmersLoadedState(this.farmers);
}

class FarmerSavedState extends FarmState {
  final int farmerId;
  const FarmerSavedState(this.farmerId);
}

class FarmerDeletedState extends FarmState {
  const FarmerDeletedState();
}

class FarmerDetailLoadedState extends FarmState {
  final Farmer farmer;
  const FarmerDetailLoadedState(this.farmer);
}

// Farm States
class AllFarmsLoadedState extends FarmState {
  final List<Farm> farms;
  const AllFarmsLoadedState(this.farms);
}

class FarmsLoadedState extends FarmState {
  final List<Farm> farms;
  const FarmsLoadedState(this.farms);
}

class FarmDetailLoadedState extends FarmState {
  final Farm farm;
  final List<FarmImage> images;
  const FarmDetailLoadedState(this.farm, this.images);
}

class FarmAddedState extends FarmState {
  final int farmId;
  const FarmAddedState(this.farmId);
}

class FarmUpdatedState extends FarmState {
  const FarmUpdatedState();
}

class FarmDeletedState extends FarmState {
  const FarmDeletedState();
}

// Image States
class FarmImagesLoadedState extends FarmState {
  final List<FarmImage> images;
  const FarmImagesLoadedState(this.images);
}

class FarmImageAddedState extends FarmState {
  final int imageId;
  const FarmImageAddedState(this.imageId);
}

class FarmImageDeletedState extends FarmState {
  const FarmImageDeletedState();
}

// Error State
class FarmErrorState extends FarmState {
  final String message;
  const FarmErrorState(this.message);
}
