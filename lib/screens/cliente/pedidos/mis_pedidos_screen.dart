// ── mis_pedidos_screen.dart ───────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});
  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<OrderProvider>().loadMine());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrderProvider>();

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Mis Pedidos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ParfumButton(label: 'Actualizar', onPressed: () => prov.loadMine(),
                variant: BtnVariant.secondary, icon: Icons.refresh, isSmall: true),
          ]),
          const SizedBox(height: 14),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.orders.isEmpty
                    ? const Center(child: Text('Aún no tienes pedidos',
                        style: TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                        itemCount: prov.orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _OrderCard(order: prov.orders[i]),
                      ),
          ),
        ]),
      );
  }
}

class _OrderCard extends StatelessWidget {
  final order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<OrderProvider>();
    return ParfumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Pedido #${order.id}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ParfumBadge(label: order.status),
      ]),
      const SizedBox(height: 8),
      Text(DateFormatter.long(order.fecha),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      const Divider(height: 16),
      ...order.items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Expanded(child: Text('${item.nombreProducto} x${item.cantidad}',
              style: const TextStyle(fontSize: 13))),
          Text(CurrencyFormatter.format(item.subtotal),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      )),
      const Divider(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Total: ${CurrencyFormatter.format(order.total)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: AppColors.clientePrimary)),
        if (order.canCancel)
          ParfumButton(
            label: 'Cancelar pedido', isSmall: true, variant: BtnVariant.danger,
            icon: Icons.cancel_outlined,
            onPressed: () async {
              final ok = await prov.cancel(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Pedido cancelado' : 'Error al cancelar'),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ));
              }
            },
          ),
      ]),
    ]));
  }
}
