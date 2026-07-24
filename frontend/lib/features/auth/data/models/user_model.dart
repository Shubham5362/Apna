import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.mobileNumber,
    super.name,
    required super.role,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      mobileNumber: json['mobile'] ?? json['phone'] ?? '',
      name: json['name'],
      role: json['role'] ?? 'customer',
      token: json['token'] ?? json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile': mobileNumber,
      'name': name,
      'role': role,
      'token': token,
    };
  }
}
