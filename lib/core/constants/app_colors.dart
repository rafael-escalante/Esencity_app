import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Fondo y superficies ────────────────────────────────────────
  static const Color background   = Color(0xFFF5F4F0);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFE0DDD6);
  static const Color borderLight  = Color(0xFFF0EDE8);
  static const Color inputBorder  = Color(0xFFD0CDC6);
  static const Color textPrimary  = Color(0xFF1A1A1A);
  static const Color textSecondary= Color(0xFF666666);
  static const Color textMuted    = Color(0xFF999999);

  // ── GERENTE (morado) ──────────────────────────────────────────
  static const Color gerenteNavbar    = Color(0xFF2C1654);
  static const Color gerentePrimary   = Color(0xFF2C1654);
  static const Color gerenteHover     = Color(0xFF3D2070);
  static const Color gerenteAccent    = Color(0xFFC9A96E);
  static const Color gerenteFocus     = Color(0xFF7C4DCA);
  static const Color gerenteFocusBg   = Color(0xFFF0ECFA);

  // ── CAJERO (azul) ─────────────────────────────────────────────
  static const Color cajeroNavbar     = Color(0xFF1554A0);
  static const Color cajeroPrimary    = Color(0xFF1554A0);
  static const Color cajeroHover      = Color(0xFF1868C8);
  static const Color cajeroAccent     = Color(0xFF378BDD);
  static const Color cajeroFocusBg    = Color(0xFFD0E8FF);

  // ── ALMACENISTA (dorado) ──────────────────────────────────────
  static const Color almacenistaNavbar  = Color(0xFF8B5E07);
  static const Color almacenistaPrimary = Color(0xFF8B5E07);
  static const Color almacenistaHover   = Color(0xFFA06E0A);
  static const Color almacenistaAccent  = Color(0xFFC9A96E);

  // ── CLIENTE (verde) ───────────────────────────────────────────
  static const Color clienteNavbar    = Color(0xFF1A7F4B);
  static const Color clientePrimary   = Color(0xFF1A7F4B);
  static const Color clienteHover     = Color(0xFF155C36);
  static const Color clienteAccent    = Color(0xFF27AE60);

  // ── Botones semánticos ────────────────────────────────────────
  static const Color danger       = Color(0xFFC0392B);
  static const Color dangerHover  = Color(0xFFA93226);
  static const Color warning      = Color(0xFFC9A96E);
  static const Color warningHover = Color(0xFFB8954F);
  static const Color success      = Color(0xFF1A7F4B);
  static const Color successHover = Color(0xFF155C36);

  // ── Badges ────────────────────────────────────────────────────
  static const Color badgeActiveText   = Color(0xFF1A7F4B);
  static const Color badgeActiveBg     = Color(0xFFD4F1E4);
  static const Color badgePendingText  = Color(0xFF8B5E07);
  static const Color badgePendingBg    = Color(0xFFFEF3D0);
  static const Color badgeReadyText    = Color(0xFF1554A0);
  static const Color badgeReadyBg      = Color(0xFFD0E8FF);
  static const Color badgeDoneText     = Color(0xFF5C2D99);
  static const Color badgeDoneBg       = Color(0xFFE8D0FF);
  static const Color badgeLowText      = Color(0xFFC0392B);
  static const Color badgeLowBg        = Color(0xFFFDE8E8);
  static const Color badgeInactiveText = Color(0xFFC0392B);
  static const Color badgeInactiveBg   = Color(0xFFFDE8E8);
  static const Color badgeCanceledText = Color(0xFF888888);
  static const Color badgeCanceledBg   = Color(0xFFF5F4F0);

  // ── Notificaciones ────────────────────────────────────────────
  static const Color notifSuccessBg    = Color(0xFFD4F1E4);
  static const Color notifSuccessBorder= Color(0xFFA8DFC7);
  static const Color notifSuccessText  = Color(0xFF1A7F4B);
  static const Color notifErrorBg      = Color(0xFFFDE8E8);
  static const Color notifErrorBorder  = Color(0xFFF5C0C0);
  static const Color notifErrorText    = Color(0xFFC0392B);
  static const Color notifWarnBg       = Color(0xFFFEF3D0);
  static const Color notifWarnBorder   = Color(0xFFF5D98A);
  static const Color notifWarnText     = Color(0xFF8B5E07);

  // ── Helpers por rol ───────────────────────────────────────────
  static Color primaryForRole(String rol) {
    switch (rol) {
      case 'gerente':     return gerentePrimary;
      case 'cajero':      return cajeroPrimary;
      case 'almacenista': return almacenistaPrimary;
      case 'cliente':     return clientePrimary;
      default:            return gerentePrimary;
    }
  }

  static Color navbarForRole(String rol) {
    switch (rol) {
      case 'gerente':     return gerenteNavbar;
      case 'cajero':      return cajeroNavbar;
      case 'almacenista': return almacenistaNavbar;
      case 'cliente':     return clienteNavbar;
      default:            return gerenteNavbar;
    }
  }
}
