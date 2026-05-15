import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parfum/core/network/api_client.dart';
import 'package:parfum/core/constants/api_endpoints.dart';
import 'package:parfum/models/user_model.dart';

class AuthService {
  final Dio _dio = ApiClient.instance;

  /// Login → guarda token y devuelve UserModel
  Future<UserModel> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    final token = res.data['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  /// Registro de cliente
  Future<UserModel> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'nombre': nombre, 'email': email,
      'password': password, 'telefono': telefono,
    });
    final token = res.data['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  /// Devuelve el usuario autenticado desde el token guardado
  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Cierra sesión: elimina el token local
  Future<void> logout() async {
    try { await _dio.post(ApiEndpoints.logout); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  /// Actualizar datos de perfil (cliente)
  Future<UserModel> updateProfile(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/users/$id', data: data);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }
}
