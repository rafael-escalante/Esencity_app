import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:parfum/providers/cart_provider.dart';
import 'package:parfum/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/widgets/common/common_widgets.dart';
import 'package:parfum/screens/cliente/catalogo/catalogo_screen.dart';
import 'package:parfum/screens/cliente/carrito/carrito_screen.dart';
import 'package:parfum/screens/cliente/pedidos/mis_pedidos_screen.dart';
import 'package:parfum/screens/cliente/perfil/perfil_screen.dart';

class ClienteHome extends StatefulWidget {
  const ClienteHome({super.key});
  @override
  State<ClienteHome> createState() => _ClienteHomeState();
}

class _ClienteHomeState extends State<ClienteHome> {
  // 0=Catálogo  1=Mis Pedidos  2=Perfil  (carrito ya no es tab)
  int _selected = 0;
  bool _carritoVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<CartProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    const screens = [
      CatalogoScreen(),
      MisPedidosScreen(),
      PerfilScreen(),
    ];

    const titles = ['Catálogo', 'Mis Pedidos', 'Perfil'];

    return Scaffold(
      appBar: ParfumAppBar(
        title: titles[_selected],
        backgroundColor: AppColors.clienteNavbar,
        rol: 'cliente',
        actions: [
          // ── Carrito SOLO en AppBar esquina superior derecha ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Carrito',
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 24),
                onPressed: () {
                  // Navega temporalmente al carrito usando push
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<CartProvider>(),
                        child: ChangeNotifierProvider.value(
                          value: context.read<OrderProvider>(),
                          child: const _CarritoPage(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
      body: screens[_selected],
      // ── BottomNav SIN carrito ────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected,
        onTap: (i) => setState(() => _selected = i),
        selectedItemColor: AppColors.clientePrimary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined), label: 'Catálogo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Mis Pedidos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ── Página del carrito (se abre con Navigator.push) ───────────────
class _CarritoPage extends StatelessWidget {
  const _CarritoPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.clienteNavbar,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Carrito de Compras',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: const CarritoScreen(),
    );
  }
}
