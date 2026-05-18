import 'package:flutter/material.dart';
import 'package:parfum/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/models/models.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class RealizarVentaScreen extends StatefulWidget {
  const RealizarVentaScreen({super.key});
  @override
  State<RealizarVentaScreen> createState() => _RealizarVentaScreenState();
}

class _RealizarVentaScreenState extends State<RealizarVentaScreen> {
  final _skuCtrl   = TextEditingController();
  final _montoCtrl = TextEditingController();

  List<SaleItemModel> _items = [];
  String _metodoPago         = 'Efectivo';
  bool _loadingSku           = false;
  bool _procesando           = false;
  String? _error;
  String? _success;

  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _iva      => _subtotal * 0.16;
  double get _total    => _subtotal + _iva;
  double get _cambio   => _metodoPago == 'Efectivo'
      ? (double.tryParse(_montoCtrl.text) ?? 0) - _total : 0;

  // Buscar producto del ProductProvider por SKU
  void _addBySku() async {
    final sku = _skuCtrl.text.trim().toUpperCase();
    if (sku.isEmpty) return;
    setState(() { _loadingSku = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 200));

    final prov = context.read<ProductProvider>();
    // Asegurarnos de que los productos estén cargados
    if (prov.products.isEmpty) await prov.load();

    final product = prov.products.where((p) =>
        p.sku.toUpperCase() == sku).firstOrNull;

    if (product == null) {
      setState(() { _error = 'SKU no encontrado: $sku'; _loadingSku = false; });
      return;
    }
    if (!product.isAvailable) {
      setState(() { _error = 'Producto sin stock: ${product.nombre}'; _loadingSku = false; });
      return;
    }

    final idx = _items.indexWhere((i) => i.productoId == product.id);
    if (idx >= 0) {
      _items[idx].cantidad++;
    } else {
      _items.add(SaleItemModel(
        productoId: product.id,
        nombre: product.nombre,
        sku: product.sku,
        precio: product.precio,
      ));
    }
    _skuCtrl.clear();
    setState(() => _loadingSku = false);
  }

  Future<void> _procesarVenta() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto');
      return;
    }
    if (_metodoPago == 'Efectivo') {
      final monto = double.tryParse(_montoCtrl.text) ?? 0;
      if (monto < _total) {
        setState(() => _error = 'Monto insuficiente');
        return;
      }
    }
    setState(() { _procesando = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _success = '¡Venta registrada! Total: ${CurrencyFormatter.format(_total)}';
      _items = [];
      _montoCtrl.clear();
      _procesando = false;
    });
  }

  void _cancelar() => setState(() {
    _items = []; _montoCtrl.clear(); _error = null; _success = null;
  });

  @override
Widget build(BuildContext context) {
  // Detectamos si la pantalla es de un celular (menos de 800px de ancho)
  final bool isMobile = MediaQuery.of(context).size.width < 800;

  // 1. Definimos la sección de la izquierda (Buscador + Tabla)
  Widget leftSection = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Realizar Venta',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),

      if (_error != null) ...[
        NotificationBanner(message: _error!, type: NotifType.error),
        const SizedBox(height: 10),
      ],
      if (_success != null) ...[
        NotificationBanner(message: _success!),
        const SizedBox(height: 10),
      ],

      // Buscador de SKU
      Row(children: [
        Expanded(child: TextField(
          controller: _skuCtrl,
          decoration: const InputDecoration(
            hintText: 'Escanear o escribir SKU...',
            prefixIcon: Icon(Icons.qr_code, size: 18),
          ),
          onSubmitted: (_) => _addBySku(),
        )),
        const SizedBox(width: 10),
        _loadingSku
            ? const SizedBox(width: 36, height: 36,
                child: CircularProgressIndicator(strokeWidth: 2))
            : ParfumButton(label: 'Agregar',
                onPressed: _addBySku, icon: Icons.add),
      ]),
      const SizedBox(height: 14),

      // Tabla con Scroll Horizontal (Crucial para celulares)
      ParfumCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 750, // Forzamos un ancho mínimo para que no se amontonen las columnas
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.background,
                child: const Row(children: [
                  Expanded(flex: 1, child: _TH('SKU')),
                  Expanded(flex: 3, child: _TH('Nombre')),
                  Expanded(flex: 1, child: _TH('Precio')),
                  Expanded(flex: 2, child: _TH('Cantidad')),
                  Expanded(flex: 1, child: _TH('Subtotal')),
                  SizedBox(width: 32),
                ]),
              ),
              const Divider(height: 1),
              // Aquí limitamos la altura en móvil para que no sea infinita
              Container(
                constraints: BoxConstraints(maxHeight: isMobile ? 300 : 500),
                child: _items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Sin productos agregados')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _SaleItemRow(
                          item: _items[i],
                          onQtyChange: (qty) => setState(() => _items[i].cantidad = qty),
                          onRemove: () => setState(() => _items.removeAt(i)),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ),
    ],
  );

  // 2. Definimos la sección del Ticket (Resumen)
  Widget rightSection = SizedBox(
    width: isMobile ? double.infinity : 280, // Ancho completo en móvil
    child: ParfumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de venta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const Divider(height: 20),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Sin productos',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            )
          else ...[
            ..._items.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${i.nombre} x${i.cantidad}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        Text(CurrencyFormatter.format(i.subtotal),
                            style: const TextStyle(fontSize: 12)),
                      ]),
                )),
          ],
          const Divider(height: 16),
          _TicketRow('Subtotal', CurrencyFormatter.format(_subtotal)),
          _TicketRow('IVA (16%)', CurrencyFormatter.format(_iva)),
          _TicketRow('Total', CurrencyFormatter.format(_total), bold: true, large: true),
          const Divider(height: 16),
          ParfumDropdown(
            label: 'Método de pago',
            value: _metodoPago,
            options: AppStrings.metodosPago,
            onChanged: (v) => setState(() { _metodoPago = v!; _montoCtrl.clear(); }),
          ),
          if (_metodoPago == 'Efectivo') ...[
            const SizedBox(height: 12),
            ParfumTextField(
              label: 'Monto recibido',
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (_montoCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TicketRow('Cambio',
                  CurrencyFormatter.format(_cambio.clamp(0, double.infinity)),
                  color: _cambio >= 0 ? AppColors.success : AppColors.danger),
            ],
          ],
          const SizedBox(height: 20),
          _procesando
              ? const Center(child: CircularProgressIndicator())
              : ParfumButton(
                  label: 'Procesar venta ✓',
                  onPressed: _procesarVenta,
                  fullWidth: true,
                  variant: BtnVariant.success,
                ),
          const SizedBox(height: 8),
          ParfumButton(
            label: 'Cancelar',
            onPressed: _cancelar,
            fullWidth: true,
            variant: BtnVariant.danger,
          ),
        ],
      ),
    ),
  );

  // 3. El ensamblado final dependiendo del dispositivo
  return Scaffold(
    backgroundColor: Colors.transparent, // Para que tome el fondo de la App
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isMobile
          ? Column(
              children: [
                leftSection,
                const SizedBox(height: 16),
                rightSection,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: leftSection),
                const SizedBox(width: 16),
                rightSection,
              ],
            ),
    ),
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

class _SaleItemRow extends StatelessWidget {
  final SaleItemModel item;
  final void Function(int) onQtyChange;
  final VoidCallback onRemove;
  const _SaleItemRow({required this.item,
      required this.onQtyChange, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(children: [
      Expanded(flex: 1, child: Text(item.sku,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
      Expanded(flex: 3, child: Text(item.nombre,
          style: const TextStyle(fontSize: 13))),
      Expanded(flex: 1, child: Text(CurrencyFormatter.format(item.precio),
          style: const TextStyle(fontSize: 13))),
      Expanded(flex: 2, child: Row(children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 18),
          onPressed: item.cantidad > 1
              ? () => onQtyChange(item.cantidad - 1) : null,
        ),
        Text('${item.cantidad}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 18),
          onPressed: () => onQtyChange(item.cantidad + 1),
        ),
      ])),
      Expanded(flex: 1, child: Text(CurrencyFormatter.format(item.subtotal),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      IconButton(
        icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
        onPressed: onRemove,
      ),
    ]),
  );
}

class _TicketRow extends StatelessWidget {
  final String label, value;
  final bool bold, large;
  final Color? color;
  const _TicketRow(this.label, this.value,
      {this.bold = false, this.large = false, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
          fontSize: large ? 14 : 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: TextStyle(
          fontSize: large ? 16 : 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color ?? AppColors.textPrimary)),
    ]),
  );
}
