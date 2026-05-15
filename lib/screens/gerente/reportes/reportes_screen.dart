import 'package:flutter/material.dart';
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
  String _cat     = 'Todas las categorías';
  DateTime _from  = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to    = DateTime.now();
  bool _generated = false;
  bool _loading   = false;

  final _catOptions = ['Todas las categorías', 'Hombre', 'Mujer', 'Unisex'];

  // ── Datos demo ─────────────────────────────────────────────────
  final _demoStats = {
    'totalVentas':        156800.0,
    'totalTransacciones': 47,
    'productoMasVendido': 'Dior Sauvage',
    'unidadesTop':        18,
    'categoriaLider':     'Hombre',
    'porcentajeCat':      42.5,
  };

  final _demoPeriodos = [
    ('Ene 2025', 18200.0),
    ('Feb 2025', 22400.0),
    ('Mar 2025', 19800.0),
    ('Abr 2025', 31500.0),
    ('May 2025', 28900.0),
    ('Jun 2025', 36000.0),
  ];

  final _demoDetalle = [
    ('15/Ene/2025', 'Carlos M.', 'Dior Sauvage',      2, 5600.0,  'Efectivo'),
    ('18/Ene/2025', 'Carlos M.', 'CK One',             3, 3600.0,  'Transferencia'),
    ('03/Feb/2025', 'Carlos M.', 'Chanel No. 5',       1, 3500.0,  'Efectivo'),
    ('14/Feb/2025', 'Carlos M.', 'Good Girl',          2, 6400.0,  'Efectivo'),
    ('22/Mar/2025', 'Carlos M.', 'Bleu de Chanel',     1, 3100.0,  'Transferencia'),
    ('05/Abr/2025', 'Carlos M.', 'Acqua di Gio',       3, 7200.0,  'Efectivo'),
    ('19/Abr/2025', 'Carlos M.', 'La Vie Est Belle',   2, 5400.0,  'Transferencia'),
    ('30/May/2025', 'Carlos M.', 'Jean Paul Gaultier', 4, 7600.0,  'Efectivo'),
    ('12/Jun/2025', 'Carlos M.', 'Dior Sauvage',       3, 8400.0,  'Efectivo'),
    ('25/Jun/2025', 'Carlos M.', 'Chanel No. 5',       2, 7000.0,  'Transferencia'),
  ];

  Future<void> _generate() async {
    setState(() { _loading = true; });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() { _loading = false; _generated = true; });
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
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reportes de Ventas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // Filtros
          ParfumCard(child: Row(children: [
            Expanded(child: InkWell(
              onTap: () => _pickDate(true),
              child: ParfumTextField(
                label: 'Fecha inicio',
                controller: TextEditingController(
                    text: DateFormatter.short(_from)),
                readOnly: true,
                suffix: const Icon(Icons.calendar_today, size: 16),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: InkWell(
              onTap: () => _pickDate(false),
              child: ParfumTextField(
                label: 'Fecha fin',
                controller: TextEditingController(
                    text: DateFormatter.short(_to)),
                readOnly: true,
                suffix: const Icon(Icons.calendar_today, size: 16),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: ParfumDropdown(
              label: 'Categoría',
              value: _cat,
              options: _catOptions,
              onChanged: (v) => setState(() => _cat = v!),
            )),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ParfumButton(
                label: 'Generar reporte',
                onPressed: _generate,
                icon: Icons.bar_chart,
              ),
            ),
          ])),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_generated) ...[
            // Stats
            Row(children: [
              Expanded(child: _StatCard(
                label: 'Total de Ventas',
                value: CurrencyFormatter.format(_demoStats['totalVentas'] as double),
                icon: Icons.attach_money, color: primary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Transacciones',
                value: '${_demoStats['totalTransacciones']}',
                icon: Icons.receipt_long_outlined, color: AppColors.cajeroAccent,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Producto más vendido',
                value: _demoStats['productoMasVendido'] as String,
                sub: '${_demoStats['unidadesTop']} unidades',
                icon: Icons.star_outline, color: AppColors.warning,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Categoría líder',
                value: _demoStats['categoriaLider'] as String,
                sub: '${_demoStats['porcentajeCat']}% del total',
                icon: Icons.category_outlined, color: AppColors.success,
              )),
            ]),
            const SizedBox(height: 20),

            // Gráfica de barras
            ParfumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ventas por período',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 40000,
                  barGroups: _demoPeriodos.asMap().entries.map((e) =>
                    BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: e.value.$2,
                        color: primary,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      )
                    ])).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 64,
                      getTitlesWidget: (v, _) => Text(
                        '\$${(v / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10)),
                    )),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= _demoPeriodos.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_demoPeriodos[idx].$1,
                              style: const TextStyle(fontSize: 9)),
                        );
                      },
                    )),
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                )),
              ),
            ])),
            const SizedBox(height: 20),

            // Tabla detalle
            ParfumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Detalle de ventas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2), 1: FlexColumnWidth(2),
                  2: FlexColumnWidth(3), 3: FlexColumnWidth(1),
                  4: FlexColumnWidth(2), 5: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.background),
                    children: ['Fecha','Cajero','Producto','Cant.','Total','Pago']
                        .map((h) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              child: Text(h, style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                            ))
                        .toList(),
                  ),
                  ..._demoDetalle.map((d) => TableRow(children: [
                    d.$1, d.$2, d.$3, '${d.$4}',
                    CurrencyFormatter.format(d.$5), d.$6,
                  ].map((v) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    child: Text(v.toString(), style: const TextStyle(fontSize: 12)),
                  )).toList())),
                ],
              ),
            ])),
          ] else
            Center(child: Column(children: [
              const SizedBox(height: 40),
              Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.border),
              const SizedBox(height: 12),
              const Text('Selecciona un período y presiona "Generar reporte"',
                  style: TextStyle(color: AppColors.textMuted)),
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
  const _StatCard({required this.label, required this.value,
      this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label, style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary,
            fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: color), overflow: TextOverflow.ellipsis),
      if (sub != null)
        Text(sub!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ]),
  );
}
