import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../widgets/rating_widgets.dart';

class ProductDetailsView extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailsView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<ProductDetailsView> {
  int _quantity = 1;
  bool _isAddingToCart = false;

  Future<void> _handleAddToCart({bool navigateToCheckout = false}) async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      final success = await ref.read(cartProvider.notifier).addToCart(widget.productId, _quantity);
      if (mounted) {
        if (success) {
          if (navigateToCheckout) {
            context.go('/checkout');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to cart successfully! (कार्ट में जोड़ा गया!)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final error = ref.read(cartProvider).error ?? 'Failed to add item to cart';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;
    final profileState = ref.watch(userProfileProvider);
    final currentUserId = profileState.profile?['user_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: productAsync.when(
        data: (product) {
          final name = product['name'] as String;
          final desc = product['description'] ?? 'No description available.';
          final category = product['category'] ?? 'General';
          final price = product['price'] as double;
          final mrp = product['mrp'] as double?;
          final stock = product['stock'] as int;
          final imageUrl = product['image_url'];
          final fullImageUrl = imageUrl != null ? '$baseUrl$imageUrl' : null;
          final shopId = product['shop_id'];

          // Generate simulated multiple images
          final List<String?> imageGallery = [
            fullImageUrl,
            null, // variant 2 placeholder
            null, // variant 3 placeholder
          ];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. MULTIPLE IMAGES SLIDER / CAROUSEL
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: imageGallery.length,
                    itemBuilder: (context, index) {
                      final img = imageGallery[index];
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                        ),
                        child: img != null
                            ? Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.shopping_bag, size: 80, color: Colors.orange.shade300),
                              )
                            : Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.orange.shade300),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name & Price Row
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
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      const SizedBox(height: 12),

                      // Tags & Status Row
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
                            label: Text(stock > 0 ? 'IN STOCK' : 'OUT OF STOCK'),
                            backgroundColor: stock > 0 ? Colors.green.shade100 : Colors.red.shade100,
                            labelStyle: TextStyle(
                              color: stock > 0 ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // 2. QUANTITY SELECTOR AND ACTION BUTTONS
                      if (stock > 0) ...[
                        const Text(
                          'Select Quantity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _quantity < stock
                                        ? () => setState(() => _quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Only $stock units left!',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons: Add to Cart and Buy Now
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isAddingToCart ? null : () => _handleAddToCart(),
                                icon: _isAddingToCart
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_shopping_cart),
                                label: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isAddingToCart ? null : () => _handleAddToCart(navigateToCheckout: true),
                                icon: const Icon(Icons.flash_on),
                                label: const Text('Buy Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'This item is currently out of stock. Please check back later.',
                          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],

                      const Divider(height: 40),

                      // 3. PRODUCT DESCRIPTION
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(desc, style: Theme.of(context).textTheme.bodyLarge),

                      const Divider(height: 40),

                      // 4. SPECIFICATIONS SECTION
                      const Text(
                        'Product Specifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildSpecRow('Origin', 'Mandla Local Organic Farms'),
                            const Divider(),
                            _buildSpecRow('Packaging', 'Eco-friendly biodegradable bag'),
                            const Divider(),
                            _buildSpecRow('Shelf Life', '3 to 5 Days'),
                            const Divider(),
                            _buildSpecRow('Type', category),
                          ],
                        ),
                      ),

                      const Divider(height: 40),

                      // 5. SELLER INFORMATION CARD
                      const Text(
                        'Seller Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (shopId != null)
                        ref.watch(shopDetailsProvider(shopId)).when(
                              data: (shop) {
                                final shopName = shop['name'] ?? 'Local Mandla Shop';
                                final shopDesc = shop['description'] ?? 'No description available.';
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.blueAccent,
                                          child: Icon(Icons.store, color: Colors.white, size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                shopName,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                shopDesc,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              )
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.verified, color: Colors.blue),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              error: (err, _) => const SizedBox(),
                              loading: () => const CircularProgressIndicator(),
                            )
                      else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.store, size: 40, color: Colors.grey),
                                SizedBox(width: 16),
                                Text(
                                  'Sold by Apna Mandla Direct Farm Collective',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Divider(height: 40),

                      // Ratings & Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ratings & Reviews',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go(
                              '/review/write?productId=${widget.productId}',
                            ),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Write Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rating Summary Card
                      ref.watch(productRatingSummaryProvider(widget.productId)).when(
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
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),

                      const SizedBox(height: 24),

                      // Reviews List
                      ref.watch(productReviewsProvider(widget.productId)).when(
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
                                  final reviewUserId = r['user_id'] as int?;

                                  final isMyReview = currentUserId != null && currentUserId == reviewUserId;

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
                                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                                                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                                  onPressed: () => context.go(
                                                    '/review/edit?reviewId=$reviewId&productId=${widget.productId}&ratingValue=$ratingVal&comment=${Uri.encodeComponent(comment)}',
                                                  ),
                                                  icon: const Icon(Icons.edit, size: 16),
                                                  label: const Text('Edit'),
                                                ),
                                                TextButton.icon(
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  onPressed: () async {
                                                    await ref
                                                        .read(reviewOpsProvider.notifier)
                                                        .deleteReview(reviewId, productId: widget.productId);
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
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
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

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
