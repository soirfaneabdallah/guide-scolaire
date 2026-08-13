// frontend/lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/environment.dart';
import '../../features/auth/providers/auth_provider.dart';

class ApiClient {
  ApiClient({
    required AuthProvider authProvider,
  }) : _authProvider = authProvider {
    _dio = Dio(
      BaseOptions(
        // 🔥 CORRECTION ICI : Utiliser apiBase au lieu de baseUrl
        baseUrl: EnvironmentConfig.apiBase,  // 👈 http://localhost:8000/api/v1
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 180),  // 3 minutes
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _authProvider.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            _authProvider.logout();
          }
          return handler.next(error);
        },
      ),
    );

    // Logs pour le développement
    if (EnvironmentConfig.baseUrl.contains('localhost')) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          compact: false,
          maxWidth: 90,
        ),
      );
    }
  }

  late final Dio _dio;
  final AuthProvider _authProvider;

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }
}