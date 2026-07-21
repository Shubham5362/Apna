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
