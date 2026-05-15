import 'package:flutter/material.dart';
import 'package:parfum/core/constants/app_colors.dart';

// ── ParfumAppBar ──────────────────────────────────────────────────
class ParfumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final String rol;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;

  const ParfumAppBar({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.rol,
    this.actions,
    this.showBackButton = false,
    this.leading,
  });

  @override
Widget build(BuildContext context) => AppBar(
    backgroundColor: backgroundColor,
    automaticallyImplyLeading: showBackButton,
    leading: leading,
    title: Row(
      mainAxisSize: MainAxisSize.min, // 👉 Ayuda a que el Row no ocupe más de lo necesario
      children: [
        const Text('✦', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(width: 8),
        Text('ESENCITY', 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 12, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2 // Bajamos un poco el espacio para ganar espacio
          )
        ),
        const SizedBox(width: 5),
        Container(height: 15, width: 1, color: Colors.white24),
        const SizedBox(width: 5),
        // 👉 LA SOLUCIÓN: Envolvemos el título dinámico en Flexible
        Flexible(
          child: Text(
            title, 
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
            overflow: TextOverflow.visible, // Si es muy largo, pone "..."
            maxLines: 1,
          ),
        ),
      ],
    ),
    actions: [
      ...?actions,
      _RolBadge(rol: rol),
      const SizedBox(width: 12),
    ],
);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (rol) {
      'gerente'     => (const Color(0xFFE8D0FF), const Color(0xFF5C2D99)),
      'cajero'      => (const Color(0xFFD0E8FF), const Color(0xFF1554A0)),
      'almacenista' => (const Color(0xFFFEF3D0), const Color(0xFF8B5E07)),
      'cliente'     => (const Color(0xFFD4F1E4), const Color(0xFF1A7F4B)),
      _             => (Colors.white24, Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(rol[0].toUpperCase() + rol.substring(1),
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── ParfumButton ──────────────────────────────────────────────────
enum BtnVariant { primary, secondary, danger, warning, success, small }

class ParfumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final bool isSmall;
  final bool fullWidth;
  final IconData? icon;

  const ParfumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BtnVariant.primary,
    this.isSmall = false,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BtnVariant.secondary => (Colors.white, AppColors.gerentePrimary),
      BtnVariant.danger    => (AppColors.danger,   Colors.white),
      BtnVariant.warning   => (AppColors.warning,  Colors.white),
      BtnVariant.success   => (AppColors.success,  Colors.white),
      _                    => (Theme.of(context).colorScheme.primary, Colors.white),
    };
    final border = variant == BtnVariant.secondary
        ? Border.all(color: Theme.of(context).colorScheme.primary)
        : null;
    final pad = isSmall
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 10);

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: isSmall ? 14 : 16, color: fg), const SizedBox(width: 6)],
        Text(label, style: TextStyle(color: fg, fontSize: isSmall ? 12 : 13, fontWeight: FontWeight.w600)),
      ],
    );

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey.shade300 : bg,
          borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
          border: border,
        ),
        child: child,
      ),
    );
  }
}

// ── ParfumTextField ───────────────────────────────────────────────
class ParfumTextField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final bool readOnly;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final Widget? suffix;

  const ParfumTextField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        maxLines: obscureText ? 1 : maxLines,
        style: TextStyle(
          fontSize: 14,
          color: readOnly ? AppColors.textMuted : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: readOnly ? AppColors.background : AppColors.surface,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        ),
      ),
    ],
  );
}

// ── ParfumBadge ───────────────────────────────────────────────────
class ParfumBadge extends StatelessWidget {
  final String label;
  const ParfumBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (label.toLowerCase()) {
      'disponible'         => (AppColors.badgeActiveBg,   AppColors.badgeActiveText),
      'activo'             => (AppColors.badgeActiveBg,   AppColors.badgeActiveText),
      'pendiente'          => (AppColors.badgePendingBg,  AppColors.badgePendingText),
      'pagado'             => (AppColors.badgePendingBg,  AppColors.badgePendingText),
      'listo para entrega' => (AppColors.badgeReadyBg,    AppColors.badgeReadyText),
      'listo'              => (AppColors.badgeReadyBg,    AppColors.badgeReadyText),
      'finalizado'         => (AppColors.badgeDoneBg,     AppColors.badgeDoneText),
      'bajo stock'         => (AppColors.badgeLowBg,      AppColors.badgeLowText),
      'sin stock'          => (AppColors.badgeInactiveBg, AppColors.badgeInactiveText),
      'inactivo'           => (AppColors.badgeCanceledBg, AppColors.badgeCanceledText),
      'cancelado'          => (AppColors.badgeCanceledBg, AppColors.badgeCanceledText),
      _                    => (AppColors.badgeCanceledBg, AppColors.badgeCanceledText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── NotificationBanner ────────────────────────────────────────────
enum NotifType { success, error, warn }

class NotificationBanner extends StatelessWidget {
  final String message;
  final NotifType type;

  const NotificationBanner({super.key, required this.message, this.type = NotifType.success});

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (type) {
      NotifType.error => (AppColors.notifErrorBg, AppColors.notifErrorBorder, AppColors.notifErrorText, Icons.error_outline),
      NotifType.warn  => (AppColors.notifWarnBg,  AppColors.notifWarnBorder,  AppColors.notifWarnText,  Icons.warning_amber),
      _               => (AppColors.notifSuccessBg,AppColors.notifSuccessBorder,AppColors.notifSuccessText, Icons.check_circle_outline),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, color: fg, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: fg, fontSize: 13))),
      ]),
    );
  }
}

// ── ParfumCard (contenedor blanco con borde) ──────────────────────
class ParfumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const ParfumCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

// ── ParfumDropdown ────────────────────────────────────────────────
class ParfumDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final void Function(String?) onChanged;

  const ParfumDropdown({
    super.key, required this.label, required this.value,
    required this.options, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          filled: true, fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

// ── LoadingOverlay ────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (isLoading)
      Container(
        color: Colors.black26,
        child: const Center(child: CircularProgressIndicator()),
      ),
  ]);
}
