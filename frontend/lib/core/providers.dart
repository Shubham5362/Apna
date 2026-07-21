import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );
  final client = ApiClient(baseUrl: backendUrl);
  final token = ref.watch(authTokenProvider);
  client.setAuthToken(token);
  return client;
});

final authTokenProvider = StateProvider<String?>((ref) => null);

final healthCheckProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.checkHealth();
});

// --- Profile state ---
class UserProfileState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? error;

  UserProfileState({this.profile, this.isLoading = false, this.error});

  UserProfileState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final ApiClient _apiClient;

  UserProfileNotifier(this._apiClient) : super(UserProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _apiClient.getProfile();
      state = UserProfileState(profile: profile, isLoading: false);
    } catch (e) {
      state = UserProfileState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _apiClient.updateProfile(data);
      state = UserProfileState(profile: profile, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadPhoto(List<int> bytes, String filename) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _apiClient.uploadProfilePhoto(bytes, filename);
      state = UserProfileState(profile: profile, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final client = ref.watch(apiClientProvider);
      return UserProfileNotifier(client);
    });

// --- Shop state and providers ---
final shopsListProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  return client.getShops();
});

final shopDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final client = ref.watch(apiClientProvider);
      return client.getShopById(id);
    });

class ShopOpsState {
  final bool isLoading;
  final String? error;

  ShopOpsState({this.isLoading = false, this.error});

  ShopOpsState copyWith({bool? isLoading, String? error}) {
    return ShopOpsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ShopOpsNotifier extends StateNotifier<ShopOpsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ShopOpsNotifier(this._apiClient, this._ref) : super(ShopOpsState());

  Future<Map<String, dynamic>?> createShop(Map<String, dynamic> data) async {
    state = ShopOpsState(isLoading: true);
    try {
      final shop = await _apiClient.createShop(data);
      state = ShopOpsState(isLoading: false);
      _ref.invalidate(shopsListProvider);
      return shop;
    } catch (e) {
      state = ShopOpsState(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> updateShop(int id, Map<String, dynamic> data) async {
    state = ShopOpsState(isLoading: true);
    try {
      await _apiClient.updateShop(id, data);
      state = ShopOpsState(isLoading: false);
      _ref.invalidate(shopsListProvider);
      _ref.invalidate(shopDetailsProvider(id));
      return true;
    } catch (e) {
      state = ShopOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteShop(int id) async {
    state = ShopOpsState(isLoading: true);
    try {
      await _apiClient.deleteShop(id);
      state = ShopOpsState(isLoading: false);
      _ref.invalidate(shopsListProvider);
      return true;
    } catch (e) {
      state = ShopOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadPhoto(int id, List<int> bytes, String filename) async {
    state = ShopOpsState(isLoading: true);
    try {
      await _apiClient.uploadShopPhoto(id, bytes, filename);
      state = ShopOpsState(isLoading: false);
      _ref.invalidate(shopsListProvider);
      _ref.invalidate(shopDetailsProvider(id));
      return true;
    } catch (e) {
      state = ShopOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final shopOpsProvider = StateNotifierProvider<ShopOpsNotifier, ShopOpsState>((
  ref,
) {
  final client = ref.watch(apiClientProvider);
  return ShopOpsNotifier(client, ref);
});

// --- Product state and providers ---
final productSearchQueryProvider = StateProvider<String>((ref) => '');
final productSelectedCategoryProvider = StateProvider<String?>((ref) => null);
final productSelectedShopIdProvider = StateProvider<int?>((ref) => null);
final productSortByProvider = StateProvider<String>((ref) => 'newest');

final productsListProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  final search = ref.watch(productSearchQueryProvider);
  final category = ref.watch(productSelectedCategoryProvider);
  final shopId = ref.watch(productSelectedShopIdProvider);
  final sortBy = ref.watch(productSortByProvider);

  return client.getProducts(
    search: search,
    category: category,
    shopId: shopId,
    sortBy: sortBy,
  );
});

final productDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final client = ref.watch(apiClientProvider);
      return client.getProductById(id);
    });

class ProductOpsState {
  final bool isLoading;
  final String? error;

  ProductOpsState({this.isLoading = false, this.error});

  ProductOpsState copyWith({bool? isLoading, String? error}) {
    return ProductOpsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProductOpsNotifier extends StateNotifier<ProductOpsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ProductOpsNotifier(this._apiClient, this._ref) : super(ProductOpsState());

  Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> data) async {
    state = ProductOpsState(isLoading: true);
    try {
      final product = await _apiClient.createProduct(data);
      state = ProductOpsState(isLoading: false);
      _ref.invalidate(productsListProvider);
      return product;
    } catch (e) {
      state = ProductOpsState(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    state = ProductOpsState(isLoading: true);
    try {
      await _apiClient.updateProduct(id, data);
      state = ProductOpsState(isLoading: false);
      _ref.invalidate(productsListProvider);
      _ref.invalidate(productDetailsProvider(id));
      return true;
    } catch (e) {
      state = ProductOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    state = ProductOpsState(isLoading: true);
    try {
      await _apiClient.deleteProduct(id);
      state = ProductOpsState(isLoading: false);
      _ref.invalidate(productsListProvider);
      return true;
    } catch (e) {
      state = ProductOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadPhoto(int id, List<int> bytes, String filename) async {
    state = ProductOpsState(isLoading: true);
    try {
      await _apiClient.uploadProductPhoto(id, bytes, filename);
      state = ProductOpsState(isLoading: false);
      _ref.invalidate(productsListProvider);
      _ref.invalidate(productDetailsProvider(id));
      return true;
    } catch (e) {
      state = ProductOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final productOpsProvider =
    StateNotifierProvider<ProductOpsNotifier, ProductOpsState>((ref) {
      final client = ref.watch(apiClientProvider);
      return ProductOpsNotifier(client, ref);
    });

// --- Cart state and providers ---
class CartState {
  final Map<String, dynamic>? cart;
  final bool isLoading;
  final String? error;

  CartState({this.cart, this.isLoading = false, this.error});

  CartState copyWith({
    Map<String, dynamic>? cart,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final ApiClient _apiClient;

  CartNotifier(this._apiClient) : super(CartState()) {
    fetchCart();
  }

  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _apiClient.getCart();
      state = CartState(cart: cart, isLoading: false);
    } catch (e) {
      state = CartState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addToCart(int productId, int quantity) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _apiClient.addToCart(productId, quantity);
      state = CartState(cart: cart, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateCartItem(int itemId, int quantity) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _apiClient.updateCartItem(itemId, quantity);
      state = CartState(cart: cart, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeFromCart(int itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _apiClient.removeFromCart(itemId);
      state = CartState(cart: cart, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> clearCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cart = await _apiClient.clearCart();
      state = CartState(cart: cart, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final client = ref.watch(apiClientProvider);
  return CartNotifier(client);
});

// --- Order state and providers ---
final ordersListProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  return client.getOrders();
});

final orderDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final client = ref.watch(apiClientProvider);
      return client.getOrderById(id);
    });

class OrderOpsState {
  final bool isLoading;
  final String? error;

  OrderOpsState({this.isLoading = false, this.error});

  OrderOpsState copyWith({bool? isLoading, String? error}) {
    return OrderOpsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class OrderOpsNotifier extends StateNotifier<OrderOpsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  OrderOpsNotifier(this._apiClient, this._ref) : super(OrderOpsState());

  Future<Map<String, dynamic>?> placeOrder(String deliveryAddress) async {
    state = OrderOpsState(isLoading: true);
    try {
      final order = await _apiClient.createOrder(deliveryAddress);
      state = OrderOpsState(isLoading: false);
      _ref.invalidate(ordersListProvider);
      _ref.read(cartProvider.notifier).fetchCart(); // Fetch the cleared cart
      return order;
    } catch (e) {
      state = OrderOpsState(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> updateStatus(int orderId, String status) async {
    state = OrderOpsState(isLoading: true);
    try {
      await _apiClient.updateOrderStatus(orderId, status);
      state = OrderOpsState(isLoading: false);
      _ref.invalidate(ordersListProvider);
      _ref.invalidate(orderDetailsProvider(orderId));
      return true;
    } catch (e) {
      state = OrderOpsState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final orderOpsProvider = StateNotifierProvider<OrderOpsNotifier, OrderOpsState>(
  (ref) {
    final client = ref.watch(apiClientProvider);
    return OrderOpsNotifier(client, ref);
  },
);
