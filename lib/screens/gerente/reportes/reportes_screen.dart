import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final String _baseUrl = 'https://stir-resisting-atom.ngrok-free.dev/api_flutter';

  String _cat     = 'Todas las categorías';
  DateTime _from  = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to    = DateTime.now();
  bool _generated = false;
  bool _loading   = false;

  final _catOptions = ['Todas las categorías', 'Hombre', 'Mujer', 'Unisex'];

  Map<String, dynamic> _stats = {};
  List<dynamic> _periodos = [];
  List<dynamic> _detalle = [];

  Future<void> _generate() async {
    setState(() { _loading = true; _generated = false; });
    
    final String startStr = "${_from.year}-${_from.month.toString().padLeft(2, '0')}-${_from.day.toString().padLeft(2, '0')}";
    final String endStr = "${_to.year}-${_to.month.toString().padLeft(2, '0')}-${_to.day.toString().padLeft(2, '0')}";

    try {
      final url = '$_baseUrl/reportes_ventas.php?fecha_inicio=$startStr&fecha_fin=$endStr&categoria=$_cat';
      print('🌐 [REPORTES] Pidiendo datos a: $url');

      final response = await http.get(Uri.parse(url));
      print('📥 [REPORTES] Código HTTP: ${response.statusCode}');
      print('📄 [REPORTES] JSON puro del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _stats = data['stats'];
            _periodos = data['periodos'];
            _detalle = data['detalle'];
            _generated = true;
          });
          print('✅ [REPORTES] Datos montados con éxito en la UI.');
        } else {
          print('❌ [REPORTES] El PHP devolvió un error de negocio: ${data['message']}');
        }
      }
    } catch (e) {
      print('❌ [REPORTES] ¡CRASH EN FLUTTER! Algo falló al procesar los datos: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget filtrosWidget = isMobile
        ? Column(children: [
            Row(children: [
              Expanded(child: InkWell(onTap: () => _pickDate(true), child: IgnorePointer(child: ParfumTextField(label: 'Fecha inicio', controller: TextEditingController(text: DateFormatter.short(_from)), readOnly: true, suffix: const Icon(Icons.calendar_today, size: 16))))),
              const SizedBox(width: 10),
              Expanded(child: InkWell(onTap: () => _pickDate(false), child: IgnorePointer(child: ParfumTextField(label: 'Fecha fin', controller: TextEditingController(text: DateFormatter.short(_to)), readOnly: true, suffix: const Icon(Icons.calendar_today, size: 16))))),
            ]),
            const SizedBox(height: 10),
            ParfumDropdown(label: 'Categoría', value: _cat, options: _catOptions, onChanged: (v) => setState(() => _cat = v!)),
            const SizedBox(height: 12),
            ParfumButton(label: 'Generar reporte', onPressed: _generate, icon: Icons.bar_chart, fullWidth: true),
          ])
        : Row(children: [
            Expanded(child: InkWell(onTap: () => _pickDate(true), child: IgnorePointer(child: ParfumTextField(label: 'Fecha inicio', controller: TextEditingController(text: DateFormatter.short(_from)), readOnly: true, suffix: const Icon(Icons.calendar_today, size: 16))))),
            const SizedBox(width: 12),
            Expanded(child: InkWell(onTap: () => _pickDate(false), child: IgnorePointer(child: ParfumTextField(label: 'Fecha fin', controller: TextEditingController(text: DateFormatter.short(_to)), readOnly: true, suffix: const Icon(Icons.calendar_today, size: 16))))),
            const SizedBox(width: 12),
            Expanded(child: ParfumDropdown(label: 'Categoría', value: _cat, options: _catOptions, onChanged: (v) => setState(() => _cat = v!))),
            const SizedBox(width: 12),
            Padding(padding: const EdgeInsets.only(top: 18), child: ParfumButton(label: 'Generar reporte', onPressed: _generate, icon: Icons.bar_chart)),
          ]);

    Widget statsWidget = isMobile
        ? Column(children: [
            Row(children: [
              // 🔥 CORREGIDO: Conversión segura de num a double usando double.parse().toString()
              Expanded(child: _StatCard(label: 'Total Ventas', value: CurrencyFormatter.format(double.parse((_stats['totalVentas'] ?? 0).toString())), icon: Icons.attach_money, color: primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Transacciones', value: '${_stats['totalTransacciones'] ?? 0}', icon: Icons.receipt_long_outlined, color: AppColors.cajeroAccent)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatCard(label: 'Producto Top', value: '${_stats['productoMasVendido'] ?? "Ninguno"}', sub: '${_stats['unidadesTop'] ?? 0} uds', icon: Icons.star_outline, color: AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Categoría Líder', value: '${_stats['categoriaLider'] ?? "Ninguna"}', sub: '${_stats['porcentajeCat'] ?? 0}% del total', icon: Icons.category_outlined, color: AppColors.success)),
            ]),
          ])
        : Row(children: [
            Expanded(child: _StatCard(label: 'Total de Ventas', value: CurrencyFormatter.format(double.parse((_stats['totalVentas'] ?? 0).toString())), icon: Icons.attach_money, color: primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Transacciones', value: '${_stats['totalTransacciones'] ?? 0}', icon: Icons.receipt_long_outlined, color: AppColors.cajeroAccent)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Producto más vendido', value: '${_stats['productoMasVendido'] ?? "Ninguno"}', sub: '${_stats['unidadesTop'] ?? 0} unidades', icon: Icons.star_outline, color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Categoría líder', value: '${_stats['categoriaLider'] ?? "Ninguna"}', sub: '${_stats['porcentajeCat'] ?? 0}% del total', icon: Icons.category_outlined, color: AppColors.success)),
          ]);

    double maxYChart = 50000;
    if (_periodos.isNotEmpty) {
      // 🔥 CORREGIDO: Parseo ultra seguro para la obtención del máximo de la gráfica
      double maxVal = _periodos.map((p) => double.parse(p[1].toString())).reduce((a, b) => a > b ? a : b);
      maxYChart = maxVal > 0 ? maxVal * 1.2 : 50000;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reportes de Ventas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ParfumCard(child: filtrosWidget),
        const SizedBox(height: 20),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
        else if (_generated) ...[
          statsWidget,
          const SizedBox(height: 20),
          ParfumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ventas por período', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _periodos.isEmpty 
              ? const SizedBox(height: 150, child: Center(child: Text('Sin datos en este rango', style: TextStyle(color: AppColors.textMuted))))
              : SizedBox(
                  height: 200,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxYChart,
                    barGroups: _periodos.asMap().entries.map((e) =>
                      BarChartGroupData(x: e.key, barRods: [
                        // 🔥 CORREGIDO: Conversión blindada para la barra de la gráfica
                        BarChartRodData(toY: double.parse(e.value[1].toString()), color: primary, width: isMobile ? 16 : 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))
                      ])).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v, _) => Text('\$${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9)))),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= _periodos.length) return const SizedBox();
                        return Padding(padding: const EdgeInsets.only(top: 4), child: Text(_periodos[idx][0], style: const TextStyle(fontSize: 8)));
                      })),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                  )),
                ),
          ])),
          const SizedBox(height: 20),
          ParfumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Detalle de ventas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _detalle.isEmpty
              ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Ninguna venta registrada')))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 650, 
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(2.5), 3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1.5), 5: FlexColumnWidth(1.5),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: AppColors.background),
                          children: ['Fecha','Cajero','Producto','Cant.','Total','Pago']
                              .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)))).toList(),
                        ),
                        ..._detalle.map((d) => TableRow(children: [
                          d[0], d[1], d[2], '${d[3]}', 
                          // 🔥 CORREGIDO: Mapeo blindado en la celda de totales de la tabla
                          CurrencyFormatter.format(double.parse(d[4].toString())), 
                          d[5],
                        ].map((v) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7), child: Text(v.toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList())),
                      ],
                    ),
                  ),
                ),
          ])),
        ] else
          Center(child: Column(children: [
            const SizedBox(height: 40),
            Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.border),
            const SizedBox(height: 12),
            const Text('Selecciona un período y presiona "Generar reporte"', style: TextStyle(color: AppColors.textMuted)),
          ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final String? sub;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis, maxLines: 1),
      if (sub != null) ...[
        const SizedBox(height: 2),
        Text(sub!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]
    ]),
  );
}