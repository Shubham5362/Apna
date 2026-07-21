import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  String? _token;

  ApiClient({String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? 'http://localhost:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _token = token;
  }

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await dio.get('/api/v1/health');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'unhealthy', 'error': 'Invalid format response'};
    } catch (e) {
      return {'status': 'unhealthy', 'error': e.toString()};
    }
  }

  // --- Profile APIs ---
  Future<Map<String, dynamic>> getProfile() async {
    final response = await dio.get('/api/v1/profile');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await dio.put('/api/v1/profile', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(
    List<int> bytes,
    String filename,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('image', 'png'),
      ),
    });
    final response = await dio.post('/api/v1/profile/photo', data: formData);
    return response.data as Map<String, dynamic>;
  }

  // --- Shop APIs ---
  Future<List<dynamic>> getShops() async {
    final response = await dio.get('/api/v1/shops');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getShopById(int id) async {
    final response = await dio.get('/api/v1/shops/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createShop(Map<String, dynamic> data) async {
    final response = await dio.post('/api/v1/shops', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateShop(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/api/v1/shops/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteShop(int id) async {
    final response = await dio.delete('/api/v1/shops/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadShopPhoto(
    int id,
    List<int> bytes,
    String filename,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('image', 'png'),
      ),
    });
    final response = await dio.post('/api/v1/shops/$id/photo', data: formData);
    return response.data as Map<String, dynamic>;
  }
}
