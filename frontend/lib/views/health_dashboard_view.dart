import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets/reusable_widgets.dart';

class HealthDashboardView extends ConsumerStatefulWidget {
  const HealthDashboardView({super.key});

  @override
  ConsumerState<HealthDashboardView> createState() =>
      _HealthDashboardViewState();
}

class _HealthDashboardViewState extends ConsumerState<HealthDashboardView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(productsListProvider);
    ref.invalidate(shopsListProvider);
    ref.invalidate(healthCheckProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final healthState = ref.watch(healthCheckProvider);
    final productsState = ref.watch(productsListProvider);
    final shopsState = ref.watch(shopsListProvider);

    final List<Map<String, String>> banners = [
      {
        'title': 'स्वदेशी बाज़ार',
        'subtitle': 'आपके शहर का अपना डिजिटल मांडला',
        'image': 'assets/banner1.jpg',
      },
      {
        'title': 'ताजा सब्जियां और फल',
        'subtitle': 'सीधे स्थानीय खेतों से आपके घर तक',
        'image': 'assets/banner2.jpg',
      },
      {
        'title': '100% शुद्ध डेयरी उत्पाद',
        'subtitle': 'ताजा दूध, मक्खन और पनीर',
        'image': 'assets/banner3.jpg',
      },
    ];

    final List<Map<String, dynamic>> categories = [
      {'name': 'Vegetables', 'hindi': 'सब्जियां', 'icon': Icons.eco_rounded},
      {'name': 'Fruits', 'hindi': 'फल', 'icon': Icons.apple_rounded},
      {'name': 'Dairy', 'hindi': 'डेयरी', 'icon': Icons.water_drop_rounded},
      {
        'name': 'Grocery',
        'hindi': 'किराना',
        'icon': Icons.local_grocery_store_rounded,
      },
      {'name': 'Bakery', 'hindi': 'बेकरी', 'icon': Icons.cookie_rounded},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'APNA MANDLA',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              context.go('/cart');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Search Bar
              AppSearchBar(
                controller: _searchController,
                hintText: 'मांडला में उत्पाद, दुकानें खोजें...',
                onChanged: (val) {
                  ref.read(productSearchQueryProvider.notifier).state = val;
                },
                onSubmitted: (val) {
                  context.go('/products');
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // 2. Announcements Carousel
              SizedBox(
                height: 140,
                child: PageView.builder(
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return Container(
                      margin: const EdgeInsets.only(right: AppSpacing.s),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.l),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner['title']!,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            banner['subtitle']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Category Row Section
              Text(
                'श्रेणियां (Categories)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return GestureDetector(
                      onTap: () {
                        ref
                                .read(productSelectedCategoryProvider.notifier)
                                .state =
                            cat['name'];
                        context.go('/products');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: AppSpacing.m),
                        width: 80,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.1),
                              child: Icon(
                                cat['icon'] as IconData,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              cat['hindi'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Featured Products Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'लोकप्रिय उत्पाद (Featured Products)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(productSelectedCategoryProvider.notifier).state =
                          null;
                      ref.read(productSelectedShopIdProvider.notifier).state =
                          null;
                      context.go('/products');
                    },
                    child: Text(
                      'सभी देखें',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              productsState.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
                      child: Text(
                        'कोई उत्पाद उपलब्ध नहीं है (No products available)',
                      ),
                    );
                  }
                  final limit = math.min(products.length, 4);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: AppSpacing.m,
                          mainAxisSpacing: AppSpacing.m,
                        ),
                    itemCount: limit,
                    itemBuilder: (context, index) {
                      final p = products[index] as Map<String, dynamic>;
                      return ProductCard(
                        title: p['name'] as String,
                        price: p['price'] as double,
                        category: p['category'] as String?,
                        shopName: 'मांडला विक्रेता',
                        onTap: () {
                          context.go('/products/${p['id']}');
                        },
                      );
                    },
                  );
                },
                error: (err, s) => ErrorStateWidget(message: err.toString()),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5. Nearby Shops Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'आसपास की दुकानें (Nearby Shops)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/shops');
                    },
                    child: Text(
                      'सभी देखें',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              shopsState.when(
                data: (shops) {
                  if (shops.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
                      child: Text(
                        'कोई दुकान उपलब्ध नहीं है (No shops available)',
                      ),
                    );
                  }
                  final limit = math.min(shops.length, 3);
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: limit,
                    itemBuilder: (context, index) {
                      final s = shops[index] as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: ShopCard(
                          name: s['name'] as String,
                          address:
                              s['description'] as String? ?? 'पता उपलब्ध नहीं',
                          onTap: () {
                            context.go('/shops/${s['id']}');
                          },
                        ),
                      );
                    },
                  );
                },
                error: (err, s) => ErrorStateWidget(message: err.toString()),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 6. Existing System Status Monitor Card
              Card(
                elevation: 1,
                color: isDark
                    ? Colors.grey.shade900
                    : Colors.blue.shade50.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.m),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            'System Status Check',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      healthState.when(
                        data: (data) {
                          final isHealthy =
                              data['status'] == 'healthy' ||
                              data['status'] == 'ok';
                          final dbStatus = data['database'] ?? 'unknown';
                          final redisStatus = data['redis'] ?? 'unknown';
                          final version = data['version'] ?? 'unknown';

                          return Column(
                            children: [
                              _StatusRow(
                                label: 'API Gateway',
                                status: isHealthy ? 'healthy' : 'unhealthy',
                              ),
                              const SizedBox(height: AppSpacing.s),
                              _StatusRow(
                                label: 'Database (PostgreSQL)',
                                status: dbStatus,
                              ),
                              const SizedBox(height: AppSpacing.s),
                              _StatusRow(
                                label: 'Cache (Redis)',
                                status: redisStatus,
                              ),
                              const Divider(height: 24),
                              Text(
                                'Version: $version',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                        error: (err, stack) => Text(
                          'Connection Error: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                        loading: () => const CircularProgressIndicator(),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Wrap(
                        spacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            onPressed: () {
                              context.go('/login');
                            },
                            icon: const Icon(
                              Icons.lock_person_rounded,
                              size: 16,
                            ),
                            label: const Text('🔐 Premium Login'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => ref.refresh(healthCheckProvider),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh Status'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;

  const _StatusRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isOk =
        status.toLowerCase() == 'healthy' ||
        status.toLowerCase() == 'connected' ||
        status.toLowerCase() == 'ok';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isOk
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.s),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: isOk ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
