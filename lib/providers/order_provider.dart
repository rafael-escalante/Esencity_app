import 'package:http/http.dart' as http; // Corrige el error de 'http'
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';               // Corrige el error de 'jsonEncode' y 'json.decode'
import 'package:flutter/material.dart';
import 'package:parfum/models/employee_model.dart';
import 'package:parfum/models/order_model.dart';
import 'package:parfum/models/user_model.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/models/models.dart';
import 'package:image_picker/image_picker.dart';


class OrderProvider extends ChangeNotifier {
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';
  
  // Inicializamos las listas vacías para que se llenen directo desde MySQL
  List<OrderModel> _all    = [];
  List<OrderModel> _orders = [];
  bool _loading = false;
  String? _error;
  String? _lastFolio;
  List<dynamic> _misPedidos = [];
  List<dynamic> get misPedidos => _misPedidos;

  List<OrderModel> get orders => _orders;
  bool get loading             => _loading;
  String? get error            => _error;
  String? get lastFolio => _lastFolio;

  //Metodo para cargar pedidos (empleados)
  Future<void> loadAll({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '$_baseUrl/pedidos_leer.php';
      if (status != null) {
        url += '?status=$status';
      }
      
      // 🕵️‍♂️ Log 1: Verificar a qué dirección le estamos pegando
      print('🌐 [OrderProvider] Iniciando petición HTTP a: $url');

      final response = await http.get(Uri.parse(url));
      
      // 🕵️‍♂️ Log 2: Verificar el código de estado HTTP (Debe ser 200)
      print('📥 [OrderProvider] Código de respuesta del servidor: ${response.statusCode}');
      // 🕵️‍♂️ Log 3: Ver el texto JSON idéntico a cómo lo escupe PHP
      print('📄 [OrderProvider] JSON puro recibido: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        
        _all = decodedData.map((jsonItem) => OrderModel.fromJson(jsonItem)).toList();
        _orders = List.from(_all);
        
        // 🕵️‍♂️ Log 4: Confirmar si Flutter terminó el mapeo
        print('✅ [OrderProvider] Mapeo completado. Pedidos cargados: ${_orders.length}');
      } else {
        _error = 'Error del servidor al cargar pedidos';
      }
    } catch (e) {
      // 🕵️‍♂️ Log 5: Capturar el culpable real del fallo
      print('❌ [OrderProvider] ¡ALERTA! El proceso falló por completo: $e');
      _error = 'Error de conexión: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Cargar mis pedidos (Para el Cliente) ──────────────────────────
  Future<void> loadMine({required int idUsuario}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('🌐 [OrderProvider] Cargando pedidos del cliente ID: $idUsuario');
      
      // Enviamos el parámetro para que MySQL filtre en el servidor de forma eficiente
      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos_leer.php?id_usuario=$idUsuario'),
      );

      print('📥 [OrderProvider] Respuesta historial cliente: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        
        // Convertimos el JSON directamente a tus objetos OrderModel
        _orders = decodedData.map((jsonItem) => OrderModel.fromJson(jsonItem)).toList();
        
        print('✅ [OrderProvider] Historial del cliente mapeado. Registros: ${_orders.length}');
      } else {
        _error = 'Error al cargar tus pedidos';
      }
    } catch (e) {
      print('❌ [OrderProvider] Fallo en loadMine: $e');
      _error = 'Error de conexión: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Actualizar Status de Pedidos (Flujo por Roles) ────────────────
  Future<bool> updateStatus(int idPedido, String nuevoEstado, int idRol) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('🌐 [POS-DEBUG] Enviando a pedido_actualizar.php -> id_pedido: $idPedido, nuevo_estado: "$nuevoEstado", id_rol: $idRol');
      final response = await http.post(
        Uri.parse('$_baseUrl/pedido_actualizar.php'),
        body: {
          'id_pedido': idPedido.toString(),
          'nuevo_estado': nuevoEstado,
          'id_rol': idRol.toString(), 
        },
      );

      _loading = false;
      print('📥 [POS-DEBUG] Respuesta cruda del servidor: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          await loadAll();
          return true;
        } else {
          print('❌ [POS-DEBUG] El servidor rechazó el cambio: ${data['message']}');
          _error = data['message'] ?? 'Error al actualizar';
          _loading = false;
          notifyListeners();
          return false;
        }
      }
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Error de conexión: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Cancelar Pedido (Universal) ───────────────────────────────────
  Future<bool> cancel(int id, {String? motivo, required int idRol}) async {
    return updateStatus(id, 'Cancelado', idRol);
  }

  // ── Crear pedido desde Carrito (Modo Demo de la App) ──────────────
  // 👉 CORREGIDO: Adaptado al constructor limpio del nuevo OrderModel
  // Cambiamos los parámetros: Ahora solo necesitamos recibir el ID del usuario conectado
  Future<bool> createFromCart({required int idUsuario}) async {
    _loading = true;
    _error = null;
    
    
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pedido_crear.php'),
        body: {
          'id_usuario': idUsuario.toString(), // 👉 Mandamos el ID al backend PHP
        },
      );

      _loading = false;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          
          // 🔥 Capturamos el folio real enviado por pedido_crear.php
          _lastFolio = data['folio'].toString(); 
          
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Error de conexión: $e';
      notifyListeners();
      return false;
    }
  }
}