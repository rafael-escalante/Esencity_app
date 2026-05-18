import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/widgets/common/common_widgets.dart';
import 'package:parfum/screens/shared/inventario/inventario_screen.dart';
import 'package:parfum/screens/shared/pedidos_emp/pedidos_empleado_screen.dart';
import 'package:parfum/screens/shared/buscar/buscar_producto_screen.dart';

class AlmacenistaHome extends StatefulWidget {
  const AlmacenistaHome({super.key});
  @override
  State<AlmacenistaHome> createState() => _AlmacenistaHomeState();
}

class _AlmacenistaHomeState extends State<AlmacenistaHome> {
  int _selected = 0;

  final _items = const [
    (icon: Icons.inventory_2_outlined,  label: 'Inventario'),
    (icon: Icons.receipt_long_outlined, label: 'Pedidos'),
    (icon: Icons.search,                label: 'Buscar'),
  ];

  final _screens = [
    const InventarioScreen(),
    // Como este archivo solo lo abre el almacenista, le inyectas el 2 directo:
    const PedidosEmpleadoScreen(idRol: 2),
    const BuscarProductoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      // 👉 1. Agregamos el Drawer (Ventana deslizante)
      drawer: Drawer(
        backgroundColor: AppColors.almacenistaNavbar,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                user?.nombre ?? '', 
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis
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
                    Navigator.pop(context); // 👉 Cierra el menú al elegir opción
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white12 : Colors.transparent,
                      border: sel ? const Border(left: BorderSide(color: Colors.white, width: 4)) : null,
                    ),
                    child: Row(children: [
                      Icon(_items[i].icon, color: sel ? Colors.white : Colors.white60, size: 22),
                      const SizedBox(width: 15),
                      Text(_items[i].label, style: TextStyle(
                        color: sel ? Colors.white : Colors.white60, fontSize: 14,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      )),
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
        backgroundColor: AppColors.almacenistaNavbar,
        rol: 'almacenista',
        // 👉 2. Botón para abrir el Drawer usando el contexto correcto
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
      // 👉 3. El body ya no necesita el Row ni el AnimatedContainer
      body: _screens[_selected],
    );
  }
}
