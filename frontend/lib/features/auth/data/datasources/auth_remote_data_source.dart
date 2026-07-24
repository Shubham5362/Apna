import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithPassword({
    required String mobileNumber,
    required String password,
  });

  Future<bool> sendOtp({required String mobileNumber});

  Future<UserModel> verifyOtp({
    required String mobileNumber,
    required String otp,
  });

  Future<UserModel> signUp({
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

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Can be injected with http.Client or Dio in real production
  @override
  Future<UserModel> loginWithPassword({
    required String mobileNumber,
    required String password,
  }) async {
    // Simulated network delay
    await Future.delayed(const Duration(seconds: 1));

    if (mobileNumber.length == 10) {
      return UserModel(
        id: 'user_101',
        mobileNumber: mobileNumber,
        name: 'Mandla User',
        role: 'customer',
        token: 'jwt_mock_token_12345',
      );
    } else {
      throw Exception('Invalid mobile number or password.');
    }
  }

  @override
  Future<bool> sendOtp({required String mobileNumber}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return mobileNumber.length == 10;
  }

  @override
  Future<UserModel> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '123456' || otp.length == 6) {
      return UserModel(
        id: 'user_101',
        mobileNumber: mobileNumber,
        name: 'Mandla User',
        role: 'customer',
        token: 'jwt_mock_otp_token',
      );
    }
    throw Exception('Incorrect OTP. Please check and re-enter.');
  }

  @override
  Future<UserModel> signUp({
    required String mobileNumber,
    required String name,
    required String password,
    required String role,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: 'new_user_102',
      mobileNumber: mobileNumber,
      name: name,
      role: role,
      token: 'jwt_new_user_token',
    );
  }

  @override
  Future<bool> resetPassword({
    required String mobileNumber,
    required String newPassword,
    required String otp,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
