import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/screens/auth/login_screen.dart';
import 'package:parfum/screens/auth/register_screen.dart';
import 'package:parfum/screens/gerente/gerente_home.dart';
import 'package:parfum/screens/cajero/cajero_home.dart';
import 'package:parfum/screens/almacenista/almacenista_home.dart';
import 'package:parfum/screens/cliente/cliente_home.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si no está autenticado y no va a login/register → redirigir a login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Si ya está autenticado y va a login → redirigir a su home
      if (isLoggedIn && isAuthRoute) {
        return switch (authProvider.rol) {
          'gerente'     => '/gerente',
          'cajero'      => '/cajero',
          'almacenista' => '/almacenista',
          'cliente'     => '/cliente',
          _             => '/login',
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/gerente',     builder: (_, __) => const GerenteHome()),
      GoRoute(path: '/cajero',      builder: (_, __) => const CajeroHome()),
      GoRoute(path: '/almacenista', builder: (_, __) => const AlmacenistaHome()),
      GoRoute(path: '/cliente',     builder: (_, __) => const ClienteHome()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}
