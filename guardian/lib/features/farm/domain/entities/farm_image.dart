// Farm Image Entity
class FarmImage {
  final int imageId;
  final int referenceId;
  final String referenceType;
  final String imageUrl;
  final int isPrimary;
  final int displayOrder;
  final String? uploadedAt;

  const FarmImage({
    required this.imageId,
    required this.referenceId,
    required this.referenceType,
    required this.imageUrl,
    this.isPrimary = 0,
    this.displayOrder = 0,
    this.uploadedAt,
  });

  FarmImage copyWith({
    int? imageId,
    int? referenceId,
    String? referenceType,
    String? imageUrl,
    int? isPrimary,
    int? displayOrder,
    String? uploadedAt,
  }) {
    return FarmImage(
      imageId: imageId ?? this.imageId,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      imageUrl: imageUrl ?? this.imageUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      displayOrder: displayOrder ?? this.displayOrder,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  String toString() =>
      'FarmImage(imageId: $imageId, referenceId: $referenceId, imageUrl: $imageUrl)';
}
