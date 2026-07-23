import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/rating_widgets.dart';
import '../widgets/reusable_widgets.dart';

class ShopDetailsView extends ConsumerWidget {
  final int shopId;

  const ShopDetailsView({super.key, required this.shopId});

  Future<void> _uploadMockPhoto(BuildContext context, WidgetRef ref) async {
    final mockPngBytes = List<int>.generate(150, (i) => i);
    final success = await ref
        .read(shopOpsProvider.notifier)
        .uploadPhoto(shopId, mockPngBytes, 'mock_shop.png');

    if (context.mounted) {
      if (success) {
        AppSnackbar.show(
          context,
          message: 'दुकान की तस्वीर सफलतापूर्वक बदली गई!',
        );
      } else {
        final error = ref.read(shopOpsProvider).error;
        AppSnackbar.show(
          context,
          message: 'फोटो अपलोड करने में विफल: $error',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteShop(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('दुकान हटाएं (Delete Shop)'),
        content: const Text(
          'क्या आप निश्चित रूप से इस दुकान को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।',
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
          .read(shopOpsProvider.notifier)
          .deleteShop(shopId);
      if (success && context.mounted) {
        AppSnackbar.show(context, message: 'दुकान सफलतापूर्वक हटा दी गई।');
        context.go('/shops');
      } else if (context.mounted) {
        final error = ref.read(shopOpsProvider).error;
        AppSnackbar.show(
          context,
          message: 'हटाने में विफलता: $error',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final shopAsync = ref.watch(shopDetailsProvider(shopId));
    final profileState = ref.watch(userProfileProvider);
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    final currentUserId = profileState.profile?['user_id'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('दुकान का विवरण (Shop Details)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shops'),
        ),
      ),
      body: shopAsync.when(
        data: (shop) {
          final name = shop['name'] as String;
          final desc = shop['description'] ?? 'कोई विवरण उपलब्ध नहीं है।';
          final imageUrl = shop['image_url'];
          final fullImageUrl = imageUrl != null ? '$baseUrl$imageUrl' : null;
          final ownerId = shop['owner_id'] as int;
          final isActive = shop['is_active'] as bool;
          final isOwner =
              currentUserId == ownerId || profileState.profile == null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Photo cover
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
                                    Icons.store_rounded,
                                    size: 80,
                                    color: theme.colorScheme.primary,
                                  ),
                            )
                          : Icon(
                              Icons.store_rounded,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.s,
                              ),
                            ),
                            child: Text(
                              isActive
                                  ? 'सक्रिय (ACTIVE)'
                                  : 'निष्क्रिय (INACTIVE)',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        desc,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const Divider(height: 40),

                      if (isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'दुकान संपादित करें (Edit)',
                                icon: Icons.edit_rounded,
                                onPressed: () =>
                                    context.go('/shops/$shopId/edit'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: OutlineButton(
                                text: 'दुकान हटाएं (Delete)',
                                icon: Icons.delete_outline_rounded,
                                onPressed: () => _deleteShop(context, ref),
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
                            onPressed: () =>
                                context.go('/review/write?shopId=$shopId'),
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
                          .watch(shopRatingSummaryProvider(shopId))
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
                          .watch(shopReviewsProvider(shopId))
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
                                                    '/review/edit?reviewId=$reviewId&shopId=$shopId&ratingValue=$ratingVal&comment=${Uri.encodeComponent(comment)}',
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
                                                          shopId: shopId,
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
          onRetry: () => ref.refresh(shopDetailsProvider(shopId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
