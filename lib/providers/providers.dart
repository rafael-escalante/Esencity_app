import 'package:http/http.dart' as http; // Corrige el error de 'http'
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';               // Corrige el error de 'jsonEncode' y 'json.decode'
import 'package:flutter/material.dart';
import 'package:parfum/models/employee_model.dart';
import 'package:parfum/models/user_model.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/models/models.dart';
import 'package:image_picker/image_picker.dart';

// ══════════════════════════════════════════════════════════════════
//  MODO DEMO — sin backend real
//  Credenciales:
//    gerente@parfum.mx   / cualquier contraseña
//    cajero@parfum.mx    / cualquier contraseña
//    almacen@parfum.mx   / cualquier contraseña
//    cliente@parfum.mx   / cualquier contraseña  (o cualquier otro email)
// ══════════════════════════════════════════════════════════════════

// ── Datos demo ────────────────────────────────────────────────────
class _DemoData {
  static final users = {
    'gerente@parfum.mx': const UserModel(id: 1, nombre: 'Ana García López', email: 'gerente@parfum.mx',  rol: 'gerente'),
    'cajero@parfum.mx':  const UserModel(id: 2, nombre: 'Carlos Martínez',  email: 'cajero@parfum.mx',   rol: 'cajero'),
    'almacen@parfum.mx': const UserModel(id: 3, nombre: 'María Rodríguez',  email: 'almacen@parfum.mx',  rol: 'almacenista'),
    'cliente@parfum.mx': const UserModel(id: 4, nombre: 'Luis Hernández',   email: 'cliente@parfum.mx',  rol: 'cliente'),
  };

  // products eliminado — los productos vienen del backend (ProductProvider.load())

  static final employees = [
    const EmployeeModel(id: 2, nombre: 'Carlos Martínez', rfc: 'MACC900101ABC', email: 'cajero@parfum.mx',  puesto: 'cajero', tel: '9945258463',      estado: 'activo'),
    const EmployeeModel(id: 3, nombre: 'María Rodríguez', rfc: 'RORM850215XYZ', email: 'almacen@parfum.mx', puesto: 'almacenista',tel: '9945258463', estado: 'activo'),
    const EmployeeModel(id: 5, nombre: 'Pedro Sánchez',   rfc: 'SAPP780304DEF', email: 'pedro@parfum.mx',   puesto: 'cajero',tel: '9945258463',      estado: 'inactivo'),
  ];

  static final orders = [
    OrderModel(
      id: 1001, clienteNombre: 'Luis Hernández',
      fecha: DateTime.now().subtract(const Duration(days: 2)),
      total: 5300, status: 'Pendiente', metodoPago: 'Transferencia', referencia: 'REF-001',
      items: const [
        OrderItemModel(id: 1, productoId: 1, nombreProducto: 'Chanel No. 5',  cantidad: 1, precioUnitario: 3500),
        OrderItemModel(id: 2, productoId: 3, nombreProducto: 'Good Girl',     cantidad: 1, precioUnitario: 1800),
      ],
    ),
    OrderModel(
      id: 1002, clienteNombre: 'Sofía Torres',
      fecha: DateTime.now().subtract(const Duration(days: 5)),
      total: 2800, status: 'Listo para entrega', metodoPago: 'Transferencia', referencia: 'REF-002',
      items: const [
        OrderItemModel(id: 3, productoId: 2, nombreProducto: 'Dior Sauvage', cantidad: 1, precioUnitario: 2800),
      ],
    ),
    OrderModel(
      id: 1003, clienteNombre: 'Roberto Díaz',
      fecha: DateTime.now().subtract(const Duration(days: 10)),
      total: 4600, status: 'Finalizado', metodoPago: 'Transferencia', referencia: 'REF-003',
      items: const [
        OrderItemModel(id: 4, productoId: 4, nombreProducto: 'Bleu de Chanel', cantidad: 1, precioUnitario: 3100),
        OrderItemModel(id: 5, productoId: 6, nombreProducto: 'CK One',         cantidad: 1, precioUnitario: 1200),
      ],
    ),
    OrderModel(
      id: 1004, clienteNombre: 'Luis Hernández',
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      total: 1200, status: 'Pendiente', metodoPago: 'Transferencia', referencia: 'REF-004',
      items: const [
        OrderItemModel(id: 6, productoId: 6, nombreProducto: 'CK One', cantidad: 1, precioUnitario: 1200),
      ],
    ),
  ];
}

// ── AuthProvider ──────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading    => _loading;
  String? get error   => _error;
  String get rol      => _user?.rol ?? '';

  Future<bool> tryAutoLogin() async {
    // En modo demo no hay sesión persistida
    return false;
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600)); // simular red

    final found = _DemoData.users[email.trim().toLowerCase()];
    if (found != null) {
      _user = found;
      _loading = false; notifyListeners();
      return true;
    }
    // Cualquier email no registrado entra como cliente
    if (email.isNotEmpty && password.isNotEmpty) {
      _user = UserModel(id: 99, nombre: email.split('@')[0], email: email, rol: 'cliente');
      _loading = false; notifyListeners();
      return true;
    }
    _error = 'Ingresa un correo y contraseña válidos';
    _loading = false; notifyListeners();
    return false;
  }

  Future<bool> register({
    required String nombre, required String email,
    required String password, String? telefono,
  }) async {
    _loading = true; _error = null; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _user = UserModel(id: 99, nombre: nombre, email: email, rol: 'cliente', telefono: telefono);
    _loading = false; notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _user = null; notifyListeners();
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
  List<CartItemModel> _items = [];
  bool _loading = false;

  List<CartItemModel> get items => _items;
  bool get loading              => _loading;
  int  get itemCount            => _items.fold(0, (s, i) => s + i.cantidad);
  double get subtotal           => _items.fold(0, (s, i) => s + i.subtotal);
  double get iva                => subtotal * 0.16;
  double get total              => subtotal + iva;

  Future<void> load() async { /* demo: carrito vacío al inicio */ }

  Future<void> addProduct(ProductModel p, int qty) async {
    final idx = _items.indexWhere((i) => i.productoId == p.id);
    if (idx >= 0) {
      _items[idx].cantidad += qty;
    } else {
      _items.add(CartItemModel(
        productoId: p.id, nombre: p.nombre,
        descripcion: '${p.concentracion} ${p.ml}ml',
        precio: p.precio, cantidad: qty,
      ));
    }
    notifyListeners();
  }

  Future<void> updateQty(int productoId, int qty) async {
    final idx = _items.indexWhere((i) => i.productoId == productoId);
    if (idx < 0) return;
    if (qty <= 0) { _items.removeAt(idx); }
    else          { _items[idx].cantidad = qty; }
    notifyListeners();
  }

  Future<void> remove(int productoId) async {
    _items.removeWhere((i) => i.productoId == productoId);
    notifyListeners();
  }

  Future<void> clear() async { _items.clear(); notifyListeners(); }
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

// ── OrderProvider ─────────────────────────────────────────────────
class OrderProvider extends ChangeNotifier {
  List<OrderModel> _all    = List.from(_DemoData.orders);
  List<OrderModel> _orders = List.from(_DemoData.orders);
  bool _loading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get loading             => _loading;
  String? get error            => _error;

  Future<void> loadAll({String? status}) async {
    _loading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _orders = status == null
        ? List.from(_all)
        : _all.where((o) => o.status == status).toList();
    _loading = false; notifyListeners();
  }

  Future<void> loadMine() async {
    _loading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    // Mostrar pedidos de Luis Hernández (id 4) como demo del cliente
    _orders = _all.where((o) => o.clienteNombre == 'Luis Hernández').toList();
    _loading = false; notifyListeners();
  }

  Future<bool> updateStatus(int id, String status) async {
    final idx = _all.indexWhere((o) => o.id == id);
    if (idx < 0) return false;
    final old = _all[idx];
    _all[idx] = OrderModel(
      id: old.id, clienteNombre: old.clienteNombre,
      fecha: old.fecha, total: old.total,
      status: status, metodoPago: old.metodoPago,
      referencia: old.referencia, items: old.items,
    );
    await loadAll();
    return true;
  }

  Future<bool> cancel(int id, {String? motivo}) async {
    return updateStatus(id, 'Cancelado');
  }

  Future<OrderModel> createFromCart(List<CartItemModel> cartItems) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final order = OrderModel(
      id: 1000 + _all.length + 1,
      clienteNombre: 'Luis Hernández',
      fecha: DateTime.now(),
      total: cartItems.fold(0.0, (s, i) => s + i.subtotal) * 1.16,
      status: 'Pendiente',
      metodoPago: 'Transferencia',
      referencia: 'REF-DEMO-${DateTime.now().millisecondsSinceEpoch}',
      items: cartItems.map((ci) => OrderItemModel(
        id: _all.length + 1,
        productoId: ci.productoId,
        nombreProducto: ci.nombre,
        cantidad: ci.cantidad,
        precioUnitario: ci.precio,
      )).toList(),
    );
    _all.insert(0, order);
    return order;
  }
}

// ── EmployeeProvider ──────────────────────────────────────────────
class EmployeeProvider extends ChangeNotifier {
  List<EmployeeModel> _employees = [];
  bool _loading = false;
  
  // 👉 Cambia esto por tu URL actual de ngrok
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter/usuarios_gestion.php';

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
        Uri.parse(_baseUrl),
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

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'ngrok-skip-browser-warning': 'true'},
        body: {
          'accion': 'guardar',
          'id': id?.toString() ?? '', // Si hay ID, PHP hará UPDATE
          'id_rol': idRol.toString(),
          'nombre': data['nombre'],
          'email': data['email'],
          'password': data['password'] ?? '123456', // Password por defecto si es nuevo
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