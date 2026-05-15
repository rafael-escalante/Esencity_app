import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final int id;
  final String sku;
  final String nombre;
  final String descripcion;
  final String marca;
  final String categoria;      // Hombre | Mujer | Unisex
  final String concentracion;  // EDP | EDT | EDC
  final int ml;
  final double precio;
  final int stock;
  final String estado;         // disponible | bajo_stock | sin_stock | inactivo
  final String? imagenUrl;
  final DateTime? fechaRegistro;

  const ProductModel({
    required this.id,
    required this.sku,
    required this.nombre,
    required this.descripcion,
    required this.marca,
    required this.categoria,
    required this.concentracion,
    required this.ml,
    required this.precio,
    required this.stock,
    required this.estado,
    this.imagenUrl,
    this.fechaRegistro,
  });

  // ── fromJson ────────────────────────────────
  // Claves esperadas del PHP:
  //   id_producto, sku, nombre, marca, descripcion,
  //   cat_nom, con_nom, mililitros,
  //   precio, stock, estado, imagen, fecha_registro
  factory ProductModel.fromJson(Map<String, dynamic> j) {
  // 1. Usamos tu URL de ngrok para las imágenes locales
  const String baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';

  String? imgUrl;
  if (j['imagen_url'] != null && j['imagen_url'].toString().isNotEmpty) {
    imgUrl = j['imagen_url'].toString();
  } else if (j['imagen'] != null &&
             j['imagen'].toString().isNotEmpty &&
             j['imagen'].toString() != 'default.png') {
    imgUrl = '$baseUrl/uploads/${j['imagen']}';
  } else {
    // Imagen por defecto si no hay nada en la BD
    imgUrl = '$baseUrl/uploads/default.png';
  }

  return ProductModel(
    // Usamos tryParse para evitar que la app truene si el dato viene mal
    id: int.tryParse(j['id_producto']?.toString() ?? '0') ?? 0,
    sku: j['sku']?.toString() ?? j['id_producto']?.toString() ?? '0',
    nombre: j['nombre']?.toString() ?? '',
    descripcion: j['descripcion']?.toString() ?? '',
    marca: j['marca']?.toString() ?? '',
    // Priorizamos los alias que vienen del JOIN en tu PHP (cat_nom y con_nom)
    categoria: j['cat_nom']?.toString() ?? j['categoria']?.toString() ?? 'General',
    concentracion: j['con_nom']?.toString() ?? j['concentracion']?.toString() ?? 'EDP',
    ml: int.tryParse((j['mililitros'] ?? j['ml'] ?? '0').toString()) ?? 0,
    precio: double.tryParse((j['precio'] ?? '0.0').toString()) ?? 0.0,
    stock: int.tryParse((j['stock'] ?? '0').toString()) ?? 0,
    estado: j['estado']?.toString() ?? 'disponible',
    imagenUrl: imgUrl,
    fechaRegistro: j['fecha_registro'] != null
        ? DateTime.tryParse(j['fecha_registro'].toString())
        : null,
  );
}

  // ── toJson (para enviar a PHP en crear/editar) ──
  Map<String, dynamic> toJson() => {
    'sku':          sku,
    'nombre':       nombre,
    'descripcion':  descripcion,
    'marca':        marca,
    'categoria':    categoria,
    'concentracion':concentracion,
    'ml':           ml,
    'precio':       precio,
    'stock':        stock,
    'estado':       estado,
  };

  // ── copyWith (útil en formularios de edición) ──
  ProductModel copyWith({
    int?      id,
    String?   sku,
    String?   nombre,
    String?   descripcion,
    String?   marca,
    String?   categoria,
    String?   concentracion,
    int?      ml,
    double?   precio,
    int?      stock,
    String?   estado,
    String?   imagenUrl,
    DateTime? fechaRegistro,
  }) => ProductModel(
    id:             id            ?? this.id,
    sku:            sku           ?? this.sku,
    nombre:         nombre        ?? this.nombre,
    descripcion:    descripcion   ?? this.descripcion,
    marca:          marca         ?? this.marca,
    categoria:      categoria     ?? this.categoria,
    concentracion:  concentracion ?? this.concentracion,
    ml:             ml            ?? this.ml,
    precio:         precio        ?? this.precio,
    stock:          stock         ?? this.stock,
    estado:         estado        ?? this.estado,
    imagenUrl:      imagenUrl     ?? this.imagenUrl,
    fechaRegistro:  fechaRegistro ?? this.fechaRegistro,
  );

  // ── Getters de utilidad ─────────────────────
  String get estadoBadge {
    switch (estado) {
      case 'bajo_stock': return 'Bajo Stock';
      case 'sin_stock':  return 'Sin Stock';
      case 'inactivo':   return 'Inactivo';
      default:           return 'Disponible';
    }
  }

  // Color sugerido para el badge (usa con ColoredBox o Chip)
  int get estadoColor {
    switch (estado) {
      case 'bajo_stock': return 0xFFFFA726; // naranja
      case 'sin_stock':  return 0xFFE53935; // rojo
      case 'inactivo':   return 0xFF9E9E9E; // gris
      default:           return 0xFF43A047; // verde
    }
  }

  bool get isAvailable => stock > 0 && estado != 'inactivo';

  String get precioFormateado =>
      '\$${precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      )}';

  @override
  List<Object?> get props => [id, sku, stock, estado, precio];
}
