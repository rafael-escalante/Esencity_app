import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:parfum/providers/cart_provider.dart';
import 'package:parfum/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class RealizarPedidoScreen extends StatefulWidget {
  const RealizarPedidoScreen({super.key});
  @override
  State<RealizarPedidoScreen> createState() => _RealizarPedidoScreenState();
}

class _RealizarPedidoScreenState extends State<RealizarPedidoScreen> {
  bool _procesando = false;
  bool _success    = false;
  String _ticketId = '';
  String? _error;

  // Queda únicamente como plan de respaldo por si el servidor no responde un folio válido
  String _generarTicketId() {
    final now = DateTime.now();
    final fecha = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final ms = (now.millisecondsSinceEpoch % 100000)
        .toString()
        .padLeft(5, '0');
    return 'PAR-$fecha-$ms';
  }

  Future<void> _confirmarPedido() async {
    setState(() { _procesando = true; _error = null; });
    try {
      final cart = context.read<CartProvider>();
      final orders = context.read<OrderProvider>();

      // 1. Jalamos el ID del usuario actual desde el AuthProvider
      final int userId = context.read<AuthProvider>().user?.id ?? 0;

      // 2. Ejecutamos la petición HTTP hacia el backend pasándole el idUsuario
      final bool ok = await orders.createFromCart(idUsuario: userId);

      // 3. Validamos si el servidor pudo procesar la transacción SQL con éxito
      if (!ok) {
        setState(() {
          _error = orders.error ?? 'Error al registrar el pedido en el servidor.';
          _procesando = false;
        });
        return; // Detenemos el flujo para proteger el carrito local
      }

      // Si la base de datos procesó todo al 100%, procedemos a limpiar el estado del carrito local
      await cart.clear();
      
      // 🔥 LA CLAVE: Extraemos el folio real que capturó el OrderProvider desde el PHP.
      // Si por alguna extraña razón viene vacío, usamos el generador local de respaldo.
      final String realFolio = orders.lastFolio ?? _generarTicketId();

      setState(() { 
        _ticketId = realFolio; 
        _success = true; 
        _procesando = false; 
      });
    } catch (_) {
      setState(() {
        _error = 'Error al registrar el pedido. Inténtalo de nuevo.';
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: _success
          ? _TicketView(ticketId: _ticketId)
          : _PagoView(
              error: _error,
              procesando: _procesando,
              onConfirmar: _confirmarPedido,
              onCancelar: () => Navigator.pop(context),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Vista formulario de pago por transferencia
// ══════════════════════════════════════════════════════════════════
class _PagoView extends StatelessWidget {
  final String? error;
  final bool procesando;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  // Datos bancarios de la perfumería
  static const String _banco  = 'BBVA';
  static const String _clabe  = '012 180 0012 3456 7890 1';
  static const String _nombre = 'PARFUM S.A. de C.V.';
  static const String _cuenta = '0123456789';

  const _PagoView({
    required this.error, required this.procesando,
    required this.onConfirmar, required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, 
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          const Row(
            children: [
              Icon(Icons.payment_outlined, color: AppColors.clientePrimary, size: 22),
              SizedBox(width: 10),
              Text('Pago por Transferencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(height: 20),

          if (error != null) ...[
            NotificationBanner(message: error!, type: NotifType.error),
            const SizedBox(height: 12),
          ],

          // ── Resumen del pedido ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Resumen del pedido',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...cart.items.values.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${i['nombre']} x${i['cantidad']}',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format((double.parse(i['precio'].toString())) * int.parse(i['cantidad'].toString())),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                )),

                const Divider(height: 14),
                _ResumenRow('Subtotal', CurrencyFormatter.format(cart.subtotal)),
                const SizedBox(height: 3),
                _ResumenRow('IVA (16%)', CurrencyFormatter.format(cart.iva)),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text(
                      'TOTAL A PAGAR',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      CurrencyFormatter.format(cart.total),
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w900,
                        color: AppColors.clientePrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Datos bancarios ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBADEF7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_outlined, size: 16, color: AppColors.cajeroNavbar),
                    SizedBox(width: 6),
                    Text(
                      'Realiza tu transferencia a:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.cajeroNavbar),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DatosBancariosRow('Banco',       _banco),
                _DatosBancariosRow('No. cuenta', _cuenta),
                _DatosBancariosRow('CLABE',      _clabe, copiable: true),
                _DatosBancariosRow('A nombre de', _nombre),
                const SizedBox(height: 10),
                
                // Aviso informativo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.notifWarnBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.notifWarnBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.notifWarnText),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Al confirmar, tu pedido quedará en estado '
                          '"Pendiente" hasta que verifiquemos tu pago.',
                          style: TextStyle(fontSize: 11, color: AppColors.notifWarnText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Botones de acción ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onCancelar,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: procesando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.clientePrimary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        label: const Text('Confirmar pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        onPressed: onConfirmar,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Fila datos bancarios con opción de copiar
class _DatosBancariosRow extends StatelessWidget {
  final String label, value;
  final bool copiable;
  const _DatosBancariosRow(this.label, this.value, {this.copiable = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            if (copiable)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CLABE copiada al portapapeles'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.clientePrimary,
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.copy_outlined, size: 16, color: AppColors.cajeroNavbar),
                ),
              ),
          ],
        ),
      );
}

class _ResumenRow extends StatelessWidget {
  final String label, value;
  const _ResumenRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════
//  Vista ticket generado tras confirmar
// ══════════════════════════════════════════════════════════════════
class _TicketView extends StatelessWidget {
  final String ticketId;
  const _TicketView({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, 
      children: [
        // Handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 28),

        // Ícono éxito
        Container(
          width: 80, 
          height: 80,
          decoration: const BoxDecoration(color: Color(0xFFD4F1E4), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.clientePrimary, size: 46),
        ),
        const SizedBox(height: 16),
        const Text('¡Pedido registrado!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Tu pedido está pendiente de verificación de pago.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 28),

        // ── Ticket ID (Folio Real de MySQL) ───────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Text(
                'FOLIO DE TU PEDIDO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              // ID en grande
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.clientePrimary, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: AppColors.clientePrimary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      ticketId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        color: AppColors.clientePrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Botón copiar folio
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticketId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Folio copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.clientePrimary,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copiar folio'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Guarda este folio para rastrear\ntu pedido en "Mis Pedidos".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Aviso de seguimiento
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.notifWarnBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.notifWarnBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.notifWarnText),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verificaremos tu transferencia en las próximas horas. '
                  'Puedes consultar el estado en "Mis Pedidos".',
                  style: TextStyle(fontSize: 12, color: AppColors.notifWarnText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Botón cerrar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clientePrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}