import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> loginWithPassword({
    required String mobileNumber,
    required String password,
  }) async {
    return await remoteDataSource.loginWithPassword(
      mobileNumber: mobileNumber,
      password: password,
    );
  }

  @override
  Future<bool> sendOtp({required String mobileNumber}) async {
    return await remoteDataSource.sendOtp(mobileNumber: mobileNumber);
  }

  @override
  Future<UserEntity> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    return await remoteDataSource.verifyOtp(
      mobileNumber: mobileNumber,
      otp: otp,
    );
  }

  @override
  Future<UserEntity> signUp({
    required String mobileNumber,
    required String name,
    required String password,
    required String role,
  }) async {
    return await remoteDataSource.signUp(
      mobileNumber: mobileNumber,
      name: name,
      password: password,
      role: role,
    );
  }

  @override
  Future<bool> resetPassword({
    required String mobileNumber,
    required String newPassword,
    required String otp,
  }) async {
    return await remoteDataSource.resetPassword(
      mobileNumber: mobileNumber,
      newPassword: newPassword,
      otp: otp,
    );
  }
}
