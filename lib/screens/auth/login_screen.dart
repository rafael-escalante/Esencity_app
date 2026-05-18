import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:parfum/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/constants/app_strings.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl  = TextEditingController(text: '');
  
  bool _obscure    = true;

  

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  final auth = context.read<AuthProvider>();
  final cart = context.read<CartProvider>(); // 👈 1. Leemos el carrito aquí antes del await

  // 👈 2. Se lo pasamos como argumento al login
  final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text, cart);

  if (!mounted) return; // Ahora si se sale aquí, ¡ya no importa! El ID ya está a salvo en la RAM.

  if (ok) {
    _redirectByRole(auth.rol);
  }
}
  void _redirectByRole(String rol) {
    switch (rol) {
      case 'gerente':     context.go('/gerente');     break;
      case 'cajero':      context.go('/cajero');      break;
      case 'almacenista': context.go('/almacenista'); break;
      case 'cliente':     context.go('/cliente');     break;
      default:            context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1654), Color(0xFF7C4DCA)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 32, offset: const Offset(0, 8))],
              ),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  // Logo
                  const Text('ESENCITY', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1654), letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('SISTEMA DE GESTIÓN', style: TextStyle(fontSize: 11, color: AppColors.textMuted,
                      letterSpacing: 1)),
                  const SizedBox(height: 32),

                  // Error
                  if (auth.error != null) ...[
                    NotificationBanner(message: auth.error!, type: NotifType.error),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  ParfumTextField(
                    label: AppStrings.email,
                    placeholder: 'ejemplo@correo.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  ParfumTextField(
                    label: AppStrings.password,
                    placeholder: '••••••••',
                    controller: _passCtrl,
                    obscureText: _obscure,
                    validator: Validators.password,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Botón entrar
                  SizedBox(
                    width: double.infinity,
                    child: auth.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _login,
                            child: const Text(AppStrings.login),
                          ),
                  ),
                  const SizedBox(height: 16),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(AppStrings.forgotPw,
                          style: TextStyle(color: Color(0xFF7C4DCA), fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text(AppStrings.register,
                          style: TextStyle(color: Color(0xFF7C4DCA), fontSize: 12)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
