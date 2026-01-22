import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appdrop_theme_config.dart';

class AppDropThemeData {
  static ThemeData build(AppDropThemeConfig cfg) {
    final base = ThemeData(useMaterial3: true);

    final font = cfg.appStyling.fontFamily.trim().toLowerCase();
    TextTheme textTheme = base.textTheme;

    if (font == 'Poppins') {
      textTheme = GoogleFonts.poppinsTextTheme(textTheme);
    } else if (font == 'Inter') {
      textTheme = GoogleFonts.interTextTheme(textTheme);
    } else if (font == 'Roboto') {
      textTheme = GoogleFonts.robotoTextTheme(textTheme);
    } else if (font == 'Open Sans' || font == 'OpenSans') {
      textTheme = GoogleFonts.openSansTextTheme(textTheme);
    }

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: cfg.appStyling.toolbarBg,
        foregroundColor: cfg.appStyling.toolbarFont,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
