import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const bluePrimary = Color(0xFF1260DC);
  static const blueSecondary = Color(0xFF3B82F6);
  static const blueDark = Color(0xFF0B4DB3);
  static const blueLight = Color(0xFFDCEAFF);

  static const background = Color(0xFF090D14);
  static const surface = Color(0xFF111827);
  static const surfaceHigh = Color(0xFF182234);
  static const border = Color(0xFF263449);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFB8C4D6);

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: bluePrimary,
      onPrimary: Colors.white,
      primaryContainer: blueDark,
      onPrimaryContainer: Colors.white,
      secondary: blueSecondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF173B70),
      onSecondaryContainer: blueLight,
      tertiary: Color(0xFF38BDF8),
      onTertiary: Color(0xFF06131D),
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceHigh,
      outline: border,
      outlineVariant: Color(0xFF1E2A3C),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: textPrimary,
      onInverseSurface: Color(0xFF111827),
      inversePrimary: Color(0xFF8AB4FF),
    );

    final rounded16 = BorderRadius.circular(16);
    final rounded14 = BorderRadius.circular(14);
    final rounded12 = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: rounded16,
          side: const BorderSide(color: border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: rounded16),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(color: textSecondary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: Color(0xFF74839A)),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: rounded14,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: rounded14,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rounded14,
          borderSide: const BorderSide(color: bluePrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: rounded14,
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: rounded14,
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.8),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: bluePrimary,
          disabledBackgroundColor: const Color(0xFF334155),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: rounded12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: bluePrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: rounded12),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blueLight,
          side: const BorderSide(color: bluePrimary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: rounded12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6EA8FF),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: bluePrimary,
        focusColor: blueDark,
        hoverColor: blueSecondary,
        elevation: 2,
      ),

      iconTheme: const IconThemeData(color: textSecondary),
      primaryIconTheme: const IconThemeData(color: Colors.white),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF173B70),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF8AB4FF));
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF8AB4FF)
                : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0xFF173B70),
        selectedIconTheme: IconThemeData(color: Color(0xFF8AB4FF)),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: Color(0xFF8AB4FF),
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(color: textSecondary),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF8AB4FF),
        unselectedLabelColor: textSecondary,
        indicatorColor: bluePrimary,
        dividerColor: border,
        labelStyle: TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: const Color(0xFF173B70),
        disabledColor: const Color(0xFF202B3B),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: rounded12),
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF8AB4FF),
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        checkmarkColor: const Color(0xFF8AB4FF),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: bluePrimary,
        linearTrackColor: Color(0xFF243248),
        circularTrackColor: Color(0xFF243248),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF94A3B8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? bluePrimary
              : const Color(0xFF334155);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? bluePrimary
              : Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? bluePrimary
              : textSecondary;
        }),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: bluePrimary,
        inactiveTrackColor: Color(0xFF334155),
        thumbColor: Color(0xFF8AB4FF),
        overlayColor: Color(0x331260DC),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary),
        actionTextColor: const Color(0xFF8AB4FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: rounded12),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: rounded12),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: blueDark,
        headerForegroundColor: Colors.white,
        dayForegroundColor: const WidgetStatePropertyAll(textPrimary),
        todayForegroundColor: const WidgetStatePropertyAll(Color(0xFF8AB4FF)),
        todayBorder: const BorderSide(color: bluePrimary),
        dayOverlayColor: const WidgetStatePropertyAll(Color(0x221260DC)),
        shape: RoundedRectangleBorder(borderRadius: rounded16),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        textStyle: const TextStyle(color: textPrimary),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: bluePrimary,
        selectionColor: Color(0x551260DC),
        selectionHandleColor: bluePrimary,
      ),
    );
  }
}
