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
import '../views/cart_view.dart';
import '../views/checkout_view.dart';
import '../views/orders/order_list_view.dart';
import '../views/orders/order_details_view.dart';
import '../views/payment_view.dart';
import '../views/payment_success_view.dart';
import '../views/payment_failed_view.dart';
import '../views/payment_history_view.dart';
import '../views/write_review_view.dart';
import '../views/login_view.dart';
import '../views/customer_dashboard_view.dart';

final GoRouter routerConfig = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HealthDashboardView(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const CustomerDashboardView(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginView()),
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
    GoRoute(path: '/cart', builder: (context, state) => const CartView()),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutView(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderListView(),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id']!;
        final id = int.parse(idStr);
        return OrderDetailsView(orderId: id);
      },
    ),
    GoRoute(
      path: '/payment/:orderId',
      builder: (context, state) {
        final orderIdStr = state.pathParameters['orderId']!;
        final orderId = int.parse(orderIdStr);
        return PaymentView(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/payment/success',
      builder: (context, state) {
        final orderIdStr = state.uri.queryParameters['orderId'] ?? '0';
        final orderId = int.parse(orderIdStr);
        final paymentId = state.uri.queryParameters['paymentId'] ?? 'N/A';
        return PaymentSuccessView(orderId: orderId, paymentId: paymentId);
      },
    ),
    GoRoute(
      path: '/payment/failed',
      builder: (context, state) {
        final orderIdStr = state.uri.queryParameters['orderId'] ?? '0';
        final orderId = int.parse(orderIdStr);
        return PaymentFailedView(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/payments/history',
      builder: (context, state) => const PaymentHistoryView(),
    ),
    GoRoute(
      path: '/review/write',
      builder: (context, state) {
        final productIdStr = state.uri.queryParameters['productId'];
        final shopIdStr = state.uri.queryParameters['shopId'];
        final productId = productIdStr != null
            ? int.tryParse(productIdStr)
            : null;
        final shopId = shopIdStr != null ? int.tryParse(shopIdStr) : null;
        return WriteReviewView(productId: productId, shopId: shopId);
      },
    ),
    GoRoute(
      path: '/review/edit',
      builder: (context, state) {
        final reviewIdStr = state.uri.queryParameters['reviewId']!;
        final reviewId = int.parse(reviewIdStr);
        final productIdStr = state.uri.queryParameters['productId'];
        final shopIdStr = state.uri.queryParameters['shopId'];
        final productId = productIdStr != null
            ? int.tryParse(productIdStr)
            : null;
        final shopId = shopIdStr != null ? int.tryParse(shopIdStr) : null;
        final ratingValueStr = state.uri.queryParameters['ratingValue'] ?? '5';
        final ratingValue = int.parse(ratingValueStr);
        final comment = state.uri.queryParameters['comment'] ?? '';

        return WriteReviewView(
          reviewId: reviewId,
          productId: productId,
          shopId: shopId,
          initialRating: ratingValue,
          initialComment: comment,
        );
      },
    ),
  ],
);
