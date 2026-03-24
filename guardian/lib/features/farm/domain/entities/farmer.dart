// Farmer Entity
class Farmer {
  final int userId;
  final String fullName;
  final String? village;
  final String? contactName;
  final String? contactPhone;
  final int preferredVoice;

  const Farmer({
    required this.userId,
    required this.fullName,
    this.village,
    this.contactName,
    this.contactPhone,
    this.preferredVoice = 1,
  });

  // Tạo copy với các trường thay đổi
  Farmer copyWith({
    int? userId,
    String? fullName,
    String? village,
    String? contactName,
    String? contactPhone,
    int? preferredVoice,
  }) {
    return Farmer(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      village: village ?? this.village,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      preferredVoice: preferredVoice ?? this.preferredVoice,
    );
  }

  @override
  String toString() =>
      'Farmer(userId: $userId, fullName: $fullName, village: $village)';
}
