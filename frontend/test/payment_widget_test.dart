import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/providers.dart';
import 'package:frontend/views/payment_view.dart';
import 'package:frontend/views/payment_success_view.dart';
import 'package:frontend/views/payment_failed_view.dart';
import 'package:frontend/views/payment_history_view.dart';

class MockPaymentApiClient extends ApiClient {
  MockPaymentApiClient() : super(baseUrl: 'http://localhost:8000');

  @override
  Future<Map<String, dynamic>> getOrderById(int orderId) async {
    return {
      'id': orderId,
      'user_id': 1,
      'status': 'Pending',
      'total_price': 15.50,
      'delivery_address': '123 Main St, Mumbai',
      'created_at': '2026-07-21T12:00:00Z',
      'updated_at': null,
      'items': [
        {
          'id': 1,
          'product_id': 1,
          'product_name': 'Apple Organic',
          'quantity': 2,
          'price': 7.75,
        },
      ],
      'payment_status': 'Pending',
    };
  }

  @override
  Future<Map<String, dynamic>> createPayment(
    int orderId,
    String paymentMethod,
  ) async {
    return {
      'id': 101,
      'order_id': orderId,
      'razorpay_order_id': 'order_mock_xyz123',
      'payment_method': paymentMethod,
      'status': 'Pending',
      'amount': 15.50,
      'created_at': '2026-07-21T12:01:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(
    String razorpayOrderId,
    String razorpayPaymentId,
    String razorpaySignature,
  ) async {
    return {
      'id': 101,
      'order_id': 1,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'payment_method': 'UPI',
      'status': 'Success',
      'amount': 15.50,
      'created_at': '2026-07-21T12:01:00Z',
    };
  }

  @override
  Future<List<dynamic>> getPaymentHistory() async {
    return [
      {
        'id': 101,
        'order_id': 1,
        'razorpay_order_id': 'order_mock_xyz123',
        'razorpay_payment_id': 'pay_mock_999',
        'payment_method': 'UPI',
        'status': 'Success',
        'amount': 15.50,
        'created_at': '2026-07-21T12:01:00Z',
      },
      {
        'id': 102,
        'order_id': 2,
        'razorpay_order_id': 'order_mock_abc456',
        'razorpay_payment_id': 'pay_mock_888',
        'payment_method': 'Razorpay',
        'status': 'Failed',
        'amount': 25.00,
        'created_at': '2026-07-21T13:05:00Z',
      },
    ];
  }
}

void main() {
  testWidgets('PaymentView UI test (UPI selection & Pay button)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockPaymentApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_token'),
        ],
        child: const MaterialApp(home: PaymentView(orderId: 1)),
      ),
    );

    // Initial load
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify elements are present
    expect(find.text('Secure Payment'), findsOneWidget);
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('\$15.50'), findsOneWidget);
    expect(find.text('Select Payment Method'), findsOneWidget);
    expect(find.text('UPI Payment (Instant)'), findsOneWidget);
    expect(find.text('Razorpay Checkout'), findsOneWidget);

    // Input UPI ID should be prepopulated with test@upi
    expect(
      find.widgetWithText(TextFormField, 'Enter UPI ID (VPA)'),
      findsOneWidget,
    );

    // Verify pay button is present
    expect(find.text('Pay with UPI'), findsOneWidget);
  });

  testWidgets('PaymentSuccessView UI test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PaymentSuccessView(orderId: 45, paymentId: 'pay_tx_1234567890'),
      ),
    );

    expect(find.text('Payment Successful'), findsOneWidget);
    expect(find.text('Thank You!'), findsOneWidget);
    expect(find.text('#45'), findsOneWidget);
    expect(find.text('pay_tx_1234567890'), findsOneWidget);
    expect(find.text('View Order Details'), findsOneWidget);
    expect(find.text('Continue Shopping'), findsOneWidget);
  });

  testWidgets('PaymentFailedView UI test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentFailedView(orderId: 88)),
    );

    expect(find.text('Payment Failed'), findsNWidgets(2));
    expect(find.text('#88'), findsOneWidget);
    expect(find.text('Retry Payment'), findsOneWidget);
    expect(find.text('Back to Order Details'), findsOneWidget);
  });

  testWidgets('PaymentHistoryView UI test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockPaymentApiClient()),
          authTokenProvider.overrideWith((ref) => 'mock_token'),
        ],
        child: const MaterialApp(home: PaymentHistoryView()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Payment History'), findsOneWidget);
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('Order #2'), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('\$15.50'), findsOneWidget);
    expect(find.text('\$25.00'), findsOneWidget);
  });
}
