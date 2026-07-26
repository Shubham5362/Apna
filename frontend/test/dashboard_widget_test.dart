import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers.dart';
import 'package:frontend/views/customer_dashboard_view.dart';
import 'widget_test.dart'; // import MockApiClient

void main() {
  testWidgets('CustomerDashboardView UI and tab selection test', (
    WidgetTester tester,
  ) async {
    // Build CustomerDashboardView directly
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_jwt_token'),
        ],
        child: const MaterialApp(home: CustomerDashboardView()),
      ),
    );

    // Initial frame and wait for any async actions to complete
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify CustomerDashboardView renders with its bottom navigation bar items
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Shops'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify initial screen displays products list
    expect(find.text('Marketplace Products'), findsOneWidget);
    expect(find.text('Apple Organic'), findsOneWidget);

    // Tap on the Shops tab
    await tester.tap(find.text('Shops'));
    await tester.pumpAndSettle();

    // Verify it switches to Shops screen
    expect(find.text('Local Shops'), findsOneWidget);
    expect(find.text('Gorganic Grocery'), findsOneWidget);

    // Tap on Cart tab
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    // Verify it switches to Cart screen
    expect(find.text('Your Shopping Cart'), findsOneWidget);
    expect(find.text('Apple Organic'), findsOneWidget);
  });
}
