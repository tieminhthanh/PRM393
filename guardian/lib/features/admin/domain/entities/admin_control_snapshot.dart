class AdminControlSnapshot {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> machines;
  final List<Map<String, dynamic>> farms;
  final List<Map<String, dynamic>> orders;

  const AdminControlSnapshot({
    required this.users,
    required this.machines,
    required this.farms,
    required this.orders,
  });
}
