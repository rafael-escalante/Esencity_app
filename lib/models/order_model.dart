import 'package:equatable/equatable.dart';

// ── Ítem de pedido (Renglón de cada perfume) ──────────────────────
class OrderItemModel extends Equatable {
  final int id;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  const OrderItemModel({
    required this.id, 
    required this.productoId, 
    required this.nombreProducto,
    required this.cantidad, 
    required this.precioUnitario,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    id:             j['id'] as int? ?? 0,
    productoId:     j['productoId'] as int? ?? 0,
    nombreProducto: j['nombreProducto'] as String? ?? 'Perfume',
    cantidad:       j['cantidad'] as int? ?? 0,
    precioUnitario: (j['precioUnitario'] as num? ?? 0.0).toDouble(), // Evita crasheos si viene entero de la BD
  );

  double get subtotal => cantidad * precioUnitario;
  

  @override
  List<Object?> get props => [id, productoId, cantidad];
}


// ── Pedido General (Cabecera) ─────────────────────────────────────
class OrderModel extends Equatable {
  final int id;
  final int idUsuario;
  final String clienteNombre;
  final DateTime fecha;
  final double total;
  final String status;
  final String referencia; // Equivale al Folio único de recolección
  final List<OrderItemModel> items; // 👉 CORREGIDO: Ahora sí está en el constructor

  // Campos de acceso rápido para tu UI (Toman el valor del primer perfume de la lista)
  int get productoId => items.isNotEmpty ? items.first.productoId : 0;
  String get nombreProducto => items.isNotEmpty ? items.first.nombreProducto : 'Sin productos';
  int get cantidad => items.isNotEmpty ? items.first.cantidad : 0;
  double get precioUnitario => items.isNotEmpty ? items.first.precioUnitario : 0.0;
  String? get metodoPago => 'Transferencia';

  const OrderModel({
    required this.id, 
    required this.idUsuario, 
    required this.clienteNombre, 
    required this.fecha, 
    required this.total,
    required this.status, 
    required this.referencia,
    required this.items, // 👉 Incluido obligatoriamente
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    // Parseamos primero la lista de ítems de perfumes de este pedido
    final listaItems = (j['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id:            j['id'] as int? ?? 0,
      idUsuario:     j['idUsuario'] as int? ?? 0,
      clienteNombre: j['clienteNombre'] as String? ?? 'Desconocido',
      // 👉 CORREGIDO: Conversión de String a DateTime segura
      fecha:         j['fecha'] != null ? DateTime.parse(j['fecha'] as String) : DateTime.now(),
      // 👉 CORREGIDO: Cast dinámico a double para evitar fallas numéricas
      total:         (j['total'] as num? ?? 0.0).toDouble(),
      // 👉 CORREGIDO: Apunta a la clave de estatus correcta y no al total
      status:        j['status'] as String? ?? 'Pendiente',
      referencia:    j['referencia'] as String? ?? '',
      items:         listaItems,
    );
  }

  bool get canCancel => status == 'pendiente' || status == 'Pendiente';
  

  @override
  List<Object?> get props => [id, status, total, items];
}