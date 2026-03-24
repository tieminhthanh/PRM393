class EnterpriseProfile {
  final int? userId;
  final String companyName;
  final String taxCode;
  final String? contactName;
  final String? contactPhone;
  final String? addressSummary;
  final String? description;
  final String? logoUrl;
  final String? email;
  final String? displayName;
  final bool isActive;
  final String? createdAt;
  final int productCount;

  const EnterpriseProfile({
    this.userId,
    required this.companyName,
    required this.taxCode,
    this.contactName,
    this.contactPhone,
    this.addressSummary,
    this.description,
    this.logoUrl,
    this.email,
    this.displayName,
    required this.isActive,
    this.createdAt,
    this.productCount = 0,
  });
}
