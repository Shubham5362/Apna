import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../widgets/rating_widgets.dart';

class ProductDetailsView extends ConsumerWidget {
  final int productId;

  const ProductDetailsView({super.key, required this.productId});

  Future<void> _uploadMockPhoto(BuildContext context, WidgetRef ref) async {
    final mockPngBytes = List<int>.generate(200, (i) => i);
    final success = await ref
        .read(productOpsProvider.notifier)
        .uploadPhoto(productId, mockPngBytes, 'mock_product.png');

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(productOpsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await ref
          .read(productOpsProvider.notifier)
          .deleteProduct(productId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/products');
      } else if (context.mounted) {
        final error = ref.read(productOpsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: productAsync.when(
        data: (product) {
          final name = product['name'] as String;
          final desc = product['description'] ?? 'No description available.';
          final category = product['category'] ?? 'General';
          final brand = product['brand'] as String?;
          final price = product['price'] as double;
          final mrp = product['mrp'] as double?;
          final stock = product['stock'] as int;
          final imageUrl = product['image_url'];
          final fullImageUrl = imageUrl != null ? '$baseUrl$imageUrl' : null;
          final isActive = product['is_active'] as bool;

          // For demonstration / MVP we can allow edits
          const isOwner = true;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Photo Header
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.orange.shade50,
                      child: fullImageUrl != null
                          ? Image.network(
                              fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.shopping_bag,
                                    size: 80,
                                    color: Colors.orange,
                                  ),
                            )
                          : const Icon(
                              Icons.shopping_bag,
                              size: 80,
                              color: Colors.orange,
                            ),
                    ),
                    if (isOwner)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FloatingActionButton.small(
                          onPressed: () => _uploadMockPhoto(context, ref),
                          child: const Icon(Icons.camera_alt),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$$price',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (mrp != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'MRP: \$$mrp',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (brand != null && brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Brand: $brand',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(category.toUpperCase()),
                            backgroundColor: Colors.orange.shade100,
                            labelStyle: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(isActive ? 'ACTIVE' : 'INACTIVE'),
                            backgroundColor: isActive
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: isActive
                                  ? Colors.green.shade800
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Stock: $stock units available',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(desc, style: Theme.of(context).textTheme.bodyLarge),
                      const Divider(height: 40),
                      if (isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    context.go('/products/$productId/edit'),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Product'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => _deleteProduct(context, ref),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete Product'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 40),
                      // Ratings & Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ratings & Reviews',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go('/review/write?productId=$productId'),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Write Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rating Summary Card
                      ref.watch(productRatingSummaryProvider(productId)).when(
                            data: (summary) {
                              final avg = summary['average_rating'] as double? ?? 0.0;
                              final total = summary['total_ratings'] as int? ?? 0;
                              final starCountsRaw = summary['star_counts'] as Map<String, dynamic>? ?? {};
                              final Map<int, int> starCounts = {};
                              starCountsRaw.forEach((k, v) {
                                starCounts[int.parse(k)] = v as int;
                              });

                              return RatingSummaryWidget(
                                averageRating: avg,
                                totalRatings: total,
                                starCounts: starCounts,
                              );
                            },
                            error: (err, _) => const SizedBox(),
                            loading: () => const Center(child: CircularProgressIndicator()),
                          ),

                      const SizedBox(height: 24),

                      // Reviews List
                      ref.watch(productReviewsProvider(productId)).when(
                            data: (reviews) {
                              if (reviews.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: Text(
                                      'No reviews yet. Be the first to review!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviews.length,
                                itemBuilder: (context, index) {
                                  final r = reviews[index] as Map<String, dynamic>;
                                  final reviewId = r['id'] as int;
                                  final comment = r['comment'] as String;
                                  final ratingVal = r['rating_value'] as int;
                                  final userName = r['user_name'] ?? 'Anonymous';

                                  const isMyReview = true;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              StarRatingWidget(
                                                rating: ratingVal.toDouble(),
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(comment),
                                          if (isMyReview) ...[
                                            const Divider(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.orange,
                                                  ),
                                                  onPressed: () => context.go(
                                                    '/review/edit?reviewId=$reviewId&productId=$productId&ratingValue=$ratingVal&comment=${Uri.encodeComponent(comment)}',
                                                  ),
                                                  icon: const Icon(Icons.edit, size: 16),
                                                  label: const Text('Edit'),
                                                ),
                                                TextButton.icon(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    await ref
                                                        .read(reviewOpsProvider.notifier)
                                                        .deleteReview(
                                                          reviewId,
                                                          productId: productId,
                                                        );
                                                  },
                                                  icon: const Icon(Icons.delete, size: 16),
                                                  label: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            error: (err, _) => Text('Error: $err'),
                            loading: () => const Center(child: CircularProgressIndicator()),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        error: (err, stack) => Center(
          child: Text(
            'Error loading product: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
