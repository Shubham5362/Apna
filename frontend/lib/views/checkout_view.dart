import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  String _selectedPaymentMethod = 'Cash on Delivery';

  final List<String> _savedAddresses = [
    'Home: 123 Main St, Mumbai, Maharashtra - 400001',
    'Work: Office Room 404, Tech Park, Mumbai, Maharashtra - 400013',
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();

    // Populate user profile address if already loaded as a convenient default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(userProfileProvider);
      if (profileState.profile != null) {
        final profile = profileState.profile!;
        final addr = profile['address'] ?? '';
        final city = profile['city'] ?? '';
        final stateName = profile['state'] ?? '';
        final pincode = profile['pincode'] ?? '';
        if (addr.isNotEmpty) {
          _addressController.text = '$addr, $city, $stateName - $pincode';
        } else {
          _addressController.text = _savedAddresses.first;
        }
      } else {
        _addressController.text = _savedAddresses.first;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      final address = _addressController.text.trim();
      final order = await ref
          .read(orderOpsProvider.notifier)
          .placeOrder(address);

      if (mounted) {
        if (order != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Order placed successfully! (ऑर्डर सफलतापूर्वक प्राप्त हुआ!)',
              ),
              backgroundColor: Colors.green,
            ),
          );
          final id = order['id'] as int;

          // If payment method is Digital, navigate to payment screen. Otherwise COD is complete!
          if (_selectedPaymentMethod == 'Cash on Delivery') {
            // Direct to SuccessScreen!
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Order Placed')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                          const SizedBox(height: 24),
                          const Text(
                            'Order Successful!',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your order #$id has been placed successfully using Cash on Delivery.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () => context.go('/dashboard'),
                            child: const Text('Back to Home'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            context.go('/payment/$id');
          }
        } else {
          final error = ref.read(orderOpsProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to place order: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final opsState = ref.watch(orderOpsProvider);

    final cart = cartState.cart;
    final items = cart?['items'] as List<dynamic>? ?? [];
    final totalPrice = cart?['total_price'] as double? ?? 0.0;

    // Delivery charges calculations: free delivery above $30, otherwise flat $5.
    const double deliveryThreshold = 30.0;
    final double deliveryCharges = totalPrice >= deliveryThreshold ? 0.0 : 5.0;
    final double finalAmount = totalPrice + deliveryCharges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cart'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ADDRESS SELECTION & INPUT
                  Text(
                    'Delivery Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select or enter the delivery address.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Saved addresses quick chips
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.home, size: 16),
                        label: const Text('Home Address'),
                        onPressed: () {
                          setState(() {
                            _addressController.text = _savedAddresses[0];
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.work, size: 16),
                        label: const Text('Work Address'),
                        onPressed: () {
                          setState(() {
                            _addressController.text = _savedAddresses[1];
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address',
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter street, building, city, state, pincode',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Delivery address is required';
                      }
                      return null;
                    },
                  ),
                  const Divider(height: 40),

                  // 2. PAYMENT METHOD SELECTION
                  Text(
                    'Select Payment Method',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Cash on Delivery (COD)'),
                          subtitle: const Text('Pay when you receive your order'),
                          secondary: const Icon(Icons.money, color: Colors.green),
                          value: 'Cash on Delivery',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPaymentMethod = val;
                              });
                            }
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('UPI / Digital Wallet / Cards'),
                          subtitle: const Text('Fast and secure digital payment'),
                          secondary: const Icon(Icons.credit_card, color: Colors.blue),
                          value: 'Digital Payment',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPaymentMethod = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 40),

                  // 3. ITEMIZED ORDER SUMMARY
                  Text(
                    'Order Summary (${items.length} items)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index] as Map<String, dynamic>;
                        final name = item['product_name'] as String;
                        final price = item['product_price'] as double;
                        final qty = item['quantity'] as int;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$name x $qty',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              Text(
                                '\$${(price * qty).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. DETAILED CHARGES AND Dynamic Delivery Calculations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items Total:', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      Text('\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Charges:', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      Text(
                        deliveryCharges == 0.0 ? 'FREE' : '\$${deliveryCharges.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: deliveryCharges == 0.0 ? Colors.green : Colors.black,
                          fontWeight: deliveryCharges == 0.0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (deliveryCharges > 0.0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tip: Add \$${(deliveryThreshold - totalPrice).toStringAsFixed(2)} more to get FREE Delivery!',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${finalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: opsState.isLoading ? null : _placeOrder,
                      icon: opsState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.payment),
                      label: Text(
                        opsState.isLoading ? 'Placing Order...' : 'Place Order',
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
          ),
        ),
      ),
    );
  }
}
