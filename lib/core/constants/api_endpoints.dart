class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────
  static const String login        = '/auth/login';
  static const String register     = '/auth/register';
  static const String me           = '/auth/me';
  static const String logout       = '/auth/logout';

  // ── Productos ─────────────────────────────────────────────────
  static const String products     = '/products';
  static String productById(int id) => '/products/$id';
  static String productBySku(String sku) => '/products/sku/$sku';

  // ── Empleados ─────────────────────────────────────────────────
  static const String employees    = '/employees';
  static String employeeById(int id) => '/employees/$id';
  static String disableEmployee(int id) => '/employees/$id/disable';

  // ── Pedidos ───────────────────────────────────────────────────
  static const String orders       = '/orders';
  static String orderById(int id)  => '/orders/$id';
  static String orderStatus(int id)=> '/orders/$id/status';
  static String cancelOrder(int id)=> '/orders/$id/cancel';
  static const String myOrders     = '/orders/my';

  // ── Ventas (caja física) ──────────────────────────────────────
  static const String sales        = '/sales';
  static String saleById(int id)   => '/sales/$id';
  static String registerPayment(int id) => '/sales/$id/payment';

  // ── Carrito ───────────────────────────────────────────────────
  static const String cart         = '/cart';
  static String cartItem(int id)   => '/cart/$id';

  // ── Reportes ──────────────────────────────────────────────────
  static const String reports      = '/reports/sales';
}
