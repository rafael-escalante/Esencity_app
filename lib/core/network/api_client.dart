import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();

  // ── Cambia esta URL por la de tu servidor FastAPI ──────────────
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
  // static const String _baseUrl = 'http://localhost:8000'; // Web/iOS
  // static const String _baseUrl = 'http://192.168.1.X:8000'; // Dispositivo físico

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static bool _initialized = false;

  static Dio get instance {
    if (!_initialized) {
      _dio.interceptors.add(_JwtInterceptor());
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => print('[API] $o'),
      ));
      _initialized = true;
    }
    return _dio;
  }
}

// ── Interceptor que adjunta el Bearer token en cada petición ──────
class _JwtInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 → limpiar sesión (el AuthProvider lo manejará vía go_router)
    if (err.response?.statusCode == 401) {
      SharedPreferences.getInstance().then((p) => p.remove('access_token'));
    }
    handler.next(err);
  }
}
