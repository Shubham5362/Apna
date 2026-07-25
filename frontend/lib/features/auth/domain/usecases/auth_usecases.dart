import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithPasswordUseCase {
  final AuthRepository repository;

  LoginWithPasswordUseCase(this.repository);

  Future<UserEntity> call({
    required String mobileNumber,
    required String password,
  }) async {
    return await repository.loginWithPassword(
      mobileNumber: mobileNumber,
      password: password,
    );
  }
}

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<bool> call({required String mobileNumber}) async {
    return await repository.sendOtp(mobileNumber: mobileNumber);
  }
}

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<UserEntity> call({
    required String mobileNumber,
    required String otp,
  }) async {
    return await repository.verifyOtp(mobileNumber: mobileNumber, otp: otp);
  }
}
