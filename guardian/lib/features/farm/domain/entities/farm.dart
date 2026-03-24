// Farm Entity
class Farm {
  final int farmId;
  final int farmerId;
  final String? farmerName;
  final String? farmName;
  final String? location;
  final double areaHectares;
  final String? cropType;
  final String? certifications;
  final List<String>? imageUrls;

  const Farm({
    required this.farmId,
    required this.farmerId,
    this.farmerName,
    this.farmName,
    this.location,
    required this.areaHectares,
    this.cropType,
    this.certifications,
    this.imageUrls,
  });

  Farm copyWith({
    int? farmId,
    int? farmerId,
    String? farmerName,
    String? farmName,
    String? location,
    double? areaHectares,
    String? cropType,
    String? certifications,
    List<String>? imageUrls,
  }) {
    return Farm(
      farmId: farmId ?? this.farmId,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      areaHectares: areaHectares ?? this.areaHectares,
      cropType: cropType ?? this.cropType,
      certifications: certifications ?? this.certifications,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  String toString() =>
      'Farm(farmId: $farmId, farmerId: $farmerId, farmerName: $farmerName, farmName: $farmName, location: $location, areaHectares: $areaHectares)';
}
