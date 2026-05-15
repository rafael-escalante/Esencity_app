import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/router.dart';
import 'package:parfum/core/theme/app_theme.dart';
import 'package:parfum/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);
  runApp(const ParfumApp());
}

class ParfumApp extends StatelessWidget {
  const ParfumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: const _AppWithRouter(),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();
  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await context.read<AuthProvider>().tryAutoLogin();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('✦ ESCENCITY',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1654), letterSpacing: 2)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF2C1654)),
            ]),
          ),
        ),
      );
    }

    final auth  = context.watch<AuthProvider>();
    final theme = switch (auth.rol) {
      'gerente'     => AppTheme.gerente(),
      'cajero'      => AppTheme.cajero(),
      'almacenista' => AppTheme.almacenista(),
      'cliente'     => AppTheme.cliente(),
      _             => AppTheme.gerente(),
    };

    return MaterialApp.router(
      title: 'ESENCITY',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: createRouter(auth),
    );
  }
}
