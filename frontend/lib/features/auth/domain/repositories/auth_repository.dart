import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithPassword({
    required String mobileNumber,
    required String password,
  });

  Future<bool> sendOtp({required String mobileNumber});

  Future<UserEntity> verifyOtp({
    required String mobileNumber,
    required String otp,
  });

  Future<UserEntity> signUp({
    required String mobileNumber,
    required String name,
    required String password,
    required String role,
  });

  Future<bool> resetPassword({
    required String mobileNumber,
    required String newPassword,
    required String otp,
  });
}
