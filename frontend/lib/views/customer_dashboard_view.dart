import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import 'products/product_list_view.dart';
import 'shops/shop_list_view.dart';
import 'cart_view.dart';
import 'orders/order_list_view.dart';
import 'user_profile_view.dart';

class CustomerDashboardView extends ConsumerStatefulWidget {
  const CustomerDashboardView({super.key});

  @override
  ConsumerState<CustomerDashboardView> createState() =>
      _CustomerDashboardViewState();
}

class _CustomerDashboardViewState extends ConsumerState<CustomerDashboardView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProductListView(),
    ShopListView(),
    CartView(),
    OrderListView(),
    UserProfileView(),
  ];

  Widget _buildAuthGate(Widget child, String tabName) {
    final token = ref.watch(authTokenProvider);
    if (token != null) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(title: Text(tabName), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'लॉगिन आवश्यक है',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in to access this tab.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Log In / Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;
    if (_currentIndex == 2) {
      activeBody = _buildAuthGate(const CartView(), 'Cart');
    } else if (_currentIndex == 3) {
      activeBody = _buildAuthGate(const OrderListView(), 'Orders');
    } else if (_currentIndex == 4) {
      activeBody = _buildAuthGate(const UserProfileView(), 'Profile');
    } else {
      activeBody = _screens[_currentIndex];
    }

    return Scaffold(
      body: activeBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Shops',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
