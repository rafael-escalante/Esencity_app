import 'package:dio/dio.dart';
import 'package:parfum/core/network/api_client.dart';
import 'package:parfum/core/constants/api_endpoints.dart';
import 'package:parfum/models/employee_model.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/models/models.dart';

// ── ProductService ────────────────────────────────────────────────
class ProductService {
  final Dio _dio = ApiClient.instance;

  Future<List<ProductModel>> getAll({String? categoria, String? search}) async {
    final params = <String, dynamic>{};
    if (categoria != null && categoria != 'Todos') params['categoria'] = categoria;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _dio.get(ApiEndpoints.products, queryParameters: params);
    return (res.data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> getById(int id) async {
    final res = await _dio.get(ApiEndpoints.productById(id));
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProductModel> getBySku(String sku) async {
    final res = await _dio.get(ApiEndpoints.productBySku(sku));
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProductModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.products, data: data);
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProductModel> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiEndpoints.productById(id), data: data);
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Baja lógica (estado = inactivo)
  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.productById(id));
  }

  /// Subir imagen del producto (multipart)
  Future<String> uploadImage(int id, String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('${ApiEndpoints.productById(id)}/image', data: form);
    return res.data['imagen_url'] as String;
  }
}

// ── EmployeeService ───────────────────────────────────────────────
class EmployeeService {
  final Dio _dio = ApiClient.instance;

  Future<List<EmployeeModel>> getAll({String? search}) async {
    final params = search != null && search.isNotEmpty ? {'search': search} : null;
    final res = await _dio.get(ApiEndpoints.employees, queryParameters: params);
    return (res.data as List).map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EmployeeModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.employees, data: data);
    return EmployeeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<EmployeeModel> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiEndpoints.employeeById(id), data: data);
    return EmployeeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> disable(int id) async {
    await _dio.patch(ApiEndpoints.disableEmployee(id));
  }
}

// ── OrderService ──────────────────────────────────────────────────
class OrderService {
  final Dio _dio = ApiClient.instance;

  /// Todos los pedidos (empleados)
  Future<List<OrderModel>> getAll({String? status}) async {
    final params = status != null && status != 'Todos los status'
        ? {'status': status} : null;
    final res = await _dio.get(ApiEndpoints.orders, queryParameters: params);
    return (res.data as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Solo pedidos del cliente autenticado
  Future<List<OrderModel>> getMyOrders() async {
    final res = await _dio.get(ApiEndpoints.myOrders);
    return (res.data as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getById(int id) async {
    final res = await _dio.get(ApiEndpoints.orderById(id));
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Crear pedido desde carrito (cliente)
  Future<OrderModel> createFromCart({
    required String metodoPago,
    required String referencia,
    required String banco,
  }) async {
    final res = await _dio.post(ApiEndpoints.orders, data: {
      'metodo_pago': metodoPago,
      'referencia': referencia,
      'banco': banco,
    });
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OrderModel> updateStatus(int id, String status) async {
    final res = await _dio.patch(ApiEndpoints.orderStatus(id), data: {'status': status});
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OrderModel> cancel(int id, {String? motivo}) async {
    final res = await _dio.patch(ApiEndpoints.cancelOrder(id), data: {'motivo': motivo});
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }
}

// ── SaleService (caja física — cajero/gerente) ────────────────────
class SaleService {
  final Dio _dio = ApiClient.instance;

  Future<List<SaleModel>> getAll() async {
    final res = await _dio.get(ApiEndpoints.sales);
    return (res.data as List).map((e) => SaleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SaleModel> create({
    required List<Map<String, dynamic>> items, // [{producto_id, cantidad}]
    required String metodoPago,
    required double montoRecibido,
  }) async {
    final res = await _dio.post(ApiEndpoints.sales, data: {
      'items': items,
      'metodo_pago': metodoPago,
      'monto_recibido': montoRecibido,
    });
    return SaleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancel(int id) async {
    await _dio.delete(ApiEndpoints.saleById(id));
  }
}

// ── CartService (carrito del cliente — persistido en API) ─────────
class CartService {
  final Dio _dio = ApiClient.instance;

  Future<List<CartItemModel>> getCart() async {
    final res = await _dio.get(ApiEndpoints.cart);
    return (res.data as List).map((e) {
      final m = e as Map<String, dynamic>;
      return CartItemModel(
        productoId:  m['producto_id'] as int,
        nombre:      m['nombre'] as String,
        descripcion: m['descripcion'] as String? ?? '',
        precio:      (m['precio'] as num).toDouble(),
        cantidad:    m['cantidad'] as int,
      );
    }).toList();
  }

  Future<void> addItem(int productoId, int cantidad) async {
    await _dio.post(ApiEndpoints.cart, data: {'producto_id': productoId, 'cantidad': cantidad});
  }

  Future<void> updateQty(int itemId, int cantidad) async {
    await _dio.put(ApiEndpoints.cartItem(itemId), data: {'cantidad': cantidad});
  }

  Future<void> removeItem(int itemId) async {
    await _dio.delete(ApiEndpoints.cartItem(itemId));
  }

  Future<void> clear() async {
    await _dio.delete(ApiEndpoints.cart);
  }
}

// ── ReportService ─────────────────────────────────────────────────
class ReportService {
  final Dio _dio = ApiClient.instance;

  Future<ReportModel> generate({
    required String fechaInicio,
    required String fechaFin,
    String? categoria,
  }) async {
    final params = <String, dynamic>{
      'fecha_inicio': fechaInicio,
      'fecha_fin':    fechaFin,
    };
    if (categoria != null && categoria != 'Todas las categorías') {
      params['categoria'] = categoria;
    }
    final res = await _dio.get(ApiEndpoints.reports, queryParameters: params);
    return ReportModel.fromJson(res.data as Map<String, dynamic>);
  }
}
