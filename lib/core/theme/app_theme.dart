import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        // primary: Colors.yellow,
        // secondary: Colors.green.shade200,
        // onPrimaryFixed: Colors.blue.shade300,
        primary: Colors.blue,
        secondary: Colors.purple,
        onPrimaryFixed: Colors.orange,
        tertiary: const Color.fromARGB(255, 255, 255, 154),
        surface: const Color.fromARGB(255, 225, 225, 225),
        surfaceDim: const Color.fromARGB(235, 215, 215, 215),
        onSurface: Colors.black,
        surfaceBright: const Color.fromARGB(60, 97, 97, 97),
        surfaceContainer: Color.fromARGB(255, 240, 240, 240),
        surfaceContainerHighest: const Color.fromARGB(220, 230, 230, 230),
      ),
      drawerTheme: DrawerThemeData(
        scrimColor: const Color.fromARGB(155, 0, 0, 0),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue,
        secondary: Colors.purple,
        onPrimaryFixed: Colors.orange,
        tertiary: const Color.fromARGB(70, 0, 162, 255),
        surface: const Color.fromARGB(255, 30, 30, 30),
        surfaceDim: const Color.fromARGB(235, 30, 30, 30),
        onSurface: Colors.white,
        surfaceBright: const Color.fromARGB(185, 100, 100, 100),
        surfaceContainer: Color.fromARGB(255, 65, 65, 65),
        surfaceContainerHighest: const Color.fromARGB(220, 30, 30, 30),
      ),
      drawerTheme: DrawerThemeData(
        scrimColor: const Color.fromARGB(185, 100, 100, 100),
      ),
    );
  }
}
