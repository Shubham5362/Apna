import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide Provider, ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dependency Injection Setup for Premium UI Auth
  final remoteDataSource = AuthRemoteDataSourceImpl();
  final repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);

  final loginWithPasswordUseCase = LoginWithPasswordUseCase(repository);
  final sendOtpUseCase = SendOtpUseCase(repository);
  final verifyOtpUseCase = VerifyOtpUseCase(repository);

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthController(
              loginWithPasswordUseCase: loginWithPasswordUseCase,
              sendOtpUseCase: sendOtpUseCase,
              verifyOtpUseCase: verifyOtpUseCase,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Apna Mandla',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: routerConfig,
      debugShowCheckedModeBanner: false,
    );
  }
}
