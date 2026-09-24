import 'package:flutter/material.dart';

/// Cor de destaque principal (coral mais forte).
const Color petTrailAccent = Color(0xFFEE5A52);

/// Tom mais escuro para links, foco e estados pressionados.
const Color petTrailAccentDeep = Color(0xFFD93F38);

/// Base neutra (texto, bordas, botões secundários).
const Color petTrailInk = Color(0xFF111827);

/// Coral mais claro para uso no tema escuro.
const Color petTrailAccentLight = Color(0xFFFF7B74);

final ColorScheme petTrailColorScheme = ColorScheme.light(
  primary: petTrailInk,
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFFFFE7E4),
  onPrimaryContainer: const Color(0xFF6B2C26),
  secondary: petTrailAccent,
  onSecondary: Colors.white,
  tertiary: petTrailAccentDeep,
  onTertiary: Colors.white,
  surface: const Color(0xFFF9FAFB),
  onSurface: petTrailInk,
  onSurfaceVariant: const Color(0xFF6B7280),
  outline: const Color(0xFFE5E7EB),
  outlineVariant: const Color(0xFFF3F4F6),
  error: const Color(0xFFDC2626),
  onError: Colors.white,
);

final ColorScheme petTrailDarkColorScheme = ColorScheme.dark(
  primary: const Color(0xFFF9FAFB),
  onPrimary: petTrailInk,
  primaryContainer: const Color(0xFF3D1F1C),
  onPrimaryContainer: const Color(0xFFFFB4AE),
  secondary: petTrailAccentLight,
  onSecondary: petTrailInk,
  tertiary: petTrailAccent,
  onTertiary: Colors.white,
  surface: const Color(0xFF111827),
  onSurface: const Color(0xFFF9FAFB),
  onSurfaceVariant: const Color(0xFF9CA3AF),
  outline: const Color(0xFF374151),
  outlineVariant: const Color(0xFF1F2937),
  error: const Color(0xFFFF6B6B),
  onError: petTrailInk,
);

ThemeData petTrailDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: petTrailDarkColorScheme,
    scaffoldBackgroundColor: petTrailDarkColorScheme.surface,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: petTrailAccentLight,
      selectionColor: petTrailAccentLight.withValues(alpha: 0.3),
      selectionHandleColor: petTrailAccentLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFF1F2937),
      hintStyle: TextStyle(color: petTrailDarkColorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: TextStyle(color: petTrailDarkColorScheme.onSurface.withValues(alpha: 0.75)),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.focused)
              ? petTrailAccentLight
              : petTrailDarkColorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: petTrailInk,
        backgroundColor: petTrailAccentLight,
        disabledForegroundColor: petTrailInk.withValues(alpha: 0.45),
        disabledBackgroundColor: petTrailAccentLight.withValues(alpha: 0.45),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: petTrailDarkColorScheme.onSurface,
        side: BorderSide(color: petTrailDarkColorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: petTrailAccentLight,
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      bodyLarge: TextStyle(color: petTrailDarkColorScheme.onSurface),
      bodyMedium: TextStyle(color: petTrailDarkColorScheme.onSurface),
      bodySmall: TextStyle(color: petTrailDarkColorScheme.onSurfaceVariant),
    ).apply(
      bodyColor: petTrailDarkColorScheme.onSurface,
      displayColor: petTrailDarkColorScheme.onSurface,
    ),
  );
}

ThemeData petTrailTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: petTrailColorScheme,
    scaffoldBackgroundColor: petTrailColorScheme.surface,
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: TextStyle(color: petTrailColorScheme.onSurface.withValues(alpha: 0.75)),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.focused)
              ? petTrailAccentDeep
              : petTrailColorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: petTrailInk,
        backgroundColor: petTrailAccent,
        disabledForegroundColor: petTrailInk.withValues(alpha: 0.45),
        disabledBackgroundColor: petTrailAccent.withValues(alpha: 0.45),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: petTrailInk,
        side: BorderSide(color: petTrailColorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: petTrailAccentDeep,
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.8),
    ).apply(
      bodyColor: petTrailColorScheme.onSurface,
      displayColor: petTrailColorScheme.onSurface,
    ),
  );
}
