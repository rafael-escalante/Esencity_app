import 'package:http/http.dart' as http; // Corrige el error de 'http'
import 'dart:convert';               // Corrige el error de 'jsonEncode' y 'json.decode'
import 'package:flutter/material.dart';


// ── CartProvider ──────────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter'; 
  final Map<int, dynamic> _items = {};
  int? _idUsuario;
  bool _loading = false;

  // GETTERS PÚBLICOS
  Map<int, dynamic> get items => {..._items};
  int get itemCount => _items.length;
  bool get loading => _loading;

  // 💵 CÁLCULOS FINANCIEROS DICTAMINADOS
  double get subtotal {
    double sum = 0.0;
    _items.forEach((key, item) {
      final double precio = double.parse(item['precio'].toString());
      final int cantidad = int.parse(item['cantidad'].toString());
      sum += precio * cantidad;
    });
    return sum;
  }

  double get iva => subtotal * 0.16;
  double get total => subtotal + iva;

  // 🔐 ENLAZAR EL USUARIO DESDE EL LOGIN REAL
  void registrarUsuario(int idUsuario) {
    _idUsuario = idUsuario;
    _items.clear(); // Limpia residuos de sesiones previas
    load();         // Jala automáticamente el carrito real de este usuario en MySQL
  }

  // 📥 LEER EL CARRITO DE MYSQL (INNER JOIN REALIZADO)
  Future<void> load() async {
    if (_idUsuario == null) return; 

    _loading = true; 
    notifyListeners(); 

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/carrito_obtener.php?id_usuario=$_idUsuario'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['items'] != null) {
          _items.clear(); 
          for (var item in data['items']) {
            final int idProd = int.parse(item['id_producto'].toString());
            _items[idProd] = {
              'id_producto': idProd, // Guardamos con el nombre real de tu columna
              'nombre': item['nombre'],
              'precio': double.parse(item['precio'].toString()),
              'cantidad': int.parse(item['cantidad'].toString()),
              'imagen': item['imagen'] ?? '',
            };
          }
        }
      }
    } catch (e) {
      print('Error de conexión al cargar carrito: $e');
    } finally {
      _loading = false;
      notifyListeners(); 
    }
  }

  // 🔥 AGREGAR AL CARRITO CON CONEXIÓN EN TIEMPO REAL
  Future<void> addProduct(dynamic product, int cantidad) async {
    
    // 📡 RADAR 1: Ver si el botón de la pantalla realmente llama al Provider
    print('🛒 [CartProvider] ¡El botón de la UI sí llamó a addProduct!');
    print('👤 [CartProvider] id_usuario en el Provider: $_idUsuario');

    if (_idUsuario == null) {
      print("⚠️ [CartProvider] ABORTADO: id_usuario es NULL. (Tip: Si hiciste Hot Restart, vuelve a pasar por el Login para registrar al usuario).");
      return;
    }

    // 📡 RADAR 2: Ver qué ID está detectando del perfume
    final int idProd = product.id;
    print('🆔 [CartProvider] ID del producto detectado: $idProd');
    
    if (idProd == 0) {
      print("⚠️ [CartProvider] ABORTADO: El ID del producto es 0 o NULL. Revisa cómo se llama la propiedad en tu modelo de catálogo.");
      return;
    }

    // 1. Modificación en la memoria RAM (UI veloz)
    if (_items.containsKey(idProd)) {
      _items.update(idProd, (existing) => {
        ...existing,
        'cantidad': existing['cantidad'] + cantidad,
      });
    } else {
      _items[idProd] = {
        'id_producto': idProd,
        'nombre': product.nombre,
        'precio': double.parse(product.precio.toString()),
        'cantidad': cantidad,
        'imagen': '',
      };
    }
    notifyListeners();
    print('📥 [CartProvider] Guardado en RAM con éxito. Items actuales: ${_items.length}');

    // 2. Envío transaccional a MySQL
    try {
      print('🌐 [CartProvider] Enviando datos por POST a carrito_agregar.php...');
      final response = await http.post(
        Uri.parse('$_baseUrl/gestion_carrito.php'),
        body: {
          'id_usuario': _idUsuario.toString(),
          'id_producto': idProd.toString(),
          'cantidad': cantidad.toString(),
        },
      );
      
      // 📡 RADAR 3: Ver qué dice tu base de datos
      print('📡 [CartProvider] Respuesta cruda de MySQL: ${response.body}');
      
    } catch (e) {
      print('❌ [CartProvider] Error de red al conectar con PHP: $e');
    }
  }

  // ── 🔄 ACTUALIZAR CANTIDAD DESDE EL CARRITO (Botones + y -) ──
  Future<void> updateQty(int idProducto, int nuevaCantidad) async {
    if (!_items.containsKey(idProducto)) return;

    if (nuevaCantidad <= 0) {
      await remove(idProducto);
      return;
    }

    _items[idProducto]['cantidad'] = nuevaCantidad;
    notifyListeners(); 

    // Sincronizamos el cambio absoluto con la base de datos
    try {
      await http.post(
        Uri.parse('$_baseUrl/carrito_actualizar.php'),
        body: {
          'id_usuario': _idUsuario.toString(),
          'id_producto': idProducto.toString(),
          'cantidad': nuevaCantidad.toString(),
        },
      );
    } catch (e) {
      print('Error al actualizar cantidad en la BD: $e');
    }
  }

  // ── 🗑️ ELIMINAR UN PRODUCTO INDIVIDUAL (Botón X) ──
  Future<void> remove(int idProducto) async {
    _items.remove(idProducto);
    notifyListeners(); 

    try {
      await http.post(
        Uri.parse('$_baseUrl/carrito_eliminar.php'),
        body: {
          'id_usuario': _idUsuario.toString(),
          'id_producto': idProducto.toString(),
        },
      );
    } catch (e) {
      print('Error al eliminar producto de la BD: $e');
    }
  }

  Future<void> clear() async {
    _items.clear();    
    notifyListeners(); 
  }
}