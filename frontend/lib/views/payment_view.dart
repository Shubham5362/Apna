import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';

class PaymentView extends ConsumerStatefulWidget {
  final int orderId;

  const PaymentView({super.key, required this.orderId});

  @override
  ConsumerState<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends ConsumerState<PaymentView> {
  String _selectedMethod = 'UPI'; // 'UPI' or 'Razorpay'
  final _upiController = TextEditingController(text: 'test@upi');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(double amount) async {
    if (_selectedMethod == 'UPI') {
      if (!_formKey.currentState!.validate()) return;
    }

    final paymentNotifier = ref.read(paymentOpsProvider.notifier);
    final paymentData = await paymentNotifier.createPayment(
      widget.orderId,
      _selectedMethod,
    );

    if (paymentData == null) {
      if (mounted) {
        final error = ref.read(paymentOpsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate payment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final razorpayOrderId = paymentData['razorpay_order_id'] as String;

    if (_selectedMethod == 'Razorpay') {
      // Show Razorpay mock modal
      if (mounted) {
        _showRazorpayMockCheckout(razorpayOrderId, amount);
      }
    } else {
      // UPI flow: Simulate instant UPI approval/success
      final verifyRes = await paymentNotifier.verifyPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: 'pay_upi_${DateTime.now().millisecondsSinceEpoch}',
        razorpaySignature: 'mock_sig',
        orderId: widget.orderId,
      );

      if (mounted) {
        if (verifyRes != null) {
          context.go(
            '/payment/success?orderId=${widget.orderId}&paymentId=${verifyRes['razorpay_payment_id'] ?? 'N/A'}',
          );
        } else {
          context.go('/payment/failed?orderId=${widget.orderId}');
        }
      }
    }
  }

  void _showRazorpayMockCheckout(String razorpayOrderId, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Image.network(
                'https://razorpay.com/favicon.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.payment),
              ),
              const SizedBox(width: 8),
              const Text('Razorpay Secure'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: $razorpayOrderId'),
              const SizedBox(height: 8),
              Text(
                'Amount: \$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              const Text('This is a simulated Razorpay Checkout overlay.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/payment/failed?orderId=${widget.orderId}');
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final verifyRes = await ref
                    .read(paymentOpsProvider.notifier)
                    .verifyPayment(
                      razorpayOrderId: razorpayOrderId,
                      razorpayPaymentId:
                          'pay_rzp_${DateTime.now().millisecondsSinceEpoch}',
                      razorpaySignature: 'mock_sig',
                      orderId: widget.orderId,
                    );
                if (mounted) {
                  if (verifyRes != null) {
                    context.go(
                      '/payment/success?orderId=${widget.orderId}&paymentId=${verifyRes['razorpay_payment_id'] ?? 'N/A'}',
                    );
                  } else {
                    context.go('/payment/failed?orderId=${widget.orderId}');
                  }
                }
              },
              child: const Text(
                'Simulate Success',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailsProvider(widget.orderId));
    final opsState = ref.watch(paymentOpsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders/${widget.orderId}'),
        ),
      ),
      body: orderAsync.when(
        data: (order) {
          final amount = order['total_price'] as double;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Amount Card
                  Card(
                    color: Colors.blue.shade50,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${widget.orderId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Total Amount Due',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Method list
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Row(
                      children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 12),
                        Text('UPI Payment (Instant)'),
                      ],
                    ),
                    value: 'UPI',
                    // ignore: deprecated_member_use
                    groupValue: _selectedMethod,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() => _selectedMethod = val!);
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Row(
                      children: [
                        Icon(Icons.credit_card),
                        SizedBox(width: 12),
                        Text('Razorpay Checkout'),
                      ],
                    ),
                    value: 'Razorpay',
                    // ignore: deprecated_member_use
                    groupValue: _selectedMethod,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() => _selectedMethod = val!);
                    },
                  ),

                  const SizedBox(height: 16),

                  if (_selectedMethod == 'UPI') ...[
                    TextFormField(
                      controller: _upiController,
                      decoration: const InputDecoration(
                        labelText: 'Enter UPI ID (VPA)',
                        hintText: 'e.g. user@upi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'UPI ID is required';
                        }
                        final upiRegex = RegExp(
                          r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$',
                        );
                        if (!upiRegex.hasMatch(value.trim())) {
                          return 'Enter a valid UPI ID (e.g. name@bank)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (opsState.error != null) ...[
                    Text(
                      opsState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: opsState.isLoading
                          ? null
                          : () => _processPayment(amount),
                      child: opsState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _selectedMethod == 'UPI'
                                  ? 'Pay with UPI'
                                  : 'Pay via Razorpay',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
