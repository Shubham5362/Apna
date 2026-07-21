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

  // --- Product APIs ---
  Future<List<dynamic>> getProducts({
    String? search,
    String? category,
    int? shopId,
    String? sortBy,
    int? skip,
    int? limit,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (shopId != null) {
      queryParams['shop_id'] = shopId;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sort_by'] = sortBy;
    }
    if (skip != null) {
      queryParams['skip'] = skip;
    }
    if (limit != null) {
      queryParams['limit'] = limit;
    }

    final response = await dio.get(
      '/api/v1/products',
      queryParameters: queryParams,
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await dio.get('/api/v1/products/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await dio.post('/api/v1/products', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.put('/api/v1/products/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    final response = await dio.delete('/api/v1/products/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadProductPhoto(
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
    final response = await dio.post(
      '/api/v1/products/$id/photo',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  // --- Cart & Order APIs ---
  Future<Map<String, dynamic>> getCart() async {
    final response = await dio.get('/api/v1/cart');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    final response = await dio.post(
      '/api/v1/cart',
      data: {'product_id': productId, 'quantity': quantity},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCartItem(int itemId, int quantity) async {
    final response = await dio.put(
      '/api/v1/cart/$itemId',
      data: {'quantity': quantity},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeFromCart(int itemId) async {
    final response = await dio.delete('/api/v1/cart/$itemId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> clearCart() async {
    final response = await dio.delete('/api/v1/cart');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createOrder(String deliveryAddress) async {
    final response = await dio.post(
      '/api/v1/orders',
      data: {'delivery_address': deliveryAddress},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getOrders() async {
    final response = await dio.get('/api/v1/orders');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOrderById(int orderId) async {
    final response = await dio.get('/api/v1/orders/$orderId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final response = await dio.put(
      '/api/v1/orders/$orderId/status',
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  }

  // --- Payment APIs ---
  Future<Map<String, dynamic>> createPayment(
    int orderId,
    String paymentMethod,
  ) async {
    final response = await dio.post(
      '/api/v1/payments/create',
      data: {'order_id': orderId, 'payment_method': paymentMethod},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(
    String razorpayOrderId,
    String razorpayPaymentId,
    String razorpaySignature,
  ) async {
    final response = await dio.post(
      '/api/v1/payments/verify',
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPaymentHistory() async {
    final response = await dio.get('/api/v1/payments/history');
    return response.data as List<dynamic>;
  }
}
