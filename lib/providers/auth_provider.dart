import 'package:http/http.dart' as http; // Corrige el error de 'http'
import 'dart:convert';               // Corrige el error de 'jsonEncode' y 'json.decode'
import 'package:flutter/material.dart';
import 'package:parfum/models/user_model.dart';
import 'package:parfum/providers/cart_provider.dart';


// ── AuthProvider ──────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  // ── 🌐 URL DE TU SERVIDOR (ngrok actual) ──────────────────────────
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';

  UserModel? _user;
  bool _loading = false;
  String? _error;

  // GETTERS
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading    => _loading;
  String? get error   => _error;
  String get rol      => _user?.rol ?? '';
  
  // 🏆 GETTER CLAVE: Para que el LoginScreen le pase el ID al CartProvider de forma directa
  int get idUsuario   => _user?.id ?? 0;

  Future<bool> tryAutoLogin() async {
    // Aquí podrías meter persistencia con SharedPreferences más adelante
    return false;
  }

  // ── 🔑 LOGIN TRANSACCIONAL CON BASE DE DATOS ──────────────────────
  // ── Modifica la firma para recibir al CartProvider ──
Future<bool> login(String email, String password, CartProvider cart) async {
  _loading = true; 
  _error = null; 
  notifyListeners();

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/login.php'),
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        final int idRolReal = data['id_rol'];
        String stringRol = 'cliente';

        if (idRolReal == 1) stringRol = 'gerente';
        if (idRolReal == 2) stringRol = 'cajero';
        if (idRolReal == 3) stringRol = 'almacenista';

        _user = UserModel(
          id: data['id_usuario'],
          nombre: data['nombre'],
          email: email.trim(),
          rol: stringRol,
          idRol: idRolReal,
        );

        // 🔥 EL TRUCO MAESTRO: Enlazamos el usuario al carrito AQUÍ,
        // justo antes de que las pantallas cambien de lugar.
        cart.registrarUsuario(data['id_usuario']);

        _loading = false;
        notifyListeners(); // Ahora sí, que el main reconstruya el router en paz
        return true;
      } else {
        _error = data['message'];
      }
    } else {
      _error = 'Error de respuesta del servidor (${response.statusCode})';
    }
  } catch (e) {
    _error = 'No se pudo conectar con el servidor.';
  }

  _loading = false;
  notifyListeners();
  return false;
}
  // ── 📝 REGISTRO DE NUEVOS CLIENTES (Opcional, se conecta igual) ──
  // ── 📝 REGISTRO REAL DE NUEVOS CLIENTES (Conectado a MySQL) ──
  Future<bool> register({
    required String nombre, 
    required String email,
    required String password, 
    String? telefono,
  }) async {
    _loading = true; 
    _error = null; 
    notifyListeners();

    try {
      print('🌐 [Auth] Enviando registro de cliente a MySQL...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/registro_cliente.php'),
        body: {
          'nombre': nombre,
          'email': email,
          'password': password,
          'tel': telefono ?? '', // 🔥 CORREGIDO: Enviamos 'tel' al PHP
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final userMap = data['user'];
          
          // 🔥 MAPEADO EXACTO: Captura userMap['tel'] que envía el nuevo PHP
          _user = UserModel(
            id: userMap['id'] as int? ?? 0,
            nombre: userMap['nombre'] as String? ?? nombre,
            email: userMap['email'] as String? ?? email, 
            telefono: userMap['tel'] as String? ?? telefono, // Mapea 'tel' a tu propiedad local
            rol: 'cliente',
            idRol: userMap['id_rol'] as int? ?? 4, 
          );
          
          _error = null;
          print('✅ [Auth] Registro completado y sesión iniciada con éxito.');
          return true;
        } else {
          _error = data['message'] ?? 'Error al registrar la cuenta.';
          return false;
        }
      } else {
        _error = 'Error de respuesta del servidor (${response.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión. Verifica que ngrok esté encendido.';
      print('Error crítico en register: $e');
      return false;
    } finally {
      _loading = false; 
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null; 
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;
    _user = _user!.copyWith(
      nombre: data['nombre'] as String?,
      telefono: data['telefono'] as String?,
    );
    notifyListeners();
    return true;
  }

  void clearError() { _error = null; notifyListeners(); }

  

}
