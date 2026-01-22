import 'package:flutter/material.dart';
import 'package:frontend_commons/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDropThemeData {
  static ThemeData build(Map<String, dynamic> themeJson) {
    final app = (themeJson["app_styling"] ?? {}) as Map<String, dynamic>;

    final font = (app["font_family"] ?? "Inter").toString().trim();
    final toolbarBg = parseHexColor(app["toolbar_bg"]?.toString() ?? "#FFFFFF");
    final toolbarFont = parseHexColor(app["toolbar_font"]?.toString() ?? "#000000");

    final base = ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: toolbarBg ?? Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: toolbarBg,
        foregroundColor: toolbarFont,
        surfaceTintColor: toolbarBg,
        elevation: 0,
      ),
    );

    final tt = _textThemeForFont(font, base.textTheme);

    return base.copyWith(
      textTheme: tt,
      primaryTextTheme: tt, // ✅ important for AppBar / Buttons etc.
    );
  }

  static TextTheme _textThemeForFont(String font, TextTheme base) {
    switch (font.toLowerCase()) {
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme(base);
      case 'Roboto':
        return GoogleFonts.robotoTextTheme(base);
      case 'Open Sans':
      case 'OpenSans':
        return GoogleFonts.openSansTextTheme(base);
      case 'Inter':
      default:
        return GoogleFonts.interTextTheme(base);
    }
  }
}
