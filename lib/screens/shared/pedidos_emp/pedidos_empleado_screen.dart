import 'package:flutter/material.dart';
import 'package:parfum/models/order_model.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:parfum/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class PedidosEmpleadoScreen extends StatefulWidget {
  final int idRol; // 👉 Recibimos el rol del usuario conectado (1: Gerente, 2: Almacenista, 3: Cajero)

  const PedidosEmpleadoScreen({super.key, required this.idRol});

  @override
  State<PedidosEmpleadoScreen> createState() => _PedidosEmpleadoScreenState();
}

class _PedidosEmpleadoScreenState extends State<PedidosEmpleadoScreen> {
  String _statusFiltro = 'Todos los status';
  late List<String> _statusOptions;

  @override
  void initState() {
    super.initState();
    
    // Configuración inicial de filtros según las responsabilidades del Rol
    if (widget.idRol == 2) {
      // El almacenista solo trabaja con pedidos pagados en espera de empaque
      _statusFiltro = 'pagado';
      _statusOptions = ['pagado'];
    } else {
      // El gerente y cajero pueden auditar todo el catálogo de estados
      _statusOptions = ['Todos los status', ...AppStrings.statusOptions];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<OrderProvider>().loadAll(
          status: _statusFiltro == 'Todos los status' ? null : _statusFiltro
        ));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();
    final user = context.watch<AuthProvider>().user;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          widget.idRol == 2 ? 'Pedidos por Preparar (Almacén)' : 'Gestión de Pedidos',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)
        ),
        const SizedBox(height: 16),

        // Filtro status: Solo lo mostramos si NO es almacenista para no confundirlo
        if (widget.idRol != 2)
          Row(children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                value: _statusFiltro,
                decoration: const InputDecoration(),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _statusFiltro = v!);
                  prov.loadAll(status: v == 'Todos los status' ? null : v);
                },
              ),
            ),
            const SizedBox(width: 12),
            ParfumButton(
              label: 'Actualizar',
              onPressed: () => prov.loadAll(
                  status: _statusFiltro == 'Todos los status' ? null : _statusFiltro),
              variant: BtnVariant.secondary,
              icon: Icons.refresh,
              isSmall: true,
            ),
          ]),
        
        if (widget.idRol != 2) const SizedBox(height: 16),

        Expanded(
          child: prov.loading
              ? const Center(child: CircularProgressIndicator())
              : prov.orders.isEmpty
                  ? const Center(child: Text('No hay pedidos en este bloque', style: TextStyle(color: AppColors.textMuted)))
                  : _OrderTable(orders: prov.orders, idRol: user?.idRol ?? 0), // 👉 Pasamos el rol a la tabla
        ),
      ]),
    );
  }
}

class _OrderTable extends StatelessWidget {
  final List<OrderModel> orders;
  final int idRol;
  
  const _OrderTable({required this.orders, required this.idRol});

  @override
  Widget build(BuildContext context) {
    
    // 1. Definimos los anchos fijos exactos para cada columna (Deben coincidir en cabecera y filas)
    const double colId = 70;
    const double colCliente = 160;
    const double colFecha = 100;
    const double colTotal = 100;
    const double colStatus = 110;
    const double colAcciones = 300; // Espacio de sobra para los botones de acción
    print('🚨 [DEBUG TABLA] El idRol que está recibiendo la tabla es: $idRol');
    // Calculamos el ancho total sumando todas las columnas
    const double anchoTotalTabla = colId + colCliente + colFecha + colTotal + colStatus + colAcciones + 40;

    return ParfumCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal, // 👉 Habilitamos el desplazamiento horizontal
            child: SizedBox(
              width: anchoTotalTabla, // Forzamos a la tabla a tomar el ancho de sus columnas
              child: Column(
                children: [
                  // ── CABECERA DE LA TABLA ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppColors.background,
                    child: const Row(
                      children: [
                        SizedBox(width: colId,       child: _TH('# Pedido')),
                        SizedBox(width: colCliente,  child: _TH('Cliente')),
                        SizedBox(width: colFecha,    child: _TH('Fecha')),
                        SizedBox(width: colTotal,    child: _TH('Total')),
                        SizedBox(width: colStatus,   child: _TH('Status')),
                        SizedBox(width: colAcciones, child: _TH('Acciones')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // ── FILAS DE DATOS (LISTVIEW) ────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) => _OrderRow(
                        order: orders[i], 
                        idRol: idRol,
                        colWidths: const [colId, colCliente, colFecha, colTotal, colStatus, colAcciones],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      );
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final int idRol; 
  final List<double> colWidths; // 👉 Recibimos la lista de anchos desde el padre
  
  const _OrderRow({
    required this.order, 
    required this.idRol,
    required this.colWidths,
  });

  void _procesarCambioEstado(BuildContext context, String nuevoEstado, String mensajeExito) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: Text('¿Confirmas cambiar el pedido #${order.id} al estado "$nuevoEstado"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<OrderProvider>().updateStatus(order.id, nuevoEstado, idRol);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? mensajeExito : 'Error al procesar la solicitud'),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ));
                context.read<OrderProvider>().loadAll();
              }
            },
            child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ── 🗑️ NUEVO: DIÁLOGO ESTILO "DAR DE BAJA" PARA CANCELACIONES ──
  void _mostrarDialogoCancelacion(BuildContext context) {
    final prov = context.read<OrderProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga al usuario a elegir una opción
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Dar de baja pedido'),
          ],
        ),
        content: Text(
          '¿Está seguro de que desea cancelar el pedido #${order.id} de manera definitiva?\n\n',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, mantener activo', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Cierra la ventana emergente
              final ok = await prov.cancel(order.id, idRol: idRol);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Pedido dado de baja con éxito' : 'Error al procesar la cancelación'),
                  backgroundColor: ok ? Colors.green[700] : Colors.red[700],
                ));
              }
            },
            child: const Text('Sí, cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<OrderProvider>();
    final String statusNormalizado = order.status.toLowerCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Columna ID
          SizedBox(
            width: colWidths[0], 
            child: Text('#${order.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          // Columna Cliente
          SizedBox(
            width: colWidths[1], 
            child: Text(order.clienteNombre, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
          // Columna Fecha
          SizedBox(
            width: colWidths[2], 
            child: Text(DateFormatter.short(order.fecha), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          // Columna Total
          SizedBox(
            width: colWidths[3], 
            child: Text(CurrencyFormatter.format(order.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          // Columna Status
          SizedBox(
            width: colWidths[4], 
            child: Align(alignment: Alignment.centerLeft, child: ParfumBadge(label: order.status)),
          ),
          // Columna Acciones (Aquí van tus botones alineados)
          SizedBox(
            width: colWidths[5], 
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ParfumButton(
                  label: 'Detalles', 
                  isSmall: true,
                  variant: BtnVariant.secondary, 
                  icon: Icons.visibility_outlined,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _OrderDetailDialog(order: order),
                  ),
                ),
                const SizedBox(width: 6),

                // Botón dinámico según Rol y Estado
                if (idRol == 3 && order.status == 'pagado')
                  ParfumButton(
                    label: 'Empaquetar', 
                    isSmall: true, 
                    icon: Icons.inventory_2_outlined,
                    onPressed: () => _procesarCambioEstado(context, 'listo para entregar', 'Pedido empaquetado.'),
                  ),

                if (idRol == 1 || idRol == 2) ...[
                  if (order.status == 'pendiente')
                    ParfumButton(
                      label: 'Cobrar', 
                      isSmall: true, 
                      variant: BtnVariant.success,
                      icon: Icons.payments_outlined,
                      onPressed: () => _procesarCambioEstado(context, 'pagado', 'Pago registrado.'),
                    ),
                  if (statusNormalizado == 'listo para entregar')
                    ParfumButton(
                      label: 'Entregar', 
                      isSmall: true, 
                      icon: Icons.assignment_turned_in_outlined,
                      onPressed: () => _procesarCambioEstado(context, 'finalizado', 'Entrega completada.'),
                    ),
                ],

                if ((idRol == 1) && statusNormalizado == 'pendiente') ...[
                  const SizedBox(width: 6),
                  ParfumButton(
                    label: 'Cancelar', 
                    isSmall: true,
                    variant: BtnVariant.danger, 
                    icon: Icons.cancel_outlined,
                    onPressed: () => _mostrarDialogoCancelacion(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo detalles de pedido ────────────────────────────────────
class _OrderDetailDialog extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Pedido #${order.id}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ParfumBadge(label: order.status),
          ]),
          const Divider(height: 24),
          _InfoRow('Cliente', order.clienteNombre),
          _InfoRow('Fecha', DateFormatter.long(order.fecha)),
          if (order.metodoPago != null) _InfoRow('Método de pago', order.metodoPago!),
          if (order.referencia != null) _InfoRow('Referencia', order.referencia!),
          const SizedBox(height: 16),
          const Text('Productos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const Divider(height: 12),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(item.nombreProducto, style: const TextStyle(fontSize: 13))),
              Text('x${item.cantidad}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              Text(CurrencyFormatter.format(item.subtotal),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          )),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('Total: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(CurrencyFormatter.format(order.total),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16,
                    color: AppColors.gerentePrimary)),
          ]),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerRight,
              child: ParfumButton(label: 'Cerrar', onPressed: () => Navigator.pop(context),
                  variant: BtnVariant.secondary)),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}