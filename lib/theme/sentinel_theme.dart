import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shadow Sentinel design system — "Zero Trust" aesthetic.
class SentinelTheme {
  SentinelTheme._();

  // ─── Core Colors ─────────────────────────────────────────
  static const Color bg = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceAlt = Color(0xFF1A2332);
  static const Color border = Color(0xFF1E293B);
  static const Color borderGlow = Color(0x330EA5E9);

  static const Color cyberBlue = Color(0xFF0EA5E9);
  static const Color cyberBlueDim = Color(0x660EA5E9);
  static const Color cyberCyan = Color(0xFF22D3EE);

  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertRedDim = Color(0x66EF4444);
  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color alertGreen = Color(0xFF10B981);
  static const Color alertGreenDim = Color(0x6610B981);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ─── Trust Level Colors ──────────────────────────────────
  static Color trustColor(double score) {
    if (score >= 80) return alertGreen;
    if (score >= 60) return cyberBlue;
    if (score >= 40) return alertAmber;
    return alertRed;
  }

  static String trustLabel(double score) {
    if (score >= 80) return 'VERIFIED';
    if (score >= 60) return 'MONITORING';
    if (score >= 40) return 'CAUTION';
    return 'CRITICAL';
  }

  // ─── Severity Colors ────────────────────────────────────
  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return alertRed;
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return alertAmber;
      case 'low':
        return alertGreen;
      default:
        return textMuted;
    }
  }

  // ─── Productivity State Colors ──────────────────────────
  static Color productivityColor(String state) {
    switch (state) {
      case 'deepWork':
        return cyberBlue;
      case 'focused':
        return alertGreen;
      case 'distracted':
        return alertAmber;
      case 'burnoutRisk':
        return alertRed;
      default:
        return border;
    }
  }

  // ─── Fonts ──────────────────────────────────────────────
  static TextStyle get mono => GoogleFonts.jetBrainsMono();
  static TextStyle get sans => GoogleFonts.inter();

  // ─── Theme Data ─────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: cyberBlue,
        secondary: cyberCyan,
        surface: surface,
        error: alertRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    );
  }

  // ─── Glass Decoration ───────────────────────────────────
  static BoxDecoration glassCard({Color? glowColor}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xCC111827),
          Color(0x991A2332),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: glowColor?.withValues(alpha: 0.15) ?? border,
        width: 1,
      ),
    );
  }
}
