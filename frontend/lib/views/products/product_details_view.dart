import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/rating_widgets.dart';
import '../widgets/reusable_widgets.dart';

class ProductDetailsView extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailsView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<ProductDetailsView> {
  int _quantity = 1;
  bool _addingToCart = false;

  Future<void> _uploadMockPhoto(BuildContext context, WidgetRef ref) async {
    final mockPngBytes = List<int>.generate(200, (i) => i);
    final success = await ref
        .read(productOpsProvider.notifier)
        .uploadPhoto(widget.productId, mockPngBytes, 'mock_product.png');

    if (context.mounted) {
      if (success) {
        AppSnackbar.show(
          context,
          message: 'उत्पाद की तस्वीर सफलतापूर्वक बदली गई!',
        );
      } else {
        final error = ref.read(productOpsProvider).error;
        AppSnackbar.show(
          context,
          message: 'तस्वीर बदलने में विफलता: $error',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('उत्पाद हटाएं (Delete Product)'),
        content: const Text(
          'क्या आप वाकई इस उत्पाद को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('रद्द करें (Cancel)'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('हटाएं (Delete)'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await ref
          .read(productOpsProvider.notifier)
          .deleteProduct(widget.productId);
      if (success && context.mounted) {
        AppSnackbar.show(context, message: 'उत्पाद सफलतापूर्वक हटा दिया गया।');
        context.go('/products');
      } else if (context.mounted) {
        final error = ref.read(productOpsProvider).error;
        AppSnackbar.show(
          context,
          message: 'उत्पाद हटाने में विफलता: $error',
          isError: true,
        );
      }
    }
  }

  Future<void> _addToCart(int stock) async {
    if (_quantity > stock) {
      AppSnackbar.show(
        context,
        message: 'अपर्याप्त स्टॉक! केवल $stock उपलब्ध हैं।',
        isError: true,
      );
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    final success = await ref
        .read(cartProvider.notifier)
        .addToCart(widget.productId, _quantity);

    if (mounted) {
      setState(() {
        _addingToCart = false;
      });
      if (success) {
        AppSnackbar.show(context, message: 'उत्पाद कार्ट में जोड़ा गया!');
      } else {
        final error = ref.read(cartProvider).error;
        AppSnackbar.show(
          context,
          message: 'कार्ट में जोड़ने में विफल: $error',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productAsync = ref.watch(productDetailsProvider(widget.productId));
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;
    final profileState = ref.watch(userProfileProvider);
    final currentUserId = profileState.profile?['user_id'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('उत्पाद का विवरण (Product Details)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: productAsync.when(
        data: (product) {
          final name = product['name'] as String;
          final desc = product['description'] ?? 'कोई विवरण उपलब्ध नहीं है।';
          final category = product['category'] ?? 'General';
          final brand = product['brand'] as String?;
          final price = product['price'] as double;
          final mrp = product['mrp'] as double?;
          final stock = product['stock'] as int;
          final imageUrl = product['image_url'];
          final fullImageUrl = imageUrl != null ? '$baseUrl$imageUrl' : null;

          const isOwner = true; // Support demo edits

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Photo Cover
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.2,
                      ),
                      child: fullImageUrl != null
                          ? Image.network(
                              fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 80,
                                    color: theme.colorScheme.primary,
                                  ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                    if (isOwner)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: FloatingActionButton.small(
                          onPressed: () => _uploadMockPhoto(context, ref),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          child: const Icon(Icons.camera_alt_rounded),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${price.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (mrp != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'MRP: ₹$mrp',
                                  style: const TextStyle(
                                    fontSize: 13,
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
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          'ब्रांड (Brand): $brand',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.m),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.s,
                              ),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: stock > 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.s,
                              ),
                            ),
                            child: Text(
                              stock > 0
                                  ? 'स्टॉक में उपलब्ध ($stock)'
                                  : 'स्टॉक समाप्त',
                              style: TextStyle(
                                color: stock > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Text(desc, style: theme.textTheme.bodyLarge),
                      const Divider(height: 40),

                      // Quantity Selector & Add To Cart Box
                      if (stock > 0) ...[
                        Row(
                          children: [
                            Text(
                              'मात्रा (Quantity):',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              onPressed: _quantity < stock
                                  ? () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        PrimaryButton(
                          text: 'कार्ट में जोड़ें (Add to Cart)',
                          isLoading: _addingToCart,
                          onPressed: () => _addToCart(stock),
                        ),
                        const Divider(height: 40),
                      ],

                      if (isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'संपादित करें (Edit)',
                                icon: Icons.edit_rounded,
                                onPressed: () => context.go(
                                  '/products/${widget.productId}/edit',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: OutlineButton(
                                text: 'उत्पाद हटाएं (Delete)',
                                icon: Icons.delete_outline_rounded,
                                onPressed: () => _deleteProduct(context, ref),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40),
                      ],

                      // Ratings Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'रेटिंग और समीक्षाएं (Reviews)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => context.go(
                              '/review/write?productId=${widget.productId}',
                            ),
                            icon: Icon(
                              Icons.rate_review_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(
                              'समीक्षा लिखें',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),

                      ref
                          .watch(productRatingSummaryProvider(widget.productId))
                          .when(
                            data: (summary) {
                              final avg =
                                  summary['average_rating'] as double? ?? 0.0;
                              final total =
                                  summary['total_ratings'] as int? ?? 0;
                              final starCountsRaw =
                                  summary['star_counts']
                                      as Map<String, dynamic>? ??
                                  {};
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

                      const SizedBox(height: AppSpacing.l),

                      ref
                          .watch(productReviewsProvider(widget.productId))
                          .when(
                            data: (reviews) {
                              if (reviews.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.xl,
                                    ),
                                    child: Text(
                                      'अभी तक कोई समीक्षा नहीं है। पहली समीक्षा लिखें!',
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
                                  final r =
                                      reviews[index] as Map<String, dynamic>;
                                  final reviewId = r['id'] as int;
                                  final comment = r['comment'] as String;
                                  final ratingVal = r['rating_value'] as int;
                                  final userName =
                                      r['user_name'] ?? 'Anonymous';
                                  final reviewUserId = r['user_id'] as int?;

                                  final isMyReview =
                                      currentUserId == null ||
                                      currentUserId == reviewUserId;

                                  return Card(
                                    margin: const EdgeInsets.only(
                                      bottom: AppSpacing.m,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.m,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.m,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              StarRatingWidget(
                                                rating: ratingVal.toDouble(),
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.s),
                                          Text(
                                            comment,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          if (isMyReview) ...[
                                            const Divider(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => context.go(
                                                    '/review/edit?reviewId=$reviewId&productId=${widget.productId}&ratingValue=$ratingVal&comment=${Uri.encodeComponent(comment)}',
                                                  ),
                                                  icon: const Icon(
                                                    Icons.edit_rounded,
                                                    size: 14,
                                                    color: Colors.orange,
                                                  ),
                                                  label: const Text(
                                                    'संपादित करें',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () async {
                                                    await ref
                                                        .read(
                                                          reviewOpsProvider
                                                              .notifier,
                                                        )
                                                        .deleteReview(
                                                          reviewId,
                                                          productId:
                                                              widget.productId,
                                                        );
                                                  },
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 14,
                                                    color: AppColors.error,
                                                  ),
                                                  label: const Text(
                                                    'हटाएं',
                                                    style: TextStyle(
                                                      color: AppColors.error,
                                                    ),
                                                  ),
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
        error: (err, stack) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(productDetailsProvider(widget.productId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
