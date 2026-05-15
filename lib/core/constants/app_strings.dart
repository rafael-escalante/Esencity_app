class AppStrings {
  AppStrings._();
  static const String appName     = 'PARFUM';
  static const String tagline     = 'Sistema de Gestión';

  // Auth
  static const String email       = 'Correo Electrónico';
  static const String password    = 'Contraseña';
  static const String login       = 'Entrar';
  static const String register    = 'Registrarse';
  static const String forgotPw    = '¿Olvidaste tu contraseña?';
  static const String badCreds    = 'Correo o contraseña incorrectos. Intenta de nuevo.';

  // Roles
  static const String rolGerente      = 'gerente';
  static const String rolCajero       = 'cajero';
  static const String rolAlmacenista  = 'almacenista';
  static const String rolCliente      = 'cliente';

  // Status pedido
  static const String statusPendiente = 'Pendiente';
  static const String statusPagado    = 'Pagado';
  static const String statusListo     = 'Listo para entrega';
  static const String statusFinalizado= 'Finalizado';
  static const String statusCancelado = 'Cancelado';

  static const List<String> statusOptions = [
    statusPendiente, statusPagado, statusListo, statusFinalizado, statusCancelado,
  ];

  // Categorías
  static const List<String> categorias = ['Todos', 'Hombre', 'Mujer', 'Unisex'];
  static const List<String> concentraciones = ['EDP', 'EDT', 'EDC'];
  static const List<String> metodosPago = ['Efectivo', 'Transferencia'];
}
