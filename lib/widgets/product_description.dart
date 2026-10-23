import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/color.dart';
import 'product_html_description.dart';

/// Product description for PDP. HTML from the catalog is rendered as
/// paragraphs, lists, and bold text. Plain copy stays a single [Text].
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
  final showTitle = node.b('showTitle');
  final title = node.s('title', def: '').trim();
  final color = parseHexColor(node.s('descriptionColor', def: '#6B7280')) ??
      const Color(0xFF6B7280);
  final size = node.d('fontSize', def: 14).clamp(12, 24).toDouble();
  final weight = _fontVariation(node.s('fontVariation', def: 'regular'));
  final titleColor = parseHexColor(node.s('titleColor', def: '#111827')) ??
      const Color(0xFF111827);
  final titleSize = node.d('titleFontSize', def: 16).clamp(12, 24).toDouble();
  final titleWeight = _fontVariation(
    node.s('titleFontVariation', def: 'semi_bold'),
  );
  final fontFamily =
      AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';

  final body = LayoutBuilder(
    builder: (context, _) {
      final style = AppDropThemeData.textStyle(
        fontFamily: fontFamily,
        fontSize: env.r.sp(size, min: 12, max: 24),
        fontWeight: weight,
        color: color,
      ).copyWith(height: 1.45);
      final descriptionView = productDescriptionLooksLikeHtml(text)
          ? ProductHtmlDescription(
              html: text,
              style: style,
              r: env.r,
              fontFamily: fontFamily,
            )
          : Text(text, style: style);
      if (!showTitle || title.isEmpty) return descriptionView;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppDropThemeData.textStyle(
              fontFamily: fontFamily,
              fontSize: env.r.sp(titleSize, min: 12, max: 24),
              fontWeight: titleWeight,
              color: titleColor,
            ).copyWith(height: 1.3),
          ),
          SizedBox(height: env.r.dp(8)),
          descriptionView,
        ],
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
