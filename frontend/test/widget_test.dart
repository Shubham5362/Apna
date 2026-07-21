import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/providers.dart';
import 'package:frontend/views/user_profile_view.dart';

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
    expect(find.text('Apna Mandla Health Monitor'), findsOneWidget);
    expect(find.text('System Status Check'), findsOneWidget);

    // Verify that the buttons are rendered.
    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.text('Refresh Status'), findsOneWidget);
    expect(find.text('Go to User Profile'), findsOneWidget);

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
    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Profile Completion'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);

    // Verify form fields populated with MockApiClient values
    expect(find.text('Profile Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);

    // Verify save button exists
    expect(find.text('Save Profile'), findsOneWidget);
  });
}
