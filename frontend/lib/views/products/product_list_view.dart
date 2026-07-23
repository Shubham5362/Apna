import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/reusable_widgets.dart';

class ProductListView extends ConsumerWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final productsAsync = ref.watch(productsListProvider);
    final shopsAsync = ref.watch(shopsListProvider);
    final selectedCategory = ref.watch(productSelectedCategoryProvider);
    final selectedShopId = ref.watch(productSelectedShopIdProvider);
    final sortBy = ref.watch(productSortByProvider);

    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    final categories = [
      'All',
      'Vegetables',
      'Fruits',
      'Dairy',
      'Grocery',
      'Bakery',
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('मांडला उत्पाद (Marketplace Products)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(productsListProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    hintText: 'उत्पाद खोजें (Search products...)',
                    onChanged: (value) {
                      ref.read(productSearchQueryProvider.notifier).state =
                          value;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.m),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: sortBy,
                    underline: const SizedBox(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(productSortByProvider.notifier).state = value;
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                      DropdownMenuItem(
                        value: 'price low-high',
                        child: Text('Price: Low-High'),
                      ),
                      DropdownMenuItem(
                        value: 'price high-low',
                        child: Text('Price: High-Low'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters Row: Categories & Shop
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                // Category Selector
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'श्रेणी (Category)',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(productSelectedCategoryProvider.notifier).state =
                          value == 'All' ? null : value;
                    },
                    items: categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),

                // Shop Selector
                Expanded(
                  child: shopsAsync.when(
                    data: (shops) {
                      return DropdownButtonFormField<int?>(
                        value: selectedShopId,
                        decoration: const InputDecoration(
                          labelText: 'दुकान (Shop)',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                        ),
                        onChanged: (value) {
                          ref
                                  .read(productSelectedShopIdProvider.notifier)
                                  .state =
                              value;
                        },
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Shops'),
                          ),
                          ...shops.map((shop) {
                            return DropdownMenuItem<int?>(
                              value: shop['id'] as int,
                              child: Text(shop['name'] as String),
                            );
                          }),
                        ],
                      );
                    },
                    error: (err, stack) => const Text('Error loading shops'),
                    loading: () => const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Product List Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      title: 'कोई उत्पाद नहीं मिला!',
                      description: 'खोज शब्द बदलें या अपना उत्पाद जोड़ें।',
                      icon: Icons.shopping_bag_outlined,
                      actionText: 'नया उत्पाद जोड़ें',
                      onActionPressed: () => context.go('/products/create'),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: AppSpacing.m,
                    mainAxisSpacing: AppSpacing.m,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index] as Map<String, dynamic>;
                    final id = product['id'] as int;
                    final name = product['name'] as String;
                    final price = product['price'] as double;
                    final cat = product['category'] ?? 'General';
                    final imageUrl = product['image_url'];
                    final fullImageUrl = imageUrl != null
                        ? '$baseUrl$imageUrl'
                        : null;

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.m),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/products/$id'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.2),
                                child: fullImageUrl != null
                                    ? Image.network(
                                        fullImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.shopping_bag_outlined,
                                                  size: 44,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                      )
                                    : Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 44,
                                        color: theme.colorScheme.primary,
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.s),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stock: ${product['stock'] ?? 0} units',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppBorderRadius.s,
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              error: (err, stack) => ErrorStateWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(productsListProvider),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/create'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('उत्पाद जोड़ें (Add Product)'),
      ),
    );
  }
}
