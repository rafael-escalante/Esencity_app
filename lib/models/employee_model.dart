import 'package:equatable/equatable.dart';

// ── Empleado ──────────────────────────────────────────────────────
class EmployeeModel extends Equatable {
  final int id;
  final String nombre;
  final String rfc;
  final String email;
  final String puesto;  // Convertiremos el id_rol a texto
  final String estado;
  final String tel;
  final DateTime? fechaRegistro;

  const EmployeeModel({
    required this.id, required this.nombre, required this.rfc,
    required this.email, required this.puesto, required this.estado,
    required this.tel,
    this.fechaRegistro,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) {
    // Mapeo inverso: de ID numérico a nombre de puesto para tu UI
    String determinarPuesto(dynamic idRol) {
      final id = int.tryParse(idRol.toString()) ?? 2;
      if (id == 1) return 'gerente';
      if (id == 2) return 'cajero';
      if (id == 3) return 'almacenista';
      return 'cliente';
    }

    return EmployeeModel(
      // MySQL devuelve 'id_usuario' y PHP lo manda como String, hay que parsear
      id: int.parse(j['id_usuario'].toString()), 
      nombre: j['nombre'] ?? '',
      rfc: j['rfc'] ?? 'SIN RFC', // Manejo de NULLs de tu DB
      email: j['email'] ?? '',
      // Convertimos el 'id_rol' de la DB al String 'puesto' que usa tu UI
      puesto: determinarPuesto(j['id_rol']), 
      estado: j['estado'] ?? 'activo',
      tel: j['tel'] ?? '',
      // En tu DB la columna se llama 'fecha_reg'
      fechaRegistro: j['fecha_reg'] != null
          ? DateTime.tryParse(j['fecha_reg'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre, 
    'rfc': rfc, 
    'email': email, 
    'puesto': puesto,
    'estado': estado,
    
  };

  @override
  List<Object?> get props => [id, nombre, tel, rfc, email, puesto, estado];
}