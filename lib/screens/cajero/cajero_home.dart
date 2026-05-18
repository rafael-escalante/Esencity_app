import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/widgets/common/common_widgets.dart';
import 'package:parfum/screens/shared/pedidos_emp/pedidos_empleado_screen.dart';
import 'package:parfum/screens/shared/buscar/buscar_producto_screen.dart';
import 'package:parfum/screens/cajero/ventas/realizar_venta_screen.dart';
import 'package:parfum/screens/gerente/reportes/reportes_screen.dart';

class CajeroHome extends StatefulWidget {
  const CajeroHome({super.key});
  @override
  State<CajeroHome> createState() => _CajeroHomeState();
}

class _CajeroHomeState extends State<CajeroHome> {
  int _selected = 0;

  final _items = const [
    (icon: Icons.point_of_sale_outlined, label: 'Realizar Venta'),
    (icon: Icons.receipt_long_outlined,  label: 'Pedidos'),
    (icon: Icons.search,                 label: 'Buscar'),
    (icon: Icons.bar_chart_outlined,     label: 'Reportes'),
  ];

  final _screens = [
    const RealizarVentaScreen(),
    const PedidosEmpleadoScreen(idRol: 3),
    const BuscarProductoScreen(),
    const ReportesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      // 👉 1. Implementación del Drawer (Overlay deslizante)
      drawer: Drawer(
        backgroundColor: AppColors.cajeroNavbar,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                user?.nombre ?? '', 
                style: const TextStyle(
                  color: Colors.white70, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final sel = i == _selected;
                return InkWell(
                  onTap: () {
                    setState(() => _selected = i);
                    Navigator.pop(context); // 👉 Cierra el menú automáticamente
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white12 : Colors.transparent,
                      border: sel 
                        ? const Border(left: BorderSide(color: Colors.white, width: 4)) 
                        : null,
                    ),
                    child: Row(children: [
                      Icon(_items[i].icon, color: sel ? Colors.white : Colors.white60, size: 22),
                      const SizedBox(width: 15),
                      Text(
                        _items[i].label, 
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.white60, 
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        )
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      appBar: ParfumAppBar(
        title: _items[_selected].label,
        backgroundColor: AppColors.cajeroNavbar,
        rol: 'cajero',
        // 👉 2. Botón de hamburguesa para abrir el menú
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      // 👉 3. El body ahora es limpio y ocupa todo el ancho
      body: _screens[_selected],
    );
  }
}
