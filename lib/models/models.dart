import 'package:equatable/equatable.dart';



// ── Ítem de pedido ────────────────────────────────────────────────
class OrderItemModel extends Equatable {
  final int id;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  const OrderItemModel({
    required this.id, required this.productoId, required this.nombreProducto,
    required this.cantidad, required this.precioUnitario,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    id:              j['id'] as int,
    productoId:      j['producto_id'] as int,
    nombreProducto:  j['nombre_producto'] as String,
    cantidad:        j['cantidad'] as int,
    precioUnitario:  (j['precio_unitario'] as num).toDouble(),
  );

  double get subtotal => cantidad * precioUnitario;

  @override
  List<Object?> get props => [id, productoId, cantidad];
}

// ── Pedido ────────────────────────────────────────────────────────
class OrderModel extends Equatable {
  final int id;
  final String clienteNombre;
  final DateTime fecha;
  final double total;
  final String status;
  final String? metodoPago;
  final String? referencia;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id, required this.clienteNombre, required this.fecha,
    required this.total, required this.status, this.metodoPago,
    this.referencia, this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id:             j['id'] as int,
    clienteNombre:  j['cliente_nombre'] as String,
    fecha:          DateTime.parse(j['fecha'] as String),
    total:          (j['total'] as num).toDouble(),
    status:         j['status'] as String,
    metodoPago:     j['metodo_pago'] as String?,
    referencia:     j['referencia'] as String?,
    items:          (j['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  bool get canCancel => status == 'Pendiente';

  @override
  List<Object?> get props => [id, status, total];
}

// ── Ítem del carrito (local) ──────────────────────────────────────
class CartItemModel extends Equatable {
  final int productoId;
  final String nombre;
  final String descripcion;
  final double precio;
  int cantidad;

  CartItemModel({
    required this.productoId, required this.nombre,
    required this.descripcion, required this.precio, this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;

  CartItemModel copyWith({int? cantidad}) => CartItemModel(
    productoId: productoId, nombre: nombre, descripcion: descripcion,
    precio: precio, cantidad: cantidad ?? this.cantidad,
  );

  Map<String, dynamic> toJson() => {
    'producto_id': productoId, 'cantidad': cantidad,
  };

  @override
  List<Object?> get props => [productoId, cantidad];
}

// ── Venta (caja física) ───────────────────────────────────────────
class SaleItemModel {
  final int productoId;
  final String nombre;
  final String sku;
  final double precio;
  int cantidad;

  SaleItemModel({
    required this.productoId, required this.nombre,
    required this.sku, required this.precio, this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}

class SaleModel extends Equatable {
  final int id;
  final String cajeroNombre;
  final DateTime fecha;
  final double subtotal;
  final double iva;
  final double total;
  final String metodoPago;
  final double montoRecibido;
  final double cambio;

  const SaleModel({
    required this.id, required this.cajeroNombre, required this.fecha,
    required this.subtotal, required this.iva, required this.total,
    required this.metodoPago, required this.montoRecibido, required this.cambio,
  });

  factory SaleModel.fromJson(Map<String, dynamic> j) => SaleModel(
    id:             j['id'] as int,
    cajeroNombre:   j['cajero_nombre'] as String,
    fecha:          DateTime.parse(j['fecha'] as String),
    subtotal:       (j['subtotal'] as num).toDouble(),
    iva:            (j['iva'] as num).toDouble(),
    total:          (j['total'] as num).toDouble(),
    metodoPago:     j['metodo_pago'] as String,
    montoRecibido:  (j['monto_recibido'] as num).toDouble(),
    cambio:         (j['cambio'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [id, total, fecha];
}

// ── Reporte ────────────────────────────────────────────────────────
class ReportModel {
  final double totalVentas;
  final int totalTransacciones;
  final String productoMasVendido;
  final int unidadesProductoTop;
  final String categoriaLider;
  final double porcentajeCategoriaLider;
  final List<ReportPeriodModel> porPeriodo;
  final List<ReportDetailModel> detalle;

  const ReportModel({
    required this.totalVentas, required this.totalTransacciones,
    required this.productoMasVendido, required this.unidadesProductoTop,
    required this.categoriaLider, required this.porcentajeCategoriaLider,
    required this.porPeriodo, required this.detalle,
  });

  factory ReportModel.fromJson(Map<String, dynamic> j) => ReportModel(
    totalVentas:              (j['total_ventas'] as num).toDouble(),
    totalTransacciones:       j['total_transacciones'] as int,
    productoMasVendido:       j['producto_mas_vendido'] as String,
    unidadesProductoTop:      j['unidades_producto_top'] as int,
    categoriaLider:           j['categoria_lider'] as String,
    porcentajeCategoriaLider: (j['porcentaje_categoria'] as num).toDouble(),
    porPeriodo:               (j['por_periodo'] as List<dynamic>)
        .map((e) => ReportPeriodModel.fromJson(e as Map<String, dynamic>)).toList(),
    detalle:                  (j['detalle'] as List<dynamic>)
        .map((e) => ReportDetailModel.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class ReportPeriodModel {
  final String periodo;
  final double total;
  const ReportPeriodModel({required this.periodo, required this.total});
  factory ReportPeriodModel.fromJson(Map<String, dynamic> j) =>
      ReportPeriodModel(periodo: j['periodo'] as String, total: (j['total'] as num).toDouble());
}

class ReportDetailModel {
  final String fecha;
  final String cajero;
  final String producto;
  final int cantidad;
  final double total;
  final String metodoPago;

  const ReportDetailModel({
    required this.fecha, required this.cajero, required this.producto,
    required this.cantidad, required this.total, required this.metodoPago,
  });

  factory ReportDetailModel.fromJson(Map<String, dynamic> j) => ReportDetailModel(
    fecha:      j['fecha'] as String,
    cajero:     j['cajero'] as String,
    producto:   j['producto'] as String,
    cantidad:   j['cantidad'] as int,
    total:      (j['total'] as num).toDouble(),
    metodoPago: j['metodo_pago'] as String,
  );
}
