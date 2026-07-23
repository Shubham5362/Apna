import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets/reusable_widgets.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();

    // Prefill default address from loaded user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(userProfileProvider);
      if (profileState.profile != null) {
        final profile = profileState.profile!;
        setState(() {
          _addressController.text = profile['address'] ?? '';
          _cityController.text = profile['city'] ?? '';
          _stateController.text = profile['state'] ?? '';
          _pincodeController.text = profile['pincode'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      final fullAddress =
          '${_addressController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()} - ${_pincodeController.text.trim()}';
      final order = await ref
          .read(orderOpsProvider.notifier)
          .placeOrder(fullAddress);

      if (mounted) {
        if (order != null) {
          AppSnackbar.show(
            context,
            message:
                'ऑर्डर सफलतापूर्वक दर्ज किया गया! भुगतान पर आगे बढ़ रहे हैं...',
          );
          final id = order['id'] as int;
          context.go('/payment/$id');
        } else {
          final error = ref.read(orderOpsProvider).error;
          AppSnackbar.show(
            context,
            message: 'ऑर्डर दर्ज करने में विफल: $error',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cartState = ref.watch(cartProvider);
    final opsState = ref.watch(orderOpsProvider);

    final cart = cartState.cart;
    final items = cart?['items'] as List<dynamic>? ?? [];
    final totalPrice = cart?['total_price'] as double? ?? 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('चेकआउट (Checkout Summary)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cart'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Delivery Details
              Text(
                'वितरण विवरण (Delivery Information)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'कृपया वह पूरा पता दर्ज करें जहां आप अपना ऑर्डर वितरित करवाना चाहते हैं।',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              AppTextField(
                labelText: 'स्थानीय पता (Street/Local Address)',
                hintText: 'मकान संख्या, गली नंबर, वार्ड नंबर',
                prefixIcon: Icons.home_work_outlined,
                controller: _addressController,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'पता दर्ज करना आवश्यक है'
                    : null,
              ),
              const SizedBox(height: AppSpacing.m),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      labelText: 'शहर (City)',
                      hintText: 'मंडला',
                      prefixIcon: Icons.location_city_outlined,
                      controller: _cityController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'शहर आवश्यक है'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: AppTextField(
                      labelText: 'राज्य (State)',
                      hintText: 'मध्य प्रदेश',
                      prefixIcon: Icons.map_outlined,
                      controller: _stateController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'राज्य आवश्यक है'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              AppTextField(
                labelText: 'पिनकोड (Pincode)',
                hintText: '481661',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                controller: _pincodeController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'पिनकोड आवश्यक है';
                  }
                  if (val.trim().length != 6) {
                    return 'वैध 6-अंकीय पिनकोड होना चाहिए';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Order items Summary
              Text(
                'ऑर्डर सारांश (Order Summary - ${items.length} उत्पाद)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.m),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index] as Map<String, dynamic>;
                        final name = item['product_name'] as String;
                        final price = item['product_price'] as double;
                        final qty = item['quantity'] as int;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$name x $qty',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '₹ ${(price * qty).toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'कुल भुगतान राशि (Total Amount):',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹ ${totalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 3. Purchase Button
              PrimaryButton(
                text: 'ऑर्डर दर्ज करें और भुगतान करें',
                isLoading: opsState.isLoading,
                onPressed: _placeOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
