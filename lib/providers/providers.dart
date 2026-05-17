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
  Future<bool> register({
    required String nombre, required String email,
    required String password, String? telefono,
  }) async {
    _loading = true; _error = null; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _user = UserModel(id: 99, nombre: nombre, email: email, rol: 'cliente', telefono: telefono, idRol: 4);
    _loading = false; notifyListeners();
    return true;
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

class ProductProvider extends ChangeNotifier {
  // 1. TU NUEVA URL DE NGROK (Asegúrate de que el túnel esté abierto)
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';

  List<ProductModel> _products = [];
  bool _loading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  // --- MÉTODO LOAD ---
  Future<void> load({String? categoria, String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      var uri = Uri.parse('$_baseUrl/productos_leer.php');
      final qp = <String, String>{};
      if (categoria != null && categoria != 'Todos') qp['categoria'] = categoria;
      if (search != null && search.isNotEmpty) qp['search'] = search;
      if (qp.isNotEmpty) uri = uri.replace(queryParameters: qp);

      final response = await http.get(uri, headers: {'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Esta línea es la que permite que ngrok entregue el JSON sin bloqueos
      'ngrok-skip-browser-warning': 'true',});

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        
        // Manejo flexible: por si el PHP devuelve la lista directo o en un campo 'data'
        if (body is Map && body['status'] == 'success') {
          final lista = body['data'] as List;
          _products = lista.map((item) => ProductModel.fromJson(item)).toList();
        } else if (body is List) {
          _products = body.map((item) => ProductModel.fromJson(item)).toList();
        }
      } else {
        _error = 'Error HTTP ${response.statusCode}';
      }
    } catch (e) {
  _error = 'Error de conexión: $e';
  print("❌ ERROR EN LOAD: $e"); // ESTO ES VITAL
} finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- MÉTODO CREATE ---
  Future<bool> create(Map<String, dynamic> data, dynamic imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/productos_operaciones.php'));
      
      // 👉 AQUÍ AGREGAMOS EL HEADER DE NGROK
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });

      request.fields['accion'] = 'crear';

      final String categoriaNombre = data['categoria']?.toString() ?? '';
      request.fields['id_categoria'] = _getIdCategoria(categoriaNombre).toString();

      data.remove('categoria');
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (imageFile != null) {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: imageFile.name ?? 'perfume.jpg'));
        } else if (imageFile.path != null) {
          request.files.add(await http.MultipartFile.fromPath('imagen', imageFile.path));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.body.contains('success')) {
        await load(); // Recarga automática para ver el nuevo producto
        return true;
      }
      // Si falla, puedes imprimir response.body aquí temporalmente para ver qué error devuelve PHP
      print("Error del servidor: ${response.body}"); 
      return false;
    } catch (e) {
      print("Error de conexión: $e");
      return false;
    }
  }
  // --- MÉTODO UPDATE (Centralizado en productos_operaciones.php) ---
  Future<bool> update(int id, Map<String, dynamic> data, [XFile? image]) async {
  try {
    // Usamos MultipartRequest para poder enviar archivos, igual que en el create
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/productos_operaciones.php'));

    // Configuración para saltar ngrok
    request.headers.addAll({
      'ngrok-skip-browser-warning': 'true',
    });

    // Añadimos los datos de texto
    request.fields['accion'] = 'editar';
    request.fields['id'] = id.toString();
    
    // Convertimos todos los valores del mapa a String para que HTTP los acepte
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // 👉 2. Si el usuario seleccionó una imagen nueva, la agregamos a la petición
    if (image != null) {
      // Para Flutter Web es mejor leer los bytes
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'imagen',
        bytes,
        filename: image.name,
      ));
    }

    // Enviamos la petición
    var response = await request.send();

    final respuestaReal = await response.stream.bytesToString();
    print("=== ESTATUS: ${response.statusCode} ===");
    print("=== RESPUESTA DE PHP: $respuestaReal ===");

    if (response.statusCode == 200) {
      // Si todo sale bien, recargamos la lista
      await load();
      return true;
    }
    return false;
  } catch (e) {
    print('Error en update: $e');
    return false;
  }
}

  // --- MÉTODO DELETE (Centralizado en productos_operaciones.php) ---
  Future<bool> delete(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/productos_operaciones.php'),
        body: {
          'accion': 'eliminar',
          'id': id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          await load();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- HELPER DE CATEGORÍAS ---
  int _getIdCategoria(String nombre) {
    switch (nombre) {
      case 'Unisex': return 1;
      case 'Hombre': return 4;
      case 'Mujer':  return 5;
      default: return 1;
    }
  }
}

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
      final response = await http.post(
        Uri.parse('$_baseUrl/pedido_actualizar.php'),
        body: {
          'id_pedido': idPedido.toString(),
          'nuevo_estado': nuevoEstado,
          'id_rol': idRol.toString(), 
        },
      );

      _loading = false;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          await loadAll();
          return true;
        } else {
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

// ── EmployeeProvider ──────────────────────────────────────────────
class EmployeeProvider extends ChangeNotifier {
  List<EmployeeModel> _employees = [];
  bool _loading = false;
  
  // 👉 Cambia esto por tu URL actual de ngrok
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';

  List<EmployeeModel> get employees => _employees;
  bool get loading => _loading;

  // Mapeo de puestos a id_rol según tu DB
  final Map<String, int> _rolesMapping = {
    'gerente': 1,
    'cajero': 2,
    'almacenista': 3,
  };

  // LEER DE LA DB
  // LEER DE LA DB (Unificado)
  Future<void> load({String? search}) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios_gestion.php'),
        headers: {'ngrok-skip-browser-warning': 'true'},
        body: {
          'accion': 'leer', // El PHP ya sabe que debe traer roles 2 y 3
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _employees = data.map((e) => EmployeeModel.fromJson(e)).toList();
        
        // El filtrado por búsqueda (nombre o email) sigue funcionando igual
        if (search != null && search.isNotEmpty) {
          _employees = _employees.where((e) =>
            e.nombre.toLowerCase().contains(search.toLowerCase()) ||
            e.email.toLowerCase().contains(search.toLowerCase())).toList();
        }
      }
    } catch (e) {
      debugPrint("Error loading employees: $e");
    }

    _loading = false;
    notifyListeners();
  }

  // CREAR O EDITAR EN LA DB
  Future<bool> saveEmployee(Map<String, dynamic> data, {int? id}) async {
    _loading = true;
    notifyListeners();

      final Map<String, int> rolesMapping = {
        'cajero': 2,
        'almacenista': 3,
      };

    // 2. Convierte el texto a minúsculas antes de buscar en el mapa
    String puestoSeleccionado = data['puesto'].toString().toLowerCase().trim();
    int idRol = rolesMapping[puestoSeleccionado] ?? 2; // Si falla, pone 2 (Cajero) por defecto
    print('🔍 MAPA RECIBIDO DESDE EL FORMULARIO: $data');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios_gestion.php'),
        headers: {'ngrok-skip-browser-warning': 'true'},
        body: {
          'accion': 'guardar',
          'id': id?.toString() ?? '', // Si hay ID, PHP hará UPDATE
          'id_rol': idRol.toString(),
          'nombre': data['nombre'],
          'email': data['email'],
          'password': data['password'] ?? data['contrasena'] ?? data['contraseña'] ?? '123456',
          'rfc': data['rfc'] ?? '',
          'tel': data['tel'] ?? '',
          'estado': data['estado'] ?? 'activo',
        },
      );

      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        await load(); // Recarga la lista completa unificada
        return true;
      }
    } catch (e) {
      debugPrint("Error saving employee: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }
}