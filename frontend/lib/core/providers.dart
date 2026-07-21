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
