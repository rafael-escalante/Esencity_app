import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String nombre;
  final String email;
  final String rol; // gerente | cajero | almacenista | cliente
  final String? telefono;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:       j['id'] as int,
    nombre:   j['nombre'] as String,
    email:    j['email'] as String,
    rol:      j['rol'] as String,
    telefono: j['telefono'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'email': email,
    'rol': rol, 'telefono': telefono,
  };

  UserModel copyWith({String? nombre, String? email, String? telefono}) =>
      UserModel(id: id, nombre: nombre ?? this.nombre,
        email: email ?? this.email, rol: rol, telefono: telefono ?? this.telefono);

  @override
  List<Object?> get props => [id, nombre, email, rol, telefono];
}
