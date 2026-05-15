import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();
  static final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  static String format(double amount) => _fmt.format(amount);
  static String formatInt(int amount) => _fmt.format(amount);
}

class DateFormatter {
  DateFormatter._();
  static final _short = DateFormat('dd/MMM/yyyy', 'es_MX');
  static final _long  = DateFormat('dd/MMM/yyyy HH:mm', 'es_MX');
  static final _input = DateFormat('yyyy-MM-dd');

  static String short(DateTime d) => _short.format(d);
  static String long(DateTime d)  => _long.format(d);
  static String toInput(DateTime d) => _input.format(d);
  static DateTime fromInput(String s) => _input.parse(s);
}

class Validators {
  Validators._();

  static String? required(String? v, [String label = 'Campo']) =>
      (v == null || v.trim().isEmpty) ? '$label requerido' : null;

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Correo requerido';
    final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return re.hasMatch(v) ? null : 'Correo no válido';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Contraseña requerida';
    return v.length < 6 ? 'Mínimo 6 caracteres' : null;
  }

  static String? passwordMatch(String? v, String other) {
    if (v == null || v.isEmpty) return 'Confirma la contraseña';
    return v != other ? 'Las contraseñas no coinciden' : null;
  }

  static String? rfc(String? v) {
    if (v == null || v.isEmpty) return 'RFC requerido';
    final re = RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$');
    return re.hasMatch(v.toUpperCase()) ? null : 'RFC no válido (formato SAT)';
  }

  static String? positiveNumber(String? v, [String label = 'Valor']) {
    if (v == null || v.isEmpty) return '$label requerido';
    final n = double.tryParse(v);
    if (n == null) return '$label no es un número';
    return n <= 0 ? '$label debe ser mayor a 0' : null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Teléfono requerido';
    return v.replaceAll(RegExp(r'\D'), '').length < 10
        ? 'Teléfono inválido (10 dígitos)' : null;
  }
}
