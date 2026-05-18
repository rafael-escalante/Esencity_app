import 'package:flutter/material.dart';
import 'package:parfum/models/employee_model.dart';
import 'package:parfum/providers/employee_provider.dart';
import 'package:provider/provider.dart';
import 'package:parfum/core/constants/app_colors.dart';
import 'package:parfum/core/utils/formatters.dart';
import 'package:parfum/widgets/common/common_widgets.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});
  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<EmployeeProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmployeeProvider>();
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Empleados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ParfumButton(
              label: 'Nuevo empleado',
              onPressed: () => showDialog(context: context,
                  builder: (_) => _EmployeeFormDialog(onSaved: () => prov.load())),
              icon: Icons.person_add_outlined,
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre, RFC, email...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => prov.load(search: v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Scroll lateral solo aquí
                  child: SizedBox(
                    width: 1200, // Ancho de la tabla para que no se amontone
                    child: _EmployeeTable(employees: prov.employees),
                  ),
                ),
          ),
        ]),
      );
  }
}

class _EmployeeTable extends StatelessWidget {
  final List<EmployeeModel> employees;
  const _EmployeeTable({required this.employees});

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) return const Center(
        child: Text('No se encontraron empleados',
            style: TextStyle(color: AppColors.textMuted)));
    return ParfumCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.background,
          child: const Row(children: [
            Expanded(flex: 3, child: _TH('Nombre')),
            Expanded(flex: 2, child: _TH('Teléfono')),
            Expanded(flex: 2, child: _TH('RFC')),
            Expanded(flex: 3, child: _TH('Correo')),
            Expanded(flex: 2, child: _TH('Puesto')),
            Expanded(flex: 1, child: _TH('Estado')),
            Expanded(flex: 2, child: _TH('Acciones')),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: employees.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) => _EmployeeRow(emp: employees[i]),
          ),
        ),
      ]),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary));
}

class _EmployeeRow extends StatelessWidget {
  final EmployeeModel emp;
  const _EmployeeRow({required this.emp});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<EmployeeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(emp.nombre,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(flex: 2, child: Text(emp.tel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Expanded(flex: 2, child: Text(emp.rfc,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        Expanded(flex: 3, child: Text(emp.email,
            style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text(
            emp.puesto[0].toUpperCase() + emp.puesto.substring(1),
            style: const TextStyle(fontSize: 13))),
        Expanded(flex: 1, child: ParfumBadge(
            label: emp.estado == 'activo' ? 'Activo' : 'Inactivo')),
        Expanded(flex: 2, child: Row(children: [
          ParfumButton(
            label: 'Editar', isSmall: true,
            variant: BtnVariant.secondary, icon: Icons.edit,
            onPressed: () => showDialog(context: context,
                builder: (_) => _EmployeeFormDialog(
                    employee: emp, onSaved: () => prov.load())),
          ),
          const SizedBox(width: 6),
          if (emp.estado == 'activo')
            ParfumButton(
              label: 'Baja', isSmall: true,
              variant: BtnVariant.danger, icon: Icons.person_off_outlined,
              onPressed: () => showDialog(context: context,
                  builder: (_) => _DisableDialog(
                      employee: emp,
                      onConfirm: () {
                        final dataBaja = {
                          'nombre': emp.nombre,
                          'email': emp.email,
                          'puesto': emp.puesto,
                          'rfc': emp.rfc,
                          'estado': 'inactivo', // Esto es lo que detecta tu PHP
                        };
                        
                        // Llamamos a saveEmployee pasando el ID para que haga UPDATE en Umán
                        prov.saveEmployee(dataBaja, id: emp.id);
                      })),
            ),
        ])),
      ]),
    );
  }
}

class _EmployeeFormDialog extends StatefulWidget {
  final EmployeeModel? employee;
  final VoidCallback onSaved;
  const _EmployeeFormDialog({this.employee, required this.onSaved});
  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre, _rfc, _email, _pass;
  String _puesto = 'cajero';
  bool _loading = false;
  bool get isEdit => widget.employee != null;
  late String _estado;
  late TextEditingController _tel;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _tel    = TextEditingController(text: e?.tel ?? '');
    _rfc    = TextEditingController(text: e?.rfc ?? '');
    _email  = TextEditingController(text: e?.email ?? '');
    _pass   = TextEditingController();
    _puesto = e?.puesto.toLowerCase() ?? 'cajero';
    _estado = e?.estado ?? 'activo';
  }

  @override
  void dispose() {
    for (final c in [_nombre, _rfc, _email, _pass]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 🔍 Si la validación falla en la pantalla, este print te avisará en la consola
    if (!_formKey.currentState!.validate()) {
      print('⚠️ Validación visual fallida. Revisa los campos marcados en rojo en el celular.');
      return;
    }
    
    setState(() => _loading = true);
    final prov = context.read<EmployeeProvider>();
    
    // 🚦 TRADUCTOR DE ROLES: Convertimos el string del dropdown al id_rol numérico que pide tu MySQL (cajero = 2, almacenista = 3)
    int idRolNum = _puesto == 'cajero' ? 2 : 3;

    // Embalamos el mapa con todas las columnas reales de tu tabla de MySQL
    final data = {
      'nombre': _nombre.text.trim(),
      'tel': _tel.text.trim(),
      'rfc': _rfc.text.trim().toUpperCase(),
      'email': _email.text.trim(),
      'id_rol': idRolNum.toString(), // 🔥 CORREGIDO: Enviamos id_rol numérico en lugar de 'puesto'
      'estado': _estado,             // 🔥 CORREGIDO: Agregamos el estado activo/inactivo del dropdown
    };

    // 🔥 CORREGIDO: Si es un registro nuevo, le inyectamos la contraseña real escrita por el gerente
    if (!isEdit) {
      data['password'] = _pass.text; 
    } else {
      data['id'] = widget.employee!.id.toString(); // Aseguramos el ID para el caso de edición
    }

    // 📦 El chismoso definitivo de la UI
    print('📦 MAPA COMPLETO LISTO PARA SER ENVIADO DESDE LA UI: $data');

    if (isEdit) {
      await prov.saveEmployee(data, id: widget.employee!.id);
    } else {
      await prov.saveEmployee(data);
    }
    
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? 'Editar Empleado' : 'Nuevo Empleado',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            ParfumTextField(label: 'Nombre completo', controller: _nombre,
                validator: (v) => Validators.required(v, 'Nombre')),
            const SizedBox(height: 12),
            ParfumTextField(
              label: 'Número de teléfono', 
              controller: _tel,
              keyboardType: TextInputType.phone, // Optimizado para tu teclado móvil
              validator: (v) => Validators.required(v, 'Teléfono')
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ParfumTextField(
                  label: 'RFC', 
                  controller: _rfc,
                  // Se mantiene como solo lectura en edición para evitar errores de llave primaria
                  readOnly: false, 
                  validator: Validators.rfc
              ),),
              const SizedBox(width: 12),
              Expanded(child: ParfumDropdown(label: 'Puesto', value: _puesto,
                  options: const ['cajero', 'almacenista'],
                  onChanged: (v) => setState(() => _puesto = v!))),
            ]),
            const SizedBox(height: 12),
            ParfumTextField(label: 'Correo electrónico', controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email),
            const SizedBox(width: 12),
            ParfumDropdown(
                  label: 'Estado', 
                  value: _estado, // Asegúrate de tener late String _estado definida en initState
                  options: const ['activo', 'inactivo'],
                  onChanged: (v) => setState(() => _estado = v!)
                ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              ParfumTextField(label: 'Contraseña temporal', controller: _pass,
                  obscureText: true, validator: Validators.password),
            ],
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ParfumButton(label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                  variant: BtnVariant.secondary),
              const SizedBox(width: 12),
              _loading
                  ? const CircularProgressIndicator()
                  : ParfumButton(
                      label: isEdit ? 'Guardar' : 'Registrar',
                      onPressed: _submit),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _DisableDialog extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onConfirm;
  
  const _DisableDialog({required this.employee, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider para ejecutar la acción
    final prov = context.read<EmployeeProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_off_outlined, color: AppColors.danger, size: 36),
          const SizedBox(height: 12),
          const Text('Dar de baja empleado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('¿Confirmas la baja de ${employee.nombre}?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ParfumButton(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                variant: BtnVariant.secondary),
            const SizedBox(width: 12),
            
            // 👉 AQUÍ PEGAS LA LÓGICA:
            ParfumButton(
              label: 'Sí, dar de baja',
              variant: BtnVariant.danger,
              onPressed: () async {
                final dataParaBaja = {
                  'nombre': employee.nombre,
                  'email': employee.email,
                  'puesto': employee.puesto,
                  'rfc': employee.rfc,
                  'estado': 'inactivo', 
                };

                // Ejecutamos la baja en el servidor de Umán
                final success = await prov.saveEmployee(dataParaBaja, id: employee.id);
                
                if (success && context.mounted) {
                  onConfirm(); // Esto ejecuta el callback si lo necesitas
                  Navigator.pop(context); // Cierra el diálogo
                }
              },
            ),
          ]),
        ]),
      ),
    );
  }
}