import 'package:go_router/go_router.dart';
import '../views/health_dashboard_view.dart';
import '../views/user_profile_view.dart';
import '../views/shops/shop_list_view.dart';
import '../views/shops/shop_details_view.dart';
import '../views/shops/create_shop_view.dart';
import '../views/shops/edit_shop_view.dart';
import '../views/products/product_list_view.dart';
import '../views/products/product_details_view.dart';
import '../views/products/create_product_view.dart';
import '../views/products/edit_product_view.dart';

final GoRouter routerConfig = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HealthDashboardView(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const UserProfileView(),
    ),
    GoRoute(path: '/shops', builder: (context, state) => const ShopListView()),
    GoRoute(
      path: '/shops/create',
      builder: (context, state) => const CreateShopView(),
    ),
    GoRoute(
      path: '/shops/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.parse(idStr);
        return ShopDetailsView(shopId: id);
      },
    ),
    GoRoute(
      path: '/shops/:id/edit',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.parse(idStr);
        return EditShopView(shopId: id);
      },
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListView(),
    ),
    GoRoute(
      path: '/products/create',
      builder: (context, state) => const CreateProductView(),
    ),
    GoRoute(
      path: '/products/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.parse(idStr);
        return ProductDetailsView(productId: id);
      },
    ),
    GoRoute(
      path: '/products/:id/edit',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.parse(idStr);
        return EditProductView(productId: id);
      },
    ),
  ],
);
