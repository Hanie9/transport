import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surface,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.cardShadow,
  });

  final Color surface;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final List<BoxShadow> cardShadow;

  @override
  AppPalette copyWith({
    Color? surface,
    Color? cardBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    List<BoxShadow>? cardShadow,
  }) {
    return AppPalette(
      surface: surface ?? this.surface,
      cardBg: cardBg ?? this.cardBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardShadow: cardShadow,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  static const String vazirFamily = 'Vazir';
  static const String interFamily = 'Inter';
  static const String brandFamily = 'Nasalization';

  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0D5C56);
  static const Color accent = Color(0xFFF97316);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static List<BoxShadow> cardShadowFor(Brightness brightness) => [
        BoxShadow(
          color: (brightness == Brightness.dark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: (brightness == Brightness.dark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: brightness == Brightness.dark ? 0.2 : 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadow => cardShadowFor(Brightness.light);

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryLight],
      );

  /// Persian → bundled Vazir; English → bundled Inter (no Google Fonts).
  static ThemeData light({bool useVazir = true}) => _buildTheme(
        brightness: Brightness.light,
        palette: AppPalette(
          surface: surface,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          divider: const Color(0xFFF1F5F9),
          cardShadow: cardShadowFor(Brightness.light),
        ),
        useVazir: useVazir,
      );

  static ThemeData dark({bool useVazir = true}) => _buildTheme(
        brightness: Brightness.dark,
        palette: AppPalette(
          surface: darkSurface,
          cardBg: darkCardBg,
          textPrimary: darkTextPrimary,
          textSecondary: darkTextSecondary,
          divider: const Color(0xFF334155),
          cardShadow: cardShadowFor(Brightness.dark),
        ),
        useVazir: useVazir,
      );

  static TextStyle textStyle({
    required String fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppPalette palette,
    required bool useVazir,
  }) {
    final isDark = brightness == Brightness.dark;
    final fontFamily = useVazir ? vazirFamily : interFamily;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: isDark ? primaryLight : primary,
        secondary: accent,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      extensions: [palette],
    );

    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    TextStyle style({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? letterSpacing,
    }) {
      return textStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return base.copyWith(
      scaffoldBackgroundColor: palette.surface,
      textTheme: textTheme,
      dividerColor: palette.divider,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: style(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: style(color: palette.textSecondary),
        hintStyle: style(color: palette.textSecondary.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? primaryLight : primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: style(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primaryLight : primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
          textStyle: style(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: style(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        backgroundColor: palette.cardBg,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.cardBg,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return style(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? (isDark ? primaryLight : primary) : palette.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? (isDark ? primaryLight : primary) : palette.textSecondary,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? primaryLight : primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? const Color(0xFFE2E8F0) : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? primaryLight : primary;
          }
          return isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark ? primaryLight : primary).withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
    );
  }
}
