import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';
import 'package:parfum/screens/shared/inventario/inventario_screen.dart';
import 'package:parfum/screens/shared/pedidos_emp/pedidos_empleado_screen.dart';
import 'package:parfum/screens/shared/buscar/buscar_producto_screen.dart';
import 'package:parfum/screens/gerente/empleados/empleados_screen.dart';
import 'package:parfum/screens/gerente/reportes/reportes_screen.dart';
import 'package:parfum/screens/cajero/ventas/realizar_venta_screen.dart';

class GerenteHome extends StatefulWidget {
  const GerenteHome({super.key});
  @override
  State<GerenteHome> createState() => _GerenteHomeState();
}

class _GerenteHomeState extends State<GerenteHome> {
  int _selected = 0;
  bool _isExpanded = true; // Controla el estado del sidebar

  final _items = const [
    _NavItem(icon: Icons.people_outline,        label: 'Empleados'),
    _NavItem(icon: Icons.inventory_2_outlined,  label: 'Inventario'),
    _NavItem(icon: Icons.receipt_long_outlined, label: 'Pedidos'),
    _NavItem(icon: Icons.point_of_sale_outlined,label: 'Realizar Venta'),
    _NavItem(icon: Icons.search,                label: 'Buscar'),
    _NavItem(icon: Icons.bar_chart_outlined,    label: 'Reportes'),
  ];

  final _screens = const [
    EmpleadosScreen(),
    InventarioScreen(),
    PedidosEmpleadoScreen(),
    RealizarVentaScreen(),
    BuscarProductoScreen(),
    ReportesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      // 1. Agregamos el Drawer (La ventana deslizante)
      drawer: _Sidebar(
        items: _items,
        selected: _selected,
        isExpanded: true, // En el Drawer siempre lo queremos expandido
        color: AppColors.gerenteNavbar,
        userName: user?.nombre ?? '',
        onSelect: (i) {
          setState(() => _selected = i);
          Navigator.pop(context); // 👉 Esto cierra el menú al tocar una opción
        },
      ),
      appBar: ParfumAppBar(
        title: _items[_selected].label,
        backgroundColor: AppColors.gerenteNavbar,
        rol: 'gerente',
        // 2. Cambiamos el leading para que abra el Drawer
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      
      // 3. El body ahora solo contiene el contenido, sin el Row
      body: _screens[_selected],
    );
  }
}

// ── Sidebar compartido ────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final bool isExpanded;
  final Color color;
  final String userName;
  final void Function(int) onSelect;

  const _Sidebar({
    required this.items, required this.selected, required this.isExpanded,
    required this.color, required this.userName, required this.onSelect,
  });

  @override
Widget build(BuildContext context) {
  // Cambiamos AnimatedContainer por Drawer
  return Drawer(
    width: 250, // Definimos un ancho fijo para el modo "deslizable"
    backgroundColor: color,
    child: Column(
      children: [
        // Header con el nombre del usuario
        Container(
          padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
          width: double.infinity,
          child: Text(
            userName,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        
        // Lista de navegación
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isSelected = i == selected;
              
              return InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white12 : Colors.transparent,
                    // Borde indicador lateral
                    border: isSelected
                        ? const Border(left: BorderSide(color: Colors.white, width: 4))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon, 
                        color: isSelected ? Colors.white : Colors.white60, 
                        size: 22
                      ),
                      const SizedBox(width: 15),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}