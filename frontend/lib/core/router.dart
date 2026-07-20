import 'package:go_router/go_router.dart';
import '../views/health_dashboard_view.dart';

final GoRouter routerConfig = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HealthDashboardView(),
    ),
  ],
);
