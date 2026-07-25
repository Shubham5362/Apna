import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthViewMode { login, signup, forgotPassword }

enum LoginTypeMode { password, otp }

class AuthController extends ChangeNotifier {
  final LoginWithPasswordUseCase loginWithPasswordUseCase;
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  AuthController({
    required this.loginWithPasswordUseCase,
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
  });

  // Screen State
  AuthViewMode _currentView = AuthViewMode.login;
  LoginTypeMode _loginMode = LoginTypeMode.password;

  AuthViewMode get currentView => _currentView;
  LoginTypeMode get loginMode => _loginMode;

  // Form Fields
  String _mobileNumber = '';
  String _password = '';
  String _otp = '';
  String _name = '';
  String _selectedRole = 'Customer';
  bool _showPassword = false;
  bool _isFocused = false;

  String get mobileNumber => _mobileNumber;
  String get password => _password;
  String get otp => _otp;
  String get name => _name;
  String get selectedRole => _selectedRole;
  bool get showPassword => _showPassword;
  bool get isFocused => _isFocused;

  // Status
  bool _isLoading = false;
  bool _otpSent = false;
  int _resendTimer = 0;
  Timer? _timer;
  String? _errorMessage;
  UserEntity? _currentUser;

  bool get isLoading => _isLoading;
  bool get otpSent => _otpSent;
  int get resendTimer => _resendTimer;
  String? get errorMessage => _errorMessage;
  UserEntity? get currentUser => _currentUser;

  void setView(AuthViewMode view) {
    _currentView = view;
    _errorMessage = null;
    _otpSent = false;
    _stopTimer();
    notifyListeners();
  }

  void setLoginMode(LoginTypeMode mode) {
    _loginMode = mode;
    _errorMessage = null;
    notifyListeners();
  }

  void setMobileNumber(String mobile) {
    _mobileNumber = mobile;
    _errorMessage = null;
    notifyListeners();
  }

  void setPassword(String pass) {
    _password = pass;
    _errorMessage = null;
    notifyListeners();
  }

  void setOtp(String value) {
    _otp = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  void setFocused(bool focused) {
    _isFocused = focused;
    notifyListeners();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        _resendTimer--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _resendTimer = 0;
  }

  Future<bool> handleSendOtp() async {
    if (_mobileNumber.length != 10) {
      _errorMessage = 'Please enter a valid 10-digit mobile number';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await sendOtpUseCase.call(mobileNumber: _mobileNumber);
      if (success) {
        _otpSent = true;
        _startResendTimer();
      } else {
        _errorMessage = 'Failed to send OTP. Please try again.';
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleLogin() async {
    if (_mobileNumber.length != 10) {
      _errorMessage = 'Please enter a valid 10-digit mobile number';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_loginMode == LoginTypeMode.password) {
        if (_password.isEmpty) {
          _errorMessage = 'Please enter your password';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        _currentUser = await loginWithPasswordUseCase.call(
          mobileNumber: _mobileNumber,
          password: _password,
        );
      } else {
        if (_otp.length < 6) {
          _errorMessage = 'Please enter the 6-digit OTP';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        _currentUser = await verifyOtpUseCase.call(
          mobileNumber: _mobileNumber,
          otp: _otp,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
