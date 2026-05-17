import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String nombre;
  final String email;
  final String rol;    // String original: gerente | cajero | almacenista | cliente
  final int idRol;     // INT de MySQL: 1 | 2 | 3 | 4
  final String? telefono;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.idRol, // 👉 Parámetro numérico incorporado
    this.telefono,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    // Protección por si MySQL regresa el id_rol como String o como int
    final rawIdRol = j['id_rol'] ?? j['idRol'] ?? 0;
    final parsedIdRol = rawIdRol is int ? rawIdRol : int.parse(rawIdRol.toString());

    return UserModel(
      id:       j['id'] as int,
      nombre:   j['nombre'] as String,
      email:    j['email'] as String,
      rol:      j['rol'] as String,
      idRol:    parsedIdRol, // 👉 Mapeado directo desde MySQL
      telefono: j['telefono'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 
    'nombre': nombre, 
    'email': email,
    'rol': rol, 
    'id_rol': idRol, // 👉 Mapeado para que PHP lo entienda
    'telefono': telefono,
  };

  UserModel copyWith({
    String? nombre, 
    String? email, 
    String? rol,
    int? idRol,
    String? telefono
  }) => UserModel(
    id: id, 
    nombre: nombre ?? this.nombre,
    email: email ?? this.email, 
    rol: rol ?? this.rol,
    idRol: idRol ?? this.idRol, // 👉 Copia del ID rol asignado
    telefono: telefono ?? this.telefono
  );

  @override
  List<Object?> get props => [id, nombre, email, rol, idRol, telefono];
}