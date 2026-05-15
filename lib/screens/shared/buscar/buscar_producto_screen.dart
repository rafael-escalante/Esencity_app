import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class BuscarProductoScreen extends StatefulWidget {
  const BuscarProductoScreen({super.key});
  @override
  State<BuscarProductoScreen> createState() => _BuscarProductoScreenState();
}

class _BuscarProductoScreenState extends State<BuscarProductoScreen> {
  final _nameCtrl   = TextEditingController();
  final _skuCtrl    = TextEditingController();
  String _categoria = 'Todos';
  bool _searched    = false;

  void _search() {
    final prov = context.read<ProductProvider>();
    final query = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : _skuCtrl.text.trim();
    prov.load(
      search: query.isEmpty ? null : query,
      categoria: _categoria == 'Todos' ? null : _categoria,
    );
    setState(() => _searched = true);
  }

  void _clear() {
    _nameCtrl.clear();
    _skuCtrl.clear();
    setState(() { _searched = false; _categoria = 'Todos'; });
    context.read<ProductProvider>().load(search: null, categoria: null);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();

    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Buscar Producto',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          // Filtros
          ParfumCard(child: Column(children: [
            Row(children: [
              Expanded(child: ParfumTextField(
                  label: 'Nombre',
                  placeholder: 'Ej. Chanel No. 5',
                  controller: _nameCtrl)),
              const SizedBox(width: 14),
              Expanded(child: ParfumTextField(
                  label: 'SKU',
                  placeholder: 'Ej. CH-001',
                  controller: _skuCtrl)),
              const SizedBox(width: 14),
              Expanded(child: ParfumDropdown(
                  label: 'Categoría',
                  value: _categoria,
                  options: AppStrings.categorias,
                  onChanged: (v) => setState(() => _categoria = v!))),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ParfumButton(label: 'Limpiar', onPressed: _clear,
                  variant: BtnVariant.secondary, icon: Icons.clear),
              const SizedBox(width: 12),
              ParfumButton(label: 'Buscar', onPressed: _search,
                  icon: Icons.search),
            ]),
          ])),
          const SizedBox(height: 20),

          if (prov.loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searched && prov.products.isEmpty)
            const Expanded(child: Center(child: Text(
                'No se encontraron resultados',
                style: TextStyle(color: AppColors.textMuted))))
          else if (prov.products.isNotEmpty && _searched)
            Expanded(child: _ResultsTable(products: prov.products)),
        ]),
      );
  }
}

class _ResultsTable extends StatelessWidget {
  final List<ProductModel> products;
  const _ResultsTable({required this.products});

  @override
  Widget build(BuildContext context) {
    return ParfumCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.background,
          child: const Row(children: [
            Expanded(flex: 1, child: _TH('SKU')),
            Expanded(flex: 3, child: _TH('Nombre')),
            Expanded(flex: 1, child: _TH('Categoría')),
            Expanded(flex: 1, child: _TH('Conc.')),
            Expanded(flex: 1, child: _TH('ml')),
            Expanded(flex: 1, child: _TH('Precio')),
            Expanded(flex: 1, child: _TH('Stock')),
            Expanded(flex: 2, child: _TH('Estado')),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = products[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Expanded(flex: 1, child: Text(p.sku,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                  Expanded(flex: 3, child: Text(p.nombre,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Expanded(flex: 1, child: Text(p.categoria,
                      style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: Text(p.concentracion,
                      style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: Text('${p.ml}ml',
                      style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: Text(CurrencyFormatter.format(p.precio),
                      style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: Text('${p.stock}',
                      style: TextStyle(fontSize: 13,
                          color: p.stock <= 5 ? AppColors.danger : AppColors.textPrimary))),
                  Expanded(flex: 2, child: ParfumBadge(label: p.estadoBadge)),
                ]),
              );
            },
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
