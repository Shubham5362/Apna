import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../widgets/reusable_widgets.dart';

class ShopListView extends ConsumerWidget {
  const ShopListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopsAsync = ref.watch(shopsListProvider);
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('स्थानीय दुकानें (Local Shops)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(shopsListProvider),
          ),
        ],
      ),
      body: shopsAsync.when(
        data: (shops) {
          if (shops.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                title: 'कोई दुकान पंजीकृत नहीं है!',
                description:
                    'अपना मांडला में पहली दुकान पंजीकृत करने के लिए नीचे क्लिक करें।',
                icon: Icons.storefront_rounded,
                actionText: 'दुकान पंजीकृत करें',
                onActionPressed: () => context.go('/shops/create'),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: AppSpacing.m,
              mainAxisSpacing: AppSpacing.m,
            ),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index] as Map<String, dynamic>;
              final id = shop['id'] as int;
              final name = shop['name'] as String;
              final desc = shop['description'] ?? 'कोई विवरण उपलब्ध नहीं';
              final imageUrl = shop['image_url'];
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
                  onTap: () => context.go('/shops/$id'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
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
                                        Icons.store_outlined,
                                        size: 44,
                                        color: theme.colorScheme.primary,
                                      ),
                                )
                              : Icon(
                                  Icons.store_outlined,
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
          onRetry: () => ref.refresh(shopsListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/shops/create'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('दुकान जोड़ें (Add Shop)'),
      ),
    );
  }
}
