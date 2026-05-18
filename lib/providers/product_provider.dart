import 'package:http/http.dart' as http; // Corrige el error de 'http'
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';               // Corrige el error de 'jsonEncode' y 'json.decode'
import 'package:flutter/material.dart';
import 'package:parfum/models/product_model.dart';
import 'package:image_picker/image_picker.dart';


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
