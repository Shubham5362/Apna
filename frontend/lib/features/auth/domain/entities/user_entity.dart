class UserEntity {
  final String id;
  final String mobileNumber;
  final String? name;
  final String role;
  final String? token;

  UserEntity({
    required this.id,
    required this.mobileNumber,
    this.name,
    required this.role,
    this.token,
  });
}
