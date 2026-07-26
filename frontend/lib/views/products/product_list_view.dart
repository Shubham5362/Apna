import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class ProductListView extends ConsumerStatefulWidget {
  const ProductListView({super.key});

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView> {
  final List<String> _recentSearches = [];
  bool _showSuggestions = false;
  final TextEditingController _searchController = TextEditingController();

  // Timer for Flash Sale countdown
  late Timer _countdownTimer;
  Duration _flashSaleDuration = const Duration(hours: 3, minutes: 45, seconds: 0);

  // Promotional Banner Banners
  final List<Map<String, String>> _promoBanners = [
    {
      'title': 'Apna Winter Market Fest!',
      'subtitle': 'Up to 30% off on fresh winter vegetables',
      'code': 'WINTER30',
      'color': '0xFF1B5E20'
    },
    {
      'title': 'Pure Organic Honey & Ghee',
      'subtitle': 'Direct from local farmers in Mandla',
      'code': 'LOCALLOVE',
      'color': '0xFFE65100'
    },
    {
      'title': 'Dairy Special Discounts',
      'subtitle': 'Fresh organic milk, paneer & butter',
      'code': 'FRESHDAIRY',
      'color': '0xFF0D47A1'
    }
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view, 'color': Colors.blue},
    {'name': 'Fruits', 'icon': Icons.apple, 'color': Colors.red},
    {'name': 'Vegetables', 'icon': Icons.eco, 'color': Colors.green},
    {'name': 'Bakery', 'icon': Icons.bakery_dining, 'color': Colors.amber},
    {'name': 'Dairy', 'icon': Icons.local_cafe, 'color': Colors.indigo},
    {'name': 'Grains', 'icon': Icons.grain, 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_flashSaleDuration.inSeconds > 0) {
            _flashSaleDuration = _flashSaleDuration - const Duration(seconds: 1);
          } else {
            _flashSaleDuration = const Duration(hours: 4, minutes: 0, seconds: 0);
          }
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final selectedCategory = ref.watch(productSelectedCategoryProvider);
    final sortBy = ref.watch(productSortByProvider);
    final baseUrl = ref.watch(apiClientProvider).dio.options.baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apna Mandla Digital Market'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(productsListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LIVE SEARCH BAR WITH SUGGESTIONS & RECENT SEARCHES
            Padding(
              padding: const EdgeInsets.all(16.0),
              // Search UI container
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onTap: () {
                      setState(() {
                        _showSuggestions = true;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search fresh vegetables, fruits, dairy...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(productSearchQueryProvider.notifier).state = '';
                                setState(() {
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      ref.read(productSearchQueryProvider.notifier).state = value;
                    },
                    onSubmitted: (value) {
                      final val = value.trim();
                      if (val.isNotEmpty && !_recentSearches.contains(val)) {
                        setState(() {
                          _recentSearches.insert(0, val);
                          if (_recentSearches.length > 5) {
                            _recentSearches.removeLast();
                          }
                        });
                      }
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  ),

                  // Suggestions Dropdown
                  if (_showSuggestions) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_recentSearches.isNotEmpty) ...[
                            const Text(
                              'Recent Searches',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                            ),
                            Wrap(
                              spacing: 8,
                              children: _recentSearches.map((s) {
                                return ActionChip(
                                  label: Text(s),
                                  onPressed: () {
                                    _searchController.text = s;
                                    ref.read(productSearchQueryProvider.notifier).state = s;
                                    setState(() {
                                      _showSuggestions = false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const Divider(),
                          ],
                          const Text(
                            'Popular Suggestions',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: ['Fresh Apple', 'Organic Potato', 'Pure Milk', 'Desi Ghee', 'Wheat Grains'].map((s) {
                              return ActionChip(
                                label: Text(s),
                                onPressed: () {
                                  _searchController.text = s;
                                  ref.read(productSearchQueryProvider.notifier).state = s;
                                  setState(() {
                                    _showSuggestions = false;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. BANNER PROMO SLIDER (HORIZONTAL AUTOSCROLL/CAROUSEL)
            SizedBox(
              height: 140,
              child: PageView.builder(
                itemCount: _promoBanners.length,
                itemBuilder: (context, index) {
                  final banner = _promoBanners[index];
                  final colorVal = int.parse(banner['color']!);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(colorVal),
                          Color(colorVal).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(colorVal).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                banner['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner['subtitle']!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Use Code: ${banner['code']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.local_offer,
                          color: Colors.white24,
                          size: 64,
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. CATEGORY GRID (EASY SELECTION FILTER)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                'Explore Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as IconData;
                  final color = cat['color'] as Color;
                  final isSelected = (selectedCategory == name) || (selectedCategory == null && name == 'All');

                  return GestureDetector(
                    onTap: () {
                      ref.read(productSelectedCategoryProvider.notifier).state = name == 'All' ? null : name;
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? color : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. FLASH SALE SECTION (countdown + list)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.deepOrange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FLASH SALE!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Direct farmer discounts',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDuration(_flashSaleDuration),
                        style: TextStyle(
                          color: Colors.deepOrange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // 5. RESPONSIVE PRODUCT LIST GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCategory == null ? 'All Products' : '$selectedCategory Products',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // Sort selector
                  DropdownButton<String>(
                    value: sortBy,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.filter_list),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(productSortByProvider.notifier).state = value;
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                      DropdownMenuItem(value: 'price low-high', child: Text('Price: Low-High')),
                      DropdownMenuItem(value: 'price high-low', child: Text('Price: High-Low')),
                    ],
                  ),
                ],
              ),
            ),

            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No products found matching filters.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final crossAxisCount = ResponsiveLayout.getResponsiveValue(
                  context: context,
                  mobile: 2.0,
                  tablet: 3.0,
                  desktop: 5.0,
                ).toInt();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.65,
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
                    final stock = product['stock'] as int;
                    final cat = product['category'] ?? 'General';
                    final imageUrl = product['image_url'];
                    final fullImageUrl = imageUrl != null ? '$baseUrl$imageUrl' : null;

                    // Calculate discount percentage
                    int discountPercent = 0;
                    if (mrp != null && mrp > price) {
                      discountPercent = (((mrp - price) / mrp) * 100).round();
                    }

                    return Card(
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/products/$id'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image and Badges
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: Colors.orange.shade50,
                                    child: fullImageUrl != null
                                        ? Image.network(
                                            fullImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.shopping_bag, size: 48, color: Colors.orange),
                                          )
                                        : const Icon(Icons.shopping_bag, size: 48, color: Colors.orange),
                                  ),
                                  if (discountPercent > 0)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$discountPercent% OFF',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stock > 0 ? Colors.green.shade600 : Colors.red.shade600,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        stock > 0 ? 'In Stock' : 'Out of Stock',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Product details
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '4.5',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        '\$$price',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (mrp != null)
                                        Text(
                                          '\$$mrp',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stock > 0 ? '$stock units available' : 'Temporarily unavailable',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: stock > 0 ? Colors.grey : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
