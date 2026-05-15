import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/providers/providers.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telCtrl;
  bool _editMode = false;
  bool _success  = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nombreCtrl = TextEditingController(text: user?.nombre ?? '');
    _emailCtrl  = TextEditingController(text: user?.email ?? '');
    _telCtrl    = TextEditingController(text: user?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _emailCtrl.dispose(); _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().updateProfile({
      'nombre': _nombreCtrl.text.trim(),
      'telefono': _telCtrl.text.trim(),
    });
    if (ok) setState(() { _editMode = false; _success = true; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mi Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          if (_success) ...[
            const NotificationBanner(message: 'Perfil actualizado correctamente'),
            const SizedBox(height: 14),
          ],

          ParfumCard(child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Datos personales',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ParfumButton(
                  label: _editMode ? 'Cancelar' : 'Editar',
                  onPressed: () => setState(() { _editMode = !_editMode; _success = false; }),
                  variant: BtnVariant.secondary,
                  icon: _editMode ? Icons.close : Icons.edit,
                  isSmall: true,
                ),
              ]),
              const Divider(height: 20),
              ParfumTextField(label: 'Nombre completo', controller: _nombreCtrl,
                  readOnly: !_editMode,
                  validator: (v) => Validators.required(v, 'Nombre')),
              const SizedBox(height: 12),
              ParfumTextField(label: 'Correo electrónico', controller: _emailCtrl,
                  readOnly: true),  // email no editable
              const SizedBox(height: 12),
              ParfumTextField(label: 'Teléfono', controller: _telCtrl,
                  readOnly: !_editMode, keyboardType: TextInputType.phone),
              if (_editMode) ...[
                const SizedBox(height: 20),
                SizedBox(width: double.infinity,
                  child: auth.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ParfumButton(label: 'Guardar cambios', onPressed: _guardar,
                          fullWidth: true, icon: Icons.save)),
              ],
            ]),
          )),
          const SizedBox(height: 16),

          // Info de cuenta
          ParfumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mi cuenta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Divider(height: 16),
            _InfoRow('Rol', 'Cliente'),
            _InfoRow('Email', user?.email ?? ''),
          ])),
        ]),
      );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}
