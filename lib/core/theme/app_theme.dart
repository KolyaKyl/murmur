import 'package:flutter/material.dart';

/// Радиусы. До этого по коду были рассыпаны 12, 16, 8, 10, 20, 4, 2 —
/// без всякой системы. Здесь их четыре, и больше добавлять не нужно.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Отступы. Шаг 4, как в Material.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Цвета состояний индекса настроения. В теме их нет — это не роли Material,
/// а собственная семантика продукта, поэтому живут расширением.
@immutable
class MoodStatusColors extends ThemeExtension<MoodStatusColors> {
  const MoodStatusColors({
    required this.peak,
    required this.high,
    required this.average,
    required this.low,
    required this.bottom,
    required this.empty,
  });

  final Color peak;
  final Color high;
  final Color average;
  final Color low;
  final Color bottom;
  final Color empty;

  static const light = MoodStatusColors(
    peak: Color(0xFF673AB7),
    high: Color(0xFF2E7D32),
    average: Color(0xFFF9A825),
    low: Color(0xFFEF6C00),
    bottom: Color(0xFFC62828),
    empty: Color(0xFF757575),
  );

  static const dark = MoodStatusColors(
    peak: Color(0xFFB39DDB),
    high: Color(0xFF81C784),
    average: Color(0xFFFFD54F),
    low: Color(0xFFFFB74D),
    bottom: Color(0xFFE57373),
    empty: Color(0xFF9E9E9E),
  );

  @override
  MoodStatusColors copyWith({
    Color? peak,
    Color? high,
    Color? average,
    Color? low,
    Color? bottom,
    Color? empty,
  }) =>
      MoodStatusColors(
        peak: peak ?? this.peak,
        high: high ?? this.high,
        average: average ?? this.average,
        low: low ?? this.low,
        bottom: bottom ?? this.bottom,
        empty: empty ?? this.empty,
      );

  @override
  MoodStatusColors lerp(ThemeExtension<MoodStatusColors>? other, double t) {
    if (other is! MoodStatusColors) return this;
    return MoodStatusColors(
      peak: Color.lerp(peak, other.peak, t)!,
      high: Color.lerp(high, other.high, t)!,
      average: Color.lerp(average, other.average, t)!,
      low: Color.lerp(low, other.low, t)!,
      bottom: Color.lerp(bottom, other.bottom, t)!,
      empty: Color.lerp(empty, other.empty, t)!,
    );
  }
}

extension MoodStatusColorsX on ThemeData {
  MoodStatusColors get moodStatus => extension<MoodStatusColors>()!;
}

class AppTheme {
  /// Палитра намеренно оставлена прежней — переносим её в систему,
  /// а не придумываем новую.
  static const _lightScheme = ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.purple,
    onPrimaryFixed: Colors.orange,
    tertiary: Color.fromARGB(255, 255, 255, 154),
    surface: Color.fromARGB(255, 225, 225, 225),
    surfaceDim: Color.fromARGB(235, 215, 215, 215),
    onSurface: Colors.black,
    onSurfaceVariant: Color(0xFF5F5F5F),
    outline: Color(0xFFB0B0B0),
    outlineVariant: Color(0xFFD4D4D4),
    surfaceBright: Color.fromARGB(60, 97, 97, 97),
    surfaceContainer: Color.fromARGB(255, 240, 240, 240),
    surfaceContainerHighest: Color.fromARGB(220, 230, 230, 230),
    error: Color(0xFFC62828),
  );

  static const _darkScheme = ColorScheme.dark(
    primary: Colors.blue,
    secondary: Colors.purple,
    onPrimaryFixed: Colors.orange,
    tertiary: Color.fromARGB(70, 0, 162, 255),
    surface: Color.fromARGB(255, 30, 30, 30),
    surfaceDim: Color.fromARGB(235, 30, 30, 30),
    onSurface: Colors.white,
    onSurfaceVariant: Color(0xFFB5B5B5),
    outline: Color(0xFF6E6E6E),
    outlineVariant: Color(0xFF3A3A3A),
    surfaceBright: Color.fromARGB(185, 100, 100, 100),
    surfaceContainer: Color.fromARGB(255, 65, 65, 65),
    surfaceContainerHighest: Color.fromARGB(220, 30, 30, 30),
    error: Color(0xFFE57373),
  );

  static ThemeData light() => _build(_lightScheme, MoodStatusColors.light);
  static ThemeData dark() => _build(_darkScheme, MoodStatusColors.dark);

  static ThemeData _build(ColorScheme scheme, MoodStatusColors status) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [status],
      textTheme: _textTheme(base.textTheme, scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceDim,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
        labelStyle: TextStyle(color: scheme.onSurface),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        backgroundColor: scheme.surfaceContainer,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }

  /// Гарнитура системная — как было до появления этого файла.
  /// Здесь задаются только роли: цвета и насыщенности.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final t = base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return t.copyWith(
      headlineMedium: t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: t.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
