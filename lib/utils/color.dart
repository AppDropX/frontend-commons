import 'package:flutter/material.dart';

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var s = hex.trim();
  if (s.isEmpty) return null;

  s = s.replaceAll('#', '');
  if (s.length == 3) {
    s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
  }
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;

  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(v);
}
