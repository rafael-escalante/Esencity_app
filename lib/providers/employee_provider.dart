import 'package:http/http.dart' as http; // Corrige el error de 'http'
import 'dart:convert';               // Corrige el error de 'jsonEncode' y 'json.decode'
import 'package:flutter/material.dart';
import 'package:parfum/models/employee_model.dart';

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