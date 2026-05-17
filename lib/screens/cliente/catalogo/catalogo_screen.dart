import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _searchCtrl = TextEditingController();
  String _cat = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ProductProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Buscador + filtro
        Row(children: [
          Expanded(child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Buscar perfume...',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
            onChanged: (v) => prov.load(search: v),
          )),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: _cat,
              decoration: const InputDecoration(),
              items: AppStrings.categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                setState(() => _cat = v!);
                prov.load(categoria: v);
              },
            ),
          ),
        ]),
        const SizedBox(height: 14),

        Expanded(
          child: prov.loading
              ? const Center(child: CircularProgressIndicator())
              : prov.products.isEmpty
                  ? const Center(child: Text('No se encontraron perfumes',
                      style: TextStyle(color: AppColors.textMuted)))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: prov.products.length,
                      itemBuilder: (_, i) =>
                          _ProductCard(product: prov.products[i]),
                    ),
        ),
      ]),
    );
  }
}

// ── Tarjeta en el grid ────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<CartProvider>(),
            child: ProductoDetalleScreen(product: product),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Imagen
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.imagenUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imagenUrl!.trim(),
                      httpHeaders: const {
                        'ngrok-skip-browser-warning': 'true', // Esto es lo que "hace clic" en el botón por ti
                      },
                      fit: BoxFit.contain,
                      width: double.infinity,
                      placeholder: (_, __) => const _PlaceholderImg(),
                      errorWidget: (_, __, ___) => const _PlaceholderImg(),
                    )
                  : const _PlaceholderImg(),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.badgePendingBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(product.categoria,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.badgePendingText,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(product.nombre,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${product.concentracion} · ${product.ml}ml',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text(CurrencyFormatter.format(product.precio),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.clientePrimary)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  const _PlaceholderImg();
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.local_florist_outlined,
              color: AppColors.border, size: 40),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
//  PANTALLA COMPLETA — Detalle del producto
// ══════════════════════════════════════════════════════════════════
class ProductoDetalleScreen extends StatefulWidget {
  final ProductModel product;
  const ProductoDetalleScreen({super.key, required this.product});
  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  int _qty   = 1;
  bool _added = false;

  Future<void> _addToCart() async {
    await context.read<CartProvider>().addProduct(widget.product, _qty);
    
    // 🔥 EL ESCUDO DEFENSIVO: Solo ejecuta el setState si el usuario sigue viendo esta pantalla
    if (mounted) {
      setState(() => _added = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar con botón regresar ─────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.clienteNavbar,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(p.nombre,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
            overflow: TextOverflow.ellipsis),
        actions: [
          // Badge del carrito también visible aquí
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            if (context.watch<CartProvider>().itemCount > 0)
              Positioned(
                right: 4, top: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${context.watch<CartProvider>().itemCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ]),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Imagen grande ───────────────────────────────────
          Container(
            width: double.infinity,
            height: 300,
            color: AppColors.surface,
            child: p.imagenUrl != null
                ? CachedNetworkImage(
                    imageUrl: p.imagenUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const _PlaceholderImg(),
                    errorWidget: (_, __, ___) => const _PlaceholderImgGrande(),
                  )
                : const _PlaceholderImgGrande(),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              // ── Categoría + disponibilidad ──────────────────
              Row(children: [
                ParfumBadge(label: p.categoria),
                const SizedBox(width: 8),
                ParfumBadge(label: p.estadoBadge),
              ]),
              const SizedBox(height: 12),

              // ── Nombre ──────────────────────────────────────
              Text(p.nombre,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),

              // ── Precio ──────────────────────────────────────
              Text(CurrencyFormatter.format(p.precio),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.clientePrimary)),
              const SizedBox(height: 20),

              // ── Características ─────────────────────────────
              const Text('Características',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  _CaracteristicaRow(
                      icon: Icons.science_outlined,
                      label: 'Concentración',
                      value: p.concentracion),
                  const Divider(height: 16),
                  _CaracteristicaRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Volumen',
                      value: '${p.ml} ml'),
                  const Divider(height: 16),
                  _CaracteristicaRow(
                      icon: Icons.category_outlined,
                      label: 'Categoría',
                      value: p.categoria),
                  const Divider(height: 16),
                  _CaracteristicaRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Disponibilidad',
                      value: p.stock > 0
                          ? '${p.stock} unidades disponibles'
                          : 'Sin stock',
                      valueColor: p.stock > 0
                          ? AppColors.clientePrimary
                          : AppColors.danger),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Descripción ─────────────────────────────────
              if (p.descripcion.isNotEmpty) ...[
                const Text('Descripción',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(p.descripcion,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6)),
                ),
                const SizedBox(height: 24),
              ],

              // ── Sin stock aviso ─────────────────────────────
              if (!p.isAvailable) ...[
                const NotificationBanner(
                    message: 'Este producto no tiene stock disponible.',
                    type: NotifType.warn),
                const SizedBox(height: 16),
              ],

              // ── Selector cantidad + botón agregar ───────────
              if (p.isAvailable) ...[
                const Text('Cantidad',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Row(children: [
                  // Botones qty
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: _qty > 1
                            ? () => setState(() => _qty--)
                            : null,
                        color: _qty > 1
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_qty',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _qty < p.stock
                            ? () => setState(() => _qty++)
                            : null,
                        color: _qty < p.stock
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  // Subtotal en tiempo real
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Subtotal',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted)),
                    Text(
                      CurrencyFormatter.format(p.precio * _qty),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.clientePrimary),
                    ),
                  ]),
                ]),
                const SizedBox(height: 20),
              ],

              // ── Botón agregar al carrito ─────────────────────
              if (_added)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.notifSuccessBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.notifSuccessBorder),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.clientePrimary, size: 20),
                    SizedBox(width: 8),
                    Text('¡Producto agregado al carrito!',
                        style: TextStyle(
                            color: AppColors.clientePrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ]),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.isAvailable
                          ? AppColors.clientePrimary
                          : AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                    label: Text(
                      p.isAvailable
                          ? 'Agregar al carrito'
                          : 'Sin stock disponible',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    onPressed: p.isAvailable ? _addToCart : null,
                  ),
                ),

              const SizedBox(height: 30),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Fila de característica ────────────────────────────────────────
class _CaracteristicaRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _CaracteristicaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: AppColors.clientePrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary)),
      ]);
}

// ── Placeholder imagen grande ─────────────────────────────────────
class _PlaceholderImgGrande extends StatelessWidget {
  const _PlaceholderImgGrande();
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.background,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const Icon(Icons.local_florist_outlined,
                color: AppColors.border, size: 80),
            const SizedBox(height: 8),
            const Text('Sin imagen',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      );
}
