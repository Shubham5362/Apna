import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(shopOpsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteShop(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text(
          'Are you sure you want to delete this shop? This action cannot be undone.',
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
          .read(shopOpsProvider.notifier)
          .deleteShop(shopId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/shops');
      } else if (context.mounted) {
        final error = ref.read(shopOpsProvider).error;
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
    final shopAsync = ref.watch(shopDetailsProvider(shopId));
    final profileState = ref.watch(userProfileProvider);
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    final currentUserId = profileState.profile?['user_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shops'),
        ),
      ),
      body: shopAsync.when(
        data: (shop) {
          final name = shop['name'] as String;
          final desc = shop['description'] ?? 'No description available.';
          final imageUrl = shop['image_url'];
          final fullImageUrl = imageUrl != null ? '$baseUrl$imageUrl' : null;
          final ownerId = shop['owner_id'] as int;
          final isActive = shop['is_active'] as bool;
          final isOwner =
              currentUserId == ownerId ||
              profileState.profile == null; // Always allow edits if demoing

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Photo Header
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.blue.shade50,
                      child: fullImageUrl != null
                          ? Image.network(
                              fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.store,
                                    size: 80,
                                    color: Colors.blue,
                                  ),
                            )
                          : const Icon(
                              Icons.store,
                              size: 80,
                              color: Colors.blue,
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
                      Text(desc, style: Theme.of(context).textTheme.bodyLarge),
                      const Divider(height: 40),
                      if (isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    context.go('/shops/$shopId/edit'),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Shop'),
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
                                onPressed: () => _deleteShop(context, ref),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete Shop'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        error: (err, stack) => Center(
          child: Text(
            'Error loading shop: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
