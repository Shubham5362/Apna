import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets/reusable_widgets.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cartState = ref.watch(cartProvider);
    final cart = cartState.cart;
    final items = cart?['items'] as List<dynamic>? ?? [];
    final totalPrice = cart?['total_price'] as double? ?? 0.0;
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('आपका कार्ट (Your Cart)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('कार्ट साफ करें (Clear Cart)'),
                    content: const Text(
                      'क्या आप वाकई अपने कार्ट के सभी उत्पाद हटाना चाहते हैं?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('रद्द करें (Cancel)'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('हटाएं (Clear)'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(cartProvider.notifier).clearCart();
                }
              },
            ),
        ],
      ),
      body: cartState.isLoading && cart == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
              child: EmptyStateWidget(
                title: 'आपका कार्ट खाली है!',
                description: 'कार्ट में उत्पाद जोड़ने के लिए नीचे क्लिक करें।',
                icon: Icons.shopping_cart_outlined,
                actionText: 'उत्पाद देखें (Browse Products)',
                onActionPressed: () => context.go('/products'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final id = item['id'] as int;
                      final name = item['product_name'] as String;
                      final price = item['product_price'] as double;
                      final qty = item['quantity'] as int;
                      final imageUrl = item['product_image_url'];
                      final fullImageUrl = imageUrl != null
                          ? '$baseUrl$imageUrl'
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.m,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.s,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.s,
                                  ),
                                  child: fullImageUrl != null
                                      ? Image.network(
                                          fullImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                        )
                                      : Icon(
                                          Icons.shopping_bag_outlined,
                                          color: theme.colorScheme.primary,
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '₹${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Counter Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                    ),
                                    onPressed: qty > 1
                                        ? () => ref
                                              .read(cartProvider.notifier)
                                              .updateCartItem(id, qty - 1)
                                        : null,
                                  ),
                                  Text(
                                    '$qty',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateCartItem(id, qty + 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .removeFromCart(id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Grand Total Summary
                Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.xxl),
                      topRight: Radius.circular(AppBorderRadius.xxl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'कुल मूल्य (Total Amount):',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${totalPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),
                        PrimaryButton(
                          text: 'चेकआउट करें (Proceed to Checkout)',
                          onPressed: () => context.go('/checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
