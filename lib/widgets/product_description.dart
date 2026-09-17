import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/color.dart';

/// Plain product description text for PDP.
/// Props: enabled, description, descriptionColor, fontVariation, fontSize.
Widget buildProductDescription(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final description = node.s('description', def: '').trim();
  final text = description.isEmpty ? 'Add product details here.' : description;
  final color = parseHexColor(node.s('descriptionColor', def: '#6B7280')) ??
      const Color(0xFF6B7280);
  final size = node.d('fontSize', def: 14).clamp(12, 24).toDouble();
  final weight = _fontVariation(node.s('fontVariation', def: 'regular'));

  final body = LayoutBuilder(
    builder: (context, _) {
      return Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: env.r.sp(size, min: 12, max: 24),
          fontWeight: weight,
          height: 1.45,
        ),
      );
    },
  );
  return wrapPdpStagger(context, PdpStaggerSlot.description, body);
}

FontWeight _fontVariation(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'bold':
      return FontWeight.w700;
    case 'semi_bold':
    case 'semibold':
      return FontWeight.w600;
    case 'regular':
    default:
      return FontWeight.w400;
  }
}
