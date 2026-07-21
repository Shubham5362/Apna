import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/providers.dart';
import 'package:frontend/views/widgets/rating_widgets.dart';
import 'package:frontend/views/write_review_view.dart';

class MockRatingApiClient extends ApiClient {
  MockRatingApiClient() : super(baseUrl: 'http://localhost:8000');

  @override
  Future<Map<String, dynamic>> getProductById(int id) async {
    return {
      'id': id,
      'name': 'Mock Product',
      'price': 10.0,
      'stock': 100,
      'shop_id': 1,
      'is_active': true,
      'created_at': '2026-07-21T12:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> getShopById(int id) async {
    return {
      'id': id,
      'name': 'Mock Shop',
      'owner_id': 1,
      'is_active': true,
      'created_at': '2026-07-21T12:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> getRatingSummary({
    int? productId,
    int? shopId,
  }) async {
    return {
      'average_rating': 4.5,
      'total_ratings': 10,
      'star_counts': {'5': 6, '4': 3, '3': 1, '2': 0, '1': 0},
    };
  }

  @override
  Future<List<dynamic>> getReviews({
    int? productId,
    int? shopId,
    int? skip,
    int? limit,
  }) async {
    return [
      {
        'id': 1,
        'user_id': 101,
        'user_name': 'Review Tester One',
        'product_id': productId,
        'shop_id': shopId,
        'rating_value': 5,
        'comment': 'Really great quality!',
        'created_at': '2026-07-21T12:00:00Z',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> createReview({
    int? productId,
    int? shopId,
    required int ratingValue,
    required String comment,
  }) async {
    return {
      'id': 2,
      'user_id': 1,
      'user_name': 'Me',
      'product_id': productId,
      'shop_id': shopId,
      'rating_value': ratingValue,
      'comment': comment,
      'created_at': '2026-07-21T12:00:00Z',
    };
  }
}

void main() {
  testWidgets('StarRatingWidget visual state and interaction test', (
    WidgetTester tester,
  ) async {
    int? ratingChangedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarRatingWidget(
            rating: 3.5,
            onRatingChanged: (val) {
              ratingChangedValue = val;
            },
          ),
        ),
      ),
    );

    // Verify stars exist
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half), findsNWidgets(1));
    expect(find.byIcon(Icons.star_border), findsNWidgets(1));

    // Tap on the 5th star
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    expect(ratingChangedValue, 5);
  });

  testWidgets('RatingSummaryWidget visual layout test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RatingSummaryWidget(
            averageRating: 4.2,
            totalRatings: 10,
            starCounts: {5: 5, 4: 3, 3: 2, 2: 0, 1: 0},
          ),
        ),
      ),
    );

    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('10 ratings'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
  });

  testWidgets('WriteReviewView inputs and form submission test', (
    WidgetTester tester,
  ) async {
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WriteReviewView(productId: 1),
        ),
        GoRoute(
          path: '/products/1',
          builder: (context, state) => const Scaffold(body: Text('Product Details Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockRatingApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_token'),
        ],
        child: MaterialApp.router(routerConfig: testRouter),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Write a Review'), findsOneWidget);
    expect(find.text('How would you rate this item?'), findsOneWidget);
    expect(find.byType(StarRatingWidget), findsOneWidget);

    // Enter feedback comment
    await tester.enterText(
      find.byType(TextFormField),
      'The product is absolutely amazing!',
    );
    await tester.pump();

    // Verify submit button is present
    expect(find.text('Submit Review'), findsOneWidget);
    await tester.tap(find.text('Submit Review'));
    await tester.pumpAndSettle();
  });
}
