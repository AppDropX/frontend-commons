import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appdrop_theme_config.dart';

class AppDropThemeData {
  static ThemeData buildFromConfig(AppDropThemeConfig cfg) {
    final font = cfg.appStyling.fontFamily.trim();

    final base = ThemeData(useMaterial3: true);

    final tt = _textTheme(font, base.textTheme);

    return base.copyWith(
      textTheme: tt,
      primaryTextTheme: tt, // ✅ AppBar/Buttons etc
    );
  }

  static TextTheme _textTheme(String font, TextTheme base) {
    switch (font.toLowerCase()) {
      case "Poppins":
        return GoogleFonts.poppinsTextTheme(base);
      case "Roboto":
        return GoogleFonts.robotoTextTheme(base);
      case "Open Sans":
      case "OpenSans":
        return GoogleFonts.openSansTextTheme(base);
      case "Inter":
      default:
        return GoogleFonts.interTextTheme(base);
    }
  }
}
