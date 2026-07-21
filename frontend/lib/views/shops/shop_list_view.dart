import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class ShopListView extends ConsumerWidget {
  const ShopListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsListProvider);
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(shopsListProvider),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: shopsAsync.when(
        data: (shops) {
          if (shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No shops registered yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/shops/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your Shop'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index] as Map<String, dynamic>;
              final id = shop['id'] as int;
              final name = shop['name'] as String;
              final desc = shop['description'] ?? 'No description provided';
              final imageUrl = shop['image_url'];
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
                  onTap: () => context.go('/shops/$id'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.blue.shade50,
                          child: fullImageUrl != null
                              ? Image.network(
                                  fullImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.store,
                                        size: 48,
                                        color: Colors.blue,
                                      ),
                                )
                              : const Icon(
                                  Icons.store,
                                  size: 48,
                                  color: Colors.blue,
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
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
        error: (err, stack) => Center(
          child: Text(
            'Error loading shops: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/shops/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Shop'),
      ),
    );
  }
}
