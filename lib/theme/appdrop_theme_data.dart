import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appdrop_theme_config.dart';

class AppDropThemeData {
  static ThemeData buildFromConfig(AppDropThemeConfig cfg) {
    final font = cfg.appStyling.fontFamily.trim();
    final content = cfg.appStyling.fontIconColor;

    final base = ThemeData(useMaterial3: true);

    final tt = _textTheme(font, base.textTheme).apply(
      bodyColor: content,
      displayColor: content,
    );

    return base.copyWith(
      textTheme: tt,
      primaryTextTheme: tt,
      iconTheme: IconThemeData(color: content),
      primaryIconTheme: IconThemeData(color: content),
    );
  }

  static TextTheme _textTheme(String font, TextTheme base) {
    switch (font) {
      case "Inter":
        return GoogleFonts.interTextTheme(base);
      case "Roboto":
        return GoogleFonts.robotoTextTheme(base);
      case "Open Sans":
      case "OpenSans":
        return GoogleFonts.openSansTextTheme(base);
      case "Lato":
        return GoogleFonts.latoTextTheme(base);
      case "Poppins":
      default:
        return GoogleFonts.poppinsTextTheme(base);
    }
  }
}
