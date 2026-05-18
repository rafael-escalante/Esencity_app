import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:parfum/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      nombre: _nombreCtrl.text.trim(),
      email:  _emailCtrl.text.trim(),
      password: _passCtrl.text,
      telefono: _telCtrl.text.trim(),
    );
    if (ok && mounted) context.go('/cliente');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A7F4B), Color(0xFF27AE60)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 32, offset: const Offset(0, 8))]),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PARFUM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: Color(0xFF1A7F4B), letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Crear cuenta', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  if (auth.error != null) ...[
                    NotificationBanner(message: auth.error!, type: NotifType.error),
                    const SizedBox(height: 16),
                  ],

                  ParfumTextField(label: 'Nombre Completo', placeholder: 'Ej. María González Pérez', controller: _nombreCtrl,
                    validator: (v) => Validators.required(v, 'Nombre')),
                  const SizedBox(height: 14),
                  ParfumTextField(label: 'Correo Electrónico', placeholder: 'maria@correo.com', controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress, validator: Validators.email),
                  const SizedBox(height: 14),
                  ParfumTextField(label: 'Teléfono', placeholder: '999 123 4567', controller: _telCtrl,
                    keyboardType: TextInputType.phone, validator: Validators.phone),
                  const SizedBox(height: 14),
                  ParfumTextField(label: 'Contraseña', placeholder: '••••••••', controller: _passCtrl,
                    obscureText: true, validator: Validators.password),
                  const SizedBox(height: 14),
                  ParfumTextField(label: 'Confirmar Contraseña', placeholder: '••••••••', controller: _pass2Ctrl,
                    obscureText: true,
                    validator: (v) => Validators.passwordMatch(v, _passCtrl.text)),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: auth.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A7F4B)),
                            onPressed: _register,
                            child: const Text('Registrarse'),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Center(child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(color: Color(0xFF1A7F4B), fontSize: 12)),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
