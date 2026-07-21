import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class ProductListView extends ConsumerWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsListProvider);
    final shopsAsync = ref.watch(shopsListProvider);
    final selectedCategory = ref.watch(productSelectedCategoryProvider);
    final selectedShopId = ref.watch(productSelectedShopIdProvider);
    final sortBy = ref.watch(productSortByProvider);

    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    final categories = [
      'All',
      'Fruits',
      'Vegetables',
      'Bakery',
      'Dairy',
      'Grains',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(productsListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Sort Controls
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      ref.read(productSearchQueryProvider.notifier).state =
                          value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: sortBy,
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
              ],
            ),
          ),

          // Filters row: Category and Shop
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(),
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
                const SizedBox(width: 12),
                // Shop Filter
                Expanded(
                  child: shopsAsync.when(
                    data: (shops) {
                      return DropdownButtonFormField<int?>(
                        initialValue: selectedShopId,
                        decoration: const InputDecoration(
                          labelText: 'Shop',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(),
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
          const SizedBox(height: 8),

          // Product List Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/products/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Product'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index] as Map<String, dynamic>;
                    final id = product['id'] as int;
                    final name = product['name'] as String;
                    final price = product['price'] as double;
                    final mrp = product['mrp'] as double?;
                    final brand = product['brand'] as String?;
                    final stock = product['stock'] as int;
                    final cat = product['category'] ?? 'General';
                    final imageUrl = product['image_url'];
                    final fullImageUrl = imageUrl != null
                        ? '$baseUrl$imageUrl'
                        : null;

                    return Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/products/$id'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                color: Colors.orange.shade50,
                                child: fullImageUrl != null
                                    ? Image.network(
                                        fullImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.shopping_bag,
                                                  size: 48,
                                                  color: Colors.orange,
                                                ),
                                      )
                                    : const Icon(
                                        Icons.shopping_bag,
                                        size: 48,
                                        color: Colors.orange,
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (brand != null && brand.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      brand,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '\$$price',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          if (mrp != null) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              '\$$mrp',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: $stock units',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
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
              error: (err, stack) => Center(
                child: Text(
                  'Error loading products: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
