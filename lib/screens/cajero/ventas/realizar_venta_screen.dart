import 'package:flutter/material.dart';
import 'package:parfum/models/product_model.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:parfum/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/models/models.dart';
import 'package:parfum/widgets/common/common_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class RealizarVentaScreen extends StatefulWidget {
  const RealizarVentaScreen({super.key});
  @override
  State<RealizarVentaScreen> createState() => _RealizarVentaScreenState();
}
final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';
class _RealizarVentaScreenState extends State<RealizarVentaScreen> {
  final _skuCtrl   = TextEditingController();
  final _montoCtrl = TextEditingController();

  List<ProductModel> _sugerencias = [];

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

  // 🔥 MÉTODO CORE: Agrega el objeto ProductModel directamente a la venta actual
  void _agregarProductoAFormulario(ProductModel product) {
    if (!product.isAvailable) {
      setState(() => _error = 'Producto sin stock: ${product.nombre}');
      return;
    }

    final idx = _items.indexWhere((i) => i.productoId == product.id);
    setState(() {
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
      _error = null; // Limpiamos errores previos si todo sale bien
      _sugerencias = []; // Ocultamos el panel de sugerencias
      _skuCtrl.clear();   // Limpiamos el buscador
    });
  }

  // 📝 TU MÉTODO MODIFICADO: Para cuando presionan ENTER o usan escáner físico
  void _addBySku() async {
    final texto = _skuCtrl.text.trim().toUpperCase();
    if (texto.isEmpty) return;

    setState(() { _loadingSku = true; _error = null; });
    final prov = context.read<ProductProvider>();
    if (prov.products.isEmpty) await prov.load();

    // Busca coincidencia exacta por SKU (Flujo del Escáner)
    final product = prov.products.where((p) => p.sku.toUpperCase() == texto).firstOrNull;

    if (product != null) {
      _agregarProductoAFormulario(product);
    } else {
      setState(() { _error = 'SKU no encontrado: $texto'; });
    }
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

    setState(() { _procesando = true; _error = null; _success = null; });

    try {
      // Jalamos el ID del empleado/cajero que está operando el POS
      final int empleadoId = context.read<AuthProvider>().user?.id ?? 0;

      // Convertimos la lista de la RAM al formato estructurado que pide tu PHP
      final List<Map<String, dynamic>> productosPayload = _items.map((item) => {
        'id': item.productoId,
        'cant': item.cantidad,
        'precio': item.precio,
      }).toList();

      // Armando el cuerpo del JSON completo
      final Map<String, dynamic> bodyPayload = {
        'id_usuario': empleadoId,
        'total': _total,
        'metodo_pago': _metodoPago,
        'productos': productosPayload,
      };

      print('🌐 [POS] Enviando JSON de venta al servidor...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/procesar_venta.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Si todo sale bien en MySQL, actualizamos el catálogo para reflejar el nuevo stock restado
          await context.read<ProductProvider>().load();

          setState(() {
            _success = '¡Venta #${data['id_venta']} registrada! Total: ${CurrencyFormatter.format(_total)}';
            _items = [];
            _montoCtrl.clear();
          });
        } else {
          setState(() => _error = 'Fallo en BD: ${data['message']}');
        }
      } else {
        setState(() => _error = 'Error de respuesta del servidor (${response.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Error de red. Verifica la conexión con ngrok.');
      print('Error crítico en POS: $e');
    } finally {
      // 🔥 ¡CORREGIDO! Sintaxis limpia que devuelve todo a la normalidad
      setState(() {
        _procesando = false;
      });
    }
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

      // Buscador de SKU e Inteligente por Nombre
      Row(children: [
        Expanded(
          child: TextField(
            controller: _skuCtrl,
            decoration: const InputDecoration(
              hintText: 'Escribir nombre, marca o escanear SKU...',
              prefixIcon: Icon(Icons.search, size: 18), // Cambiado a lupa para indicar búsqueda general
            ),
            onSubmitted: (_) => _addBySku(),
            // 🔥 FILTRO EN TIEMPO REAL: Busca coincidencias por SKU o por Nombre
            onChanged: (value) {
              final query = value.trim().toLowerCase();
              final prov = context.read<ProductProvider>();
              
              setState(() {
                if (query.isEmpty) {
                  _sugerencias = [];
                } else {
                  _sugerencias = prov.products.where((p) =>
                    p.sku.toLowerCase().contains(query) ||
                    p.nombre.toLowerCase().contains(query)
                  ).toList();
                }
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        _loadingSku
            ? const SizedBox(width: 36, height: 36,
                child: CircularProgressIndicator(strokeWidth: 2))
            : ParfumButton(label: 'Agregar',
                onPressed: _addBySku, icon: Icons.add),
      ]),
      
      // 🔥 PANEL DE SUGERENCIAS INTELIGENTE (Aparece solo si hay coincidencias al escribir)
      if (_sugerencias.isNotEmpty) ...[
        const SizedBox(height: 4),
        ParfumCard(
          padding: EdgeInsets.zero,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200), // Límite de altura con scroll para no deformar la UI
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _sugerencias.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prod = _sugerencias[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.clientePrimary, size: 18),
                  title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('SKU: ${prod.sku} • Stock: ${prod.isAvailable ? "Disponible" : "Agotado"}', style: const TextStyle(fontSize: 11)),
                  trailing: Text(CurrencyFormatter.format(prod.precio), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.clientePrimary)),
                  onTap: () => _agregarProductoAFormulario(prod), // 👈 Inserta el perfume con un toque
                );
              },
            ),
          ),
        ),
      ],
      const SizedBox(height: 14),
]);

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
