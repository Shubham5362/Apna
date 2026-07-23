import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/providers.dart';
import 'package:frontend/views/user_profile_view.dart';
import 'package:frontend/views/shops/shop_list_view.dart';
import 'package:frontend/views/products/product_list_view.dart';
import 'package:frontend/views/cart_view.dart';
import 'package:frontend/views/orders/order_list_view.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://localhost:8000');

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {
      'status': 'healthy',
      'database': 'healthy',
      'redis': 'healthy',
      'version': '1.0.0',
    };
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    return {
      'user_id': 1,
      'phone_number': '+919999999999',
      'full_name': 'Profile Test User',
      'email': 'test@example.com',
      'gender': 'Male',
      'date_of_birth': '1990-01-01',
      'address': '123 Main St',
      'city': 'Mumbai',
      'state': 'Maharashtra',
      'pincode': '400001',
      'country': 'India',
      'preferred_language': 'English',
      'timezone': 'Asia/Kolkata',
      'profile_photo_url': null,
      'completion_percentage': 92,
    };
  }

  @override
  Future<List<dynamic>> getShops() async {
    return [
      {
        'id': 1,
        'name': 'Gorganic Grocery',
        'description': 'Fresh organic vegetables',
        'owner_id': 1,
        'image_url': null,
        'is_active': true,
        'created_at': '2026-07-21T12:00:00Z',
        'updated_at': null,
      },
    ];
  }

  @override
  Future<List<dynamic>> getProducts({
    String? search,
    String? category,
    int? shopId,
    String? sortBy,
    int? skip,
    int? limit,
  }) async {
    return [
      {
        'id': 1,
        'name': 'Apple Organic',
        'description': 'Sweet red apples',
        'category': 'Fruits',
        'price': 3.99,
        'stock': 100,
        'image_url': null,
        'is_active': true,
        'shop_id': 1,
        'created_at': '2026-07-21T12:00:00Z',
        'updated_at': null,
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getCart() async {
    return {
      'items': [
        {
          'id': 1,
          'product_id': 1,
          'quantity': 2,
          'product_name': 'Apple Organic',
          'product_price': 3.99,
          'product_image_url': null,
        },
      ],
      'total_price': 7.98,
    };
  }

  @override
  Future<List<dynamic>> getOrders() async {
    return [
      {
        'id': 1,
        'user_id': 1,
        'status': 'Pending',
        'total_price': 7.98,
        'delivery_address': '123 Main St',
        'created_at': '2026-07-21T12:00:00Z',
        'updated_at': null,
        'items': [
          {
            'id': 1,
            'product_id': 1,
            'product_name': 'Apple Organic',
            'quantity': 2,
            'price': 3.99,
          },
        ],
      },
    ];
  }
}

void main() {
  testWidgets('Apna Mandla Health Monitor UI test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const MyApp(),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify that the title and key status components are rendered.
    expect(find.text('APNA MANDLA'), findsOneWidget);
    expect(find.text('System Status Check'), findsOneWidget);

    // Verify that the buttons are rendered.
    expect(find.text('🔐 Premium Login'), findsOneWidget);
    expect(find.text('Refresh Status'), findsOneWidget);

    // Let the pending async microtasks complete
    await tester.pumpAndSettle();
  });

  testWidgets('Apna Mandla User Profile Screen UI test', (
    WidgetTester tester,
  ) async {
    // Build user profile screen directly
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_jwt_token'),
        ],
        child: const MaterialApp(home: UserProfileView()),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify profile elements
    expect(find.textContaining('User Profile'), findsOneWidget);
    expect(find.textContaining('Profile Completion'), findsOneWidget);
    expect(find.textContaining('92%'), findsOneWidget);

    // Verify form fields populated with MockApiClient values
    expect(find.text('Profile Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);

    // Verify save button exists
    expect(find.textContaining('Save Profile'), findsOneWidget);
  });

  testWidgets('Apna Mandla Shops Screen UI test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_jwt_token'),
        ],
        child: const MaterialApp(home: ShopListView()),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify shop elements
    expect(find.textContaining('Local Shops'), findsOneWidget);
    expect(find.text('Gorganic Grocery'), findsOneWidget);
    expect(find.text('Fresh organic vegetables'), findsOneWidget);

    // Verify Add Shop button exists
    expect(find.textContaining('Add Shop'), findsOneWidget);
  });

  testWidgets('Apna Mandla Products Screen UI test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_jwt_token'),
        ],
        child: const MaterialApp(home: ProductListView()),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify product elements
    expect(find.textContaining('Marketplace Products'), findsOneWidget);
    expect(find.text('Apple Organic'), findsOneWidget);
    expect(find.textContaining('100'), findsOneWidget);

    // Verify Add Product button exists
    expect(find.textContaining('Add Product'), findsOneWidget);
  });

  testWidgets('Apna Mandla Cart Screen UI test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_jwt_token'),
        ],
        child: const MaterialApp(home: CartView()),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify cart elements
    expect(find.textContaining('Cart'), findsOneWidget);
    expect(find.text('Apple Organic'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Quantity
    expect(find.textContaining('7.98'), findsOneWidget); // Total price
    expect(find.textContaining('Checkout'), findsOneWidget);
  });

  testWidgets('Apna Mandla Order History Screen UI test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_jwt_token'),
        ],
        child: const MaterialApp(home: OrderListView()),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify order history elements
    expect(find.text('Your Order History'), findsOneWidget);
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('\$7.98'), findsOneWidget);
  });
}
