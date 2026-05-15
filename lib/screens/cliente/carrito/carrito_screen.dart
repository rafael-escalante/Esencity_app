// ── carrito_screen.dart ───────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';
import 'package:parfum/screens/cliente/pedidos/realizar_pedido_screen.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return cart.items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.border),
              const SizedBox(height: 12),
              const Text('Tu carrito está vacío', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
            ]))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Lista de items
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Carrito de Compras',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Expanded(child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          Container(width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.local_florist_outlined, color: AppColors.border)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.nombre,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(item.descripcion,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text(CurrencyFormatter.format(item.precio),
                                style: const TextStyle(fontSize: 13, color: AppColors.clientePrimary,
                                    fontWeight: FontWeight.w600)),
                          ])),
                          // Qty controls
                          Row(children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => cart.updateQty(item.productoId, item.cantidad - 1),
                            ),
                            Text('${item.cantidad}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => cart.updateQty(item.productoId, item.cantidad + 1),
                            ),
                          ]),
                          const SizedBox(width: 8),
                          Text(CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.close, color: AppColors.danger, size: 18),
                              onPressed: () => cart.remove(item.productoId)),
                        ]),
                      );
                    },
                  )),
                ])),
                const SizedBox(width: 16),

                // Resumen
                SizedBox(width: 240, child: ParfumCard(child: Column(children: [
                  const Text('Resumen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const Divider(height: 20),
                  _SummaryRow('Subtotal', CurrencyFormatter.format(cart.subtotal)),
                  _SummaryRow('IVA (16%)', CurrencyFormatter.format(cart.iva)),
                  const Divider(height: 16),
                  _SummaryRow('Total', CurrencyFormatter.format(cart.total), bold: true),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity,
                    child: ParfumButton(
                      label: 'Realizar pedido',
                      onPressed: () => showModalBottomSheet(
                        context: context, isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<CartProvider>(),
                          child: const RealizarPedidoScreen(),
                        ),
                      ),
                      fullWidth: true,
                      variant: BtnVariant.success,
                      icon: Icons.arrow_forward,
                    ),
                  ),
                ]))),
              ]),
            );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: TextStyle(fontSize: bold ? 15 : 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? AppColors.clientePrimary : AppColors.textPrimary)),
    ]),
  );
}
