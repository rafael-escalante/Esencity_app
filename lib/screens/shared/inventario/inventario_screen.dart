import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/providers/providers.dart';

import 'package:parfum/widgets/common/common_widgets.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _searchCtrl = TextEditingController();
  String _categoria = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ProductProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Encabezado
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Inventario', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ParfumButton(
              label: 'Registrar producto',
              onPressed: () => _openForm(context),
              icon: Icons.add,
            ),
          ]),
          const SizedBox(height: 16),

          // Filtros
          Row(children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, SKU...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16),
                          onPressed: () { _searchCtrl.clear(); prov.load(); })
                      : null,
                ),
                onChanged: (v) => prov.load(search: v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                width: 500,
                child: DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(),
                  items: AppStrings.categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _categoria = v!);
                    prov.load(categoria: v);
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Tabla
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.products.isEmpty
                    ? const Center(child: Text('No se encontraron productos', style: TextStyle(color: AppColors.textMuted)))
                    : _ProductTable(products: prov.products, primary: primary),
          ),
        ]),
      ),
    );
  }

  void _openForm(BuildContext context, [ProductModel? product]) {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
  }
}

// ── Tabla de productos ────────────────────────────────────────────
class _ProductTable extends StatelessWidget {
  final List<ProductModel> products;
  final Color primary;
  const _ProductTable({required this.products, required this.primary});

  @override
  Widget build(BuildContext context) {
    // Definimos un ancho total para la tabla (ej. 800px) para que obligue al scroll
    const double tableWidth = 1015.0; 

    return ParfumCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 👈 LA MAGIA ESTÁ AQUÍ
        child: SizedBox(
          width: tableWidth,
          child: Column(children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(children: [
                SizedBox(width: 60,  child: _TH('SKU')),
                SizedBox(width: 160, child: _TH('Nombre')),
                SizedBox(width: 120, child: _TH('Marca')),
                SizedBox(width: 120, child: _TH('Categoría')),
                SizedBox(width: 100, child: _TH('Precio')),
                SizedBox(width: 80,  child: _TH('Stock')),
                SizedBox(width: 120, child: _TH('Estado')),
                SizedBox(width: 220, child: _TH('Acciones')),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => _ProductRow(p: products[i], primary: primary),
              ),
            ),
          ]),
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
          color: AppColors.textSecondary, letterSpacing: 0.3));
}

class _ProductRow extends StatelessWidget {
  final ProductModel p;
  final Color primary;
  const _ProductRow({required this.p, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        // Cambiamos Expanded por SizedBox con el MISMO ancho que la cabecera
        SizedBox(width: 60, child: Text(p.sku.isEmpty ? 'N/A' : p.sku, 
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
            
        SizedBox(width: 160, child: Text(p.nombre, 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        
        SizedBox(width: 120, child: Text(p.marca, 
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),

        SizedBox(width: 120, child: Text(p.categoria, 
            style: const TextStyle(fontSize: 13))),
            
        SizedBox(width: 100, child: Text(CurrencyFormatter.format(p.precio), 
            style: const TextStyle(fontSize: 13))),
            
        SizedBox(width: 80, child: Text('${p.stock}', style: TextStyle(fontSize: 13,
            color: p.stock <= 5 ? AppColors.danger : AppColors.textPrimary,
            fontWeight: p.stock <= 5 ? FontWeight.w700 : FontWeight.w400))),
            
        SizedBox(width: 120, child: ParfumBadge(label: p.estadoBadge)),
        
        SizedBox(width: 220, child: Row(mainAxisAlignment: MainAxisAlignment.start,
          children: [
          ParfumButton(label: 'Editar', onPressed: () =>
              showDialog(context: context, builder: (_) => _ProductFormDialog(product: p)),
              variant: BtnVariant.secondary, isSmall: true, icon: Icons.edit),
          const SizedBox(width: 10),
          ParfumButton(label: 'Eliminar', onPressed: () =>
              showDialog(context: context, builder: (_) => _DeleteDialog(product: p)),
              variant: BtnVariant.danger, isSmall: true, icon: Icons.delete_outline),
        ])),
      ]),
    );
  }
}

// ── Formulario alta/edición producto ─────────────────────────────
class _ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  const _ProductFormDialog({this.product});
  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre, _marca, _precio, _desc, _ml, _stock;
  String _categoria = 'Hombre';
  String _concentracion = 'EDP';
  bool _loading = false;
  String? _error;
  XFile? _pickedFile;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nombre       = TextEditingController(text: p?.nombre ?? '');
    _marca          = TextEditingController(text: p?.marca ?? '');
    _precio       = TextEditingController(text: p != null ? p.precio.toString() : '');
    _desc         = TextEditingController(text: p?.descripcion ?? '');
    _ml           = TextEditingController(text: p != null ? p.ml.toString() : '');
    _stock        = TextEditingController(text: p != null ? p.stock.toString() : '');
    _categoria    = p?.categoria ?? 'Hombre';
    _concentracion= p?.concentracion ?? 'EDP';
  }

  @override
void dispose() {
  for (final c in [_nombre, _marca, _precio, _desc, _ml, _stock]) {
    c.dispose();
  }
  super.dispose();
}

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final data = {
      'nombre': _nombre.text.trim(),
      'marca': _marca.text.trim(),
      'precio': double.tryParse(_precio.text) ?? 0.0,
      'descripcion': _desc.text.trim(),
      'categoria': _categoria,
      'concentracion': _concentracion,
      'ml': int.tryParse(_ml.text) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
    };
    final prov = context.read<ProductProvider>();
    final ok = isEdit
        ? await prov.update(widget.product!.id, data, _pickedFile)
        : await prov.create(data, _pickedFile); // Pasa el archivo completo
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'No se pudo guardar. Verifica los datos.');
    }
  }

  Future<void> _pickImage() async {
  final img = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (img != null) {
    setState(() => _pickedFile = img);
  }
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? 'Editar Producto' : 'Registrar Producto',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Divider(height: 24),
            if (_error != null) ...[
              NotificationBanner(message: _error!, type: NotifType.error),
              const SizedBox(height: 14),
            ],
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ParfumTextField(label: 'Nombre del perfume', controller: _nombre,
                  validator: (v) => Validators.required(v, 'Nombre'))),
              const SizedBox(width: 14),
              Expanded(child: ParfumTextField(label: 'Marca', controller: _marca,
                  validator: (v) => Validators.required(v, 'Marca'))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ParfumTextField(label: 'Precio (MXN)', controller: _precio,
                  keyboardType: TextInputType.number,
                  validator: Validators.positiveNumber)),
              const SizedBox(width: 14),
              Expanded(child: ParfumDropdown(label: 'Categoría', value: _categoria,
                  options: const ['Hombre', 'Mujer', 'Unisex'],
                  onChanged: (v) => setState(() => _categoria = v!))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ParfumDropdown(label: 'Concentración', value: _concentracion,
                  options: AppStrings.concentraciones,
                  onChanged: (v) => setState(() => _concentracion = v!))),
              const SizedBox(width: 14),
              Expanded(child: ParfumTextField(label: 'Mililitros (ml)', controller: _ml,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.required(v, 'ml'))),
              const SizedBox(width: 14),
              Expanded(child: ParfumTextField(label: 'Stock', controller: _stock,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.required(v, 'Stock'))),
            ]),
            const SizedBox(height: 14),
            ParfumTextField(label: 'Descripción', controller: _desc, maxLines: 3,
                placeholder: 'Notas olfativas, características...'),
            const SizedBox(height: 14),
            // Imagen
            Row(children: [
              ParfumButton(label: 'Seleccionar imagen', onPressed: _pickImage,
                  variant: BtnVariant.secondary, icon: Icons.image_outlined),
              const SizedBox(width: 12),
              if (_pickedFile != null) 
                Text('Imagen seleccionada ✔', style: TextStyle(color: AppColors.success, fontSize: 12)),
              if (_pickedFile == null && widget.product?.imagenUrl != null)
                Text('Imagen actual: ${widget.product!.imagenUrl}', 
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ParfumButton(label: 'Cancelar', onPressed: () => Navigator.pop(context),
                  variant: BtnVariant.secondary),
              const SizedBox(width: 12),
              _loading
                  ? const CircularProgressIndicator()
                  : ParfumButton(label: isEdit ? 'Guardar cambios' : 'Registrar producto',
                      onPressed: _submit),
            ]),
          ])),
        ),
      ),
    );
  }
}

// ── Diálogo baja de producto ──────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final ProductModel product;
  const _DeleteDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          const Text('Eliminar producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('¿Confirmas la baja de "${product.nombre}" (${product.sku})?',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ParfumButton(label: 'Cancelar', onPressed: () => Navigator.pop(context),
                variant: BtnVariant.secondary),
            const SizedBox(width: 12),
            ParfumButton(
              label: 'Sí, eliminar',
              variant: BtnVariant.danger,
              onPressed: () async {
                await context.read<ProductProvider>().delete(product.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ]),
        ]),
      ),
    );
  }
}
