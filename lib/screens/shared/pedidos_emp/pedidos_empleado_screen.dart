import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/models/models.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class PedidosEmpleadoScreen extends StatefulWidget {
  const PedidosEmpleadoScreen({super.key});
  @override
  State<PedidosEmpleadoScreen> createState() => _PedidosEmpleadoScreenState();
}

class _PedidosEmpleadoScreenState extends State<PedidosEmpleadoScreen> {
  String _statusFiltro = 'Todos los status';

  final List<String> _statusOptions = ['Todos los status', ...AppStrings.statusOptions];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<OrderProvider>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();

    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pedidos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // Filtro status
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
          const SizedBox(height: 16),

          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.orders.isEmpty
                    ? const Center(child: Text('No hay pedidos', style: TextStyle(color: AppColors.textMuted)))
                    : _OrderTable(orders: prov.orders),
          ),
        ]),
      );
  }
}

class _OrderTable extends StatelessWidget {
  final List<OrderModel> orders;
  const _OrderTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    return ParfumCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.background,
          child: const Row(children: [
            Expanded(flex: 1, child: _TH('# Pedido')),
            Expanded(flex: 3, child: _TH('Cliente')),
            Expanded(flex: 2, child: _TH('Fecha')),
            Expanded(flex: 2, child: _TH('Total')),
            Expanded(flex: 2, child: _TH('Status')),
            Expanded(flex: 3, child: _TH('Acciones')),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) => _OrderRow(order: orders[i]),
          ),
        ),
      ]),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary));
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<OrderProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(flex: 1, child: Text('#${order.id}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 3, child: Text(order.clienteNombre, style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text(DateFormatter.short(order.fecha),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(flex: 2, child: Text(CurrencyFormatter.format(order.total),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(flex: 2, child: ParfumBadge(label: order.status)),
        Expanded(flex: 3, child: Row(children: [
          // Ver detalles
          ParfumButton(label: 'Detalles', isSmall: true,
              variant: BtnVariant.secondary, icon: Icons.visibility_outlined,
              onPressed: () => showDialog(context: context,
                  builder: (_) => _OrderDetailDialog(order: order))),
          const SizedBox(width: 6),
          // Actualizar status
          if (order.status != AppStrings.statusCancelado &&
              order.status != AppStrings.statusFinalizado)
            ParfumButton(label: 'Status', isSmall: true, icon: Icons.edit_outlined,
                onPressed: () => showDialog(context: context,
                    builder: (_) => _UpdateStatusDialog(order: order))),
          const SizedBox(width: 6),
          if (order.canCancel)
            ParfumButton(label: 'Cancelar', isSmall: true,
                variant: BtnVariant.danger, icon: Icons.cancel_outlined,
                onPressed: () async {
                  final ok = await prov.cancel(order.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Pedido cancelado' : 'Error al cancelar'),
                      backgroundColor: ok ? AppColors.success : AppColors.danger,
                    ));
                  }
                }),
        ])),
      ]),
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

// ── Diálogo actualizar status ─────────────────────────────────────
class _UpdateStatusDialog extends StatefulWidget {
  final OrderModel order;
  const _UpdateStatusDialog({required this.order});
  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  late String _newStatus;

  @override
  void initState() {
    super.initState();
    _newStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Actualizar status del pedido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Divider(height: 20),
          _InfoRow('Pedido', '#${widget.order.id}'),
          _InfoRow('Cliente', widget.order.clienteNombre),
          _InfoRow('Status actual', widget.order.status),
          const SizedBox(height: 16),
          ParfumDropdown(
            label: 'Nuevo status',
            value: _newStatus,
            options: AppStrings.statusOptions,
            onChanged: (v) => setState(() => _newStatus = v!),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ParfumButton(label: 'Cancelar', onPressed: () => Navigator.pop(context),
                variant: BtnVariant.secondary),
            const SizedBox(width: 12),
            ParfumButton(label: 'Guardar', onPressed: () async {
              final ok = await context.read<OrderProvider>().updateStatus(widget.order.id, _newStatus);
              if (context.mounted) Navigator.pop(context);
            }),
          ]),
        ]),
      ),
    );
  }
}
