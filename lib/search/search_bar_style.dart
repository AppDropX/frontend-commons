import 'package:flutter/material.dart';

import '../utils/color.dart';

const String kSearchBarBlockType = 'search_bar';
const String kSearchBarDefaultHint = 'Search products';
const int kSearchBarHintMaxChars = 40;
const int kSearchBarMaxHints = 6;

const Color kSearchBarDefaultBackground = Color(0xFFFFFFFF);
const Color kSearchBarDefaultBorder = Color(0xFFE5E7EB);
const Color kSearchBarDefaultHintColor = Color(0xFF9CA3AF);
const double kSearchBarDefaultCornerRadius = 12;

bool isSearchBarBlockType(String? type) =>
    (type ?? '').trim().toLowerCase() == kSearchBarBlockType;

/// Styling + rotating hint phrases for the search-page search bar.
class AppDropSearchBarStyle {
  const AppDropSearchBarStyle({
    this.backgroundColor = kSearchBarDefaultBackground,
    this.borderColor = kSearchBarDefaultBorder,
    this.hintTextColor = kSearchBarDefaultHintColor,
    this.cornerRadius = kSearchBarDefaultCornerRadius,
    this.hintTexts = const [kSearchBarDefaultHint],
  });

  static const defaults = AppDropSearchBarStyle();

  final Color backgroundColor;
  final Color borderColor;
  final Color hintTextColor;
  final double cornerRadius;
  final List<String> hintTexts;

  factory AppDropSearchBarStyle.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    final radius = _readDouble(data['cornerRadius'] ?? data['borderRadius'])
            ?.clamp(0, 24)
            .toDouble() ??
        kSearchBarDefaultCornerRadius;
    return AppDropSearchBarStyle(
      backgroundColor: parseHexColor(
            (data['backgroundColor'] ?? '').toString(),
          ) ??
          kSearchBarDefaultBackground,
      borderColor: parseHexColor(
            (data['borderColor'] ?? '').toString(),
          ) ??
          kSearchBarDefaultBorder,
      hintTextColor: parseHexColor(
            (data['hintTextColor'] ?? '').toString(),
          ) ??
          kSearchBarDefaultHintColor,
      cornerRadius: radius,
      hintTexts: parseSearchBarHintTexts(data),
    );
  }

  List<String> get rotatingHints {
    if (hintTexts.isEmpty) return const [kSearchBarDefaultHint];
    return hintTexts;
  }

  bool get usesTypewriter => rotatingHints.length > 1;
}

List<String> parseSearchBarHintTexts(Map<String, dynamic> data) {
  final fromList = data['hintTexts'] ?? data['hint_texts'];
  if (fromList is List) {
    final out = <String>[];
    for (final e in fromList) {
      final text = _clampHint(e.toString().trim());
      if (text.isEmpty) continue;
      out.add(text);
      if (out.length >= kSearchBarMaxHints) break;
    }
    if (out.isNotEmpty) return out;
  }
  final single = _clampHint(
    (data['hintText'] ?? data['hint_text'] ?? data['placeholder'] ?? '')
        .toString()
        .trim(),
  );
  if (single.isNotEmpty) return [single];
  return const [kSearchBarDefaultHint];
}

AppDropSearchBarStyle searchBarStyleFromPageJson(
  List<Map<String, dynamic>> pageJson,
) {
  for (final block in pageJson) {
    if (isSearchBarBlockType(block['type']?.toString())) {
      return AppDropSearchBarStyle.fromMap(block);
    }
  }
  return AppDropSearchBarStyle.defaults;
}

List<Map<String, dynamic>> pageJsonWithoutSearchBar(
  List<Map<String, dynamic>> pageJson,
) {
  return [
    for (final block in pageJson)
      if (!isSearchBarBlockType(block['type']?.toString())) block,
  ];
}

String _clampHint(String value) {
  if (value.length <= kSearchBarHintMaxChars) return value;
  return value.substring(0, kSearchBarHintMaxChars);
}

double? _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
