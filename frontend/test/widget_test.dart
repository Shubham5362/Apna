import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/providers.dart';

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
}

void main() {
  testWidgets('Apna Mandla Health Monitor UI test', (
    WidgetTester tester,
  ) async {
    // Build our app under ProviderScope with mocked provider overrides.
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

    // Verify that the Refresh button is rendered.
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Refresh Status'), findsOneWidget);

    // Let the pending async microtasks complete
    await tester.pumpAndSettle();
  });
}
