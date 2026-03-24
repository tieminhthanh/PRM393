// Farm BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardian/features/farm/data/repositories/farm_repository_impl.dart';
import 'package:guardian/features/farm/domain/entities/farm.dart';
import 'package:guardian/features/farm/domain/entities/farmer.dart';
import 'package:guardian/features/farm/domain/entities/farm_image.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_event.dart';
import 'package:guardian/features/farm/presentation/bloc/farm_state.dart';

class FarmBloc extends Bloc<FarmEvent, FarmState> {
  final FarmRepository repository;

  FarmBloc({required this.repository}) : super(const FarmInitialState()) {
    on<LoadFarmersEvent>(_onLoadFarmers);
    on<SearchFarmersEvent>(_onSearchFarmers);
    on<SaveFarmerEvent>(_onSaveFarmer);
    on<DeleteFarmerEvent>(_onDeleteFarmer);
    on<LoadFarmerDetailEvent>(_onLoadFarmerDetail);
    on<LoadAllFarmsEvent>(_onLoadAllFarms);
    on<LoadFarmsEvent>(_onLoadFarms);
    on<LoadFarmDetailEvent>(_onLoadFarmDetail);
    on<AddFarmEvent>(_onAddFarm);
    on<UpdateFarmEvent>(_onUpdateFarm);
    on<DeleteFarmEvent>(_onDeleteFarm);
    on<LoadFarmImagesEvent>(_onLoadFarmImages);
    on<AddFarmImageEvent>(_onAddFarmImage);
    on<SetPrimaryImageEvent>(_onSetPrimaryImage);
    on<DeleteFarmImageEvent>(_onDeleteFarmImage);
  }

  // ===== FARMER HANDLERS =====

  Future<void> _onLoadFarmers(
    LoadFarmersEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farmers = await repository.getAllFarmers();
      emit(FarmersLoadedState(farmers));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onSearchFarmers(
    SearchFarmersEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farmers = await repository.searchFarmers(event.query);
      emit(FarmersLoadedState(farmers));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onSaveFarmer(
    SaveFarmerEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farmer = Farmer(
        userId: event.userId,
        fullName: event.fullName,
        village: event.village,
        contactName: event.contactName,
        contactPhone: event.contactPhone,
        preferredVoice: event.preferredVoice,
      );
      final farmerId = await repository.saveFarmer(farmer);
      emit(FarmerSavedState(farmerId));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteFarmer(
    DeleteFarmerEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      await repository.deleteFarmer(event.userId);
      emit(const FarmerDeletedState());
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onLoadFarmerDetail(
    LoadFarmerDetailEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farmer = await repository.getFarmerById(event.farmerId);
      if (farmer != null) {
        emit(FarmerDetailLoadedState(farmer));
      } else {
        emit(const FarmErrorState('Không tìm thấy thông tin nông dân'));
      }
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  // ===== FARM HANDLERS =====

  Future<void> _onLoadAllFarms(
    LoadAllFarmsEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farms = await repository.getAllFarms();
      emit(AllFarmsLoadedState(farms));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onLoadFarms(
    LoadFarmsEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farms = await repository.getFarmsByFarmerId(event.farmerId);
      emit(FarmsLoadedState(farms));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onLoadFarmDetail(
    LoadFarmDetailEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farm = await repository.getFarmById(event.farmId);
      final images = await repository.getImagesByFarmId(event.farmId);

      if (farm != null) {
        emit(FarmDetailLoadedState(farm, images));
      } else {
        emit(const FarmErrorState('Farm not found'));
      }
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onAddFarm(
    AddFarmEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farm = Farm(
        farmId: 0, // ID sẽ được tạo tại DB
        farmerId: event.farmerId,
        farmName: event.farmName,
        location: event.location,
        areaHectares: event.areaHectares,
        cropType: event.cropType,
        certifications: event.certifications,
      );
      final farmId = await repository.addFarm(farm);
      emit(FarmAddedState(farmId));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateFarm(
    UpdateFarmEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final farm = Farm(
        farmId: event.farmId,
        farmerId: event.farmerId,
        farmName: event.farmName,
        location: event.location,
        areaHectares: event.areaHectares,
        cropType: event.cropType,
        certifications: event.certifications,
      );
      await repository.updateFarm(farm);
      emit(const FarmUpdatedState());
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteFarm(
    DeleteFarmEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      await repository.deleteFarm(event.farmId);
      emit(const FarmDeletedState());
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  // ===== IMAGE HANDLERS =====

  Future<void> _onLoadFarmImages(
    LoadFarmImagesEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final images = await repository.getImagesByFarmId(event.farmId);
      emit(FarmImagesLoadedState(images));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onAddFarmImage(
    AddFarmImageEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      final image = FarmImage(
        imageId: 0,
        referenceId: event.farmId,
        referenceType: 'FARM',
        imageUrl: event.imageUrl,
      );
      final imageId = await repository.addImage(image);
      emit(FarmImageAddedState(imageId));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onSetPrimaryImage(
    SetPrimaryImageEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      await repository.setPrimaryImage(event.farmId, event.imageId);
      final images = await repository.getImagesByFarmId(event.farmId);
      emit(FarmImagesLoadedState(images));
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteFarmImage(
    DeleteFarmImageEvent event,
    Emitter<FarmState> emit,
  ) async {
    emit(const FarmLoadingState());
    try {
      await repository.deleteImage(event.imageId);
      emit(const FarmImageDeletedState());
    } catch (e) {
      emit(FarmErrorState(e.toString()));
    }
  }
}
