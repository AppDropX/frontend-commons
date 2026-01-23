import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../theme/appdrop_theme_scope.dart';

Widget buildProductBlock(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final cfg = AppDropThemeScope.maybeOf(context);

  // Merge: theme.productBlock (defaults) <- node.props (override)
  final merged = <String, dynamic>{};
  if (cfg != null) merged.addAll(cfg.productBlock);
  merged.addAll(node.props);

  bool b(String k, bool def) {
    final v = merged[k];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return def;
  }

  String s(String k, String def) => (merged[k] ?? def).toString();
  int i(String k, int def) {
    final v = merged[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  double d(String k, double def) {
    final v = merged[k];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  final showSelling = b('show_selling_price', true);
  final showRetail = b('show_retail_price', true);
  final showStrike = b('show_strike_through', true);
  final showDiscount = b('show_discount', true);
  final showRating = b('show_rating', true);
  final showRatingCount = b('show_rating_count', true);
  final showVendor = b('show_vendor', true);
  final showSwatches = b('show_swatches', true);

  final priceFont = s('price_font', 'Regular').toLowerCase(); // Bold
  final discountSize = s('discount_size', 'Small').toLowerCase();

  final aspectIdx = i('image_aspect_ratio_index', 0);
  final fitIdx = i('image_position_index', 0); // ✅ 0=crop, 1=fit
  final boxFit = (fitIdx == 1) ? BoxFit.contain : BoxFit.cover;
  final titleBehaviorIdx = i('title_text_behavior_index', 0); // 0 wrap, 1 clip
  final titleAlignIdx = i('title_text_alignment_index', 0);

  final radiusDp = d('corner_radius', 12);
  final maxLines = i('max_lines', 2);
  final padDp = d('card_padding', 12);

  final imageBg = parseHexColor(s('image_bg_color', '#E0E0E0')) ?? const Color(0xFFE0E0E0);
  final priceColor = parseHexColor(s('price_color', '#000000')) ?? Colors.black;
  final discountColor = parseHexColor(s('discount_color', '#FF0000')) ?? Colors.red;
  final ratingColor = parseHexColor(s('rating_color', '#FFA500')) ?? Colors.orange;
  final titleColor = parseHexColor(s('title_color', '#000000')) ?? Colors.black;

  final product = node.m('product') ?? <String, dynamic>{};
  final title = (product['title'] ?? '').toString();
  final vendor = (product['vendor'] ?? '').toString();
  final imageUrl = (product['imageUrl'] ?? '').toString();

  final sellingPrice = _toDouble(product['sellingPrice']);
  final retailPrice = _toDouble(product['retailPrice']);
  final discountPercent = _toInt(product['discountPercent']);

  final rating = _toDouble(product['rating']);
  final ratingCount = _toInt(product['ratingCount']);

  final swatchesRaw = (product['swatches'] is List) ? (product['swatches'] as List) : const [];
  final swatches = swatchesRaw.map((e) => parseHexColor(e.toString())).whereType<Color>().toList();

  final action = node.m('action');

  final aspect = _aspectFromIndex(aspectIdx);
  final align = _alignFromIndex(titleAlignIdx);
  final titleMaxLines = (titleBehaviorIdx == 1) ? 1 : (maxLines <= 0 ? null : maxLines);
  final priceWeight = priceFont == 'bold' ? FontWeight.w700 : FontWeight.w400;
  final discountSp = _discountSp(discountSize, env.r);

  final image = ClipRRect(
    borderRadius: BorderRadius.circular(env.r.dp(radiusDp)),
    child: AspectRatio(
      aspectRatio: aspect,
      child: Container(
        color: imageBg,
        child: imageUrl.isEmpty
            ? const SizedBox.expand()
            : Image.network(
          imageUrl,
          fit: boxFit, //  crop/fit toggle works
          alignment: Alignment.center,
        ),
      ),
    ),
  );

  final meta = Padding(
    padding: EdgeInsets.all(env.r.dp(padDp)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _cross(align),
      children: [
        if (showVendor && vendor.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: env.r.dp(6)),
            child: Text(
              vendor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: align,
              style: TextStyle(fontSize: env.r.sp(12, min: 10, max: 14), color: Colors.black54),
            ),
          ),

        Text(
          title,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            fontSize: env.r.sp(14, min: 12, max: 16),
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),

        SizedBox(height: env.r.dp(10)),

        if (showRating && rating > 0)
          Padding(
            padding: EdgeInsets.only(bottom: env.r.dp(10)),
            child: Row(
              mainAxisAlignment: _main(align),
              children: [
                Icon(Icons.star, size: env.r.dp(16), color: ratingColor),
                SizedBox(width: env.r.dp(4)),
                Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: env.r.sp(12), fontWeight: FontWeight.w600)),
                if (showRatingCount && ratingCount > 0) ...[
                  SizedBox(width: env.r.dp(6)),
                  Text('($ratingCount)', style: TextStyle(fontSize: env.r.sp(12), color: Colors.black54)),
                ]
              ],
            ),
          ),

        Row(
          mainAxisAlignment: _main(align),
          children: [
            if (showSelling && sellingPrice > 0)
              Text('₹${sellingPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: env.r.sp(14), fontWeight: priceWeight, color: priceColor)),

            if (showRetail && retailPrice > 0) ...[
              SizedBox(width: env.r.dp(8)),
              Text(
                '₹${retailPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: env.r.sp(12),
                  color: Colors.black54,
                  decoration: showStrike ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ],

            if (showDiscount && discountPercent > 0) ...[
              SizedBox(width: env.r.dp(8)),
              Text('$discountPercent% OFF',
                  style: TextStyle(fontSize: discountSp, fontWeight: FontWeight.w700, color: discountColor)),
            ],
          ],
        ),

        if (showSwatches && swatches.isNotEmpty) ...[
          SizedBox(height: env.r.dp(12)),
          Row(
            mainAxisAlignment: _main(align),
            children: swatches.take(6).map((c) {
              return Container(
                width: env.r.dp(14),
                height: env.r.dp(14),
                margin: EdgeInsets.only(right: env.r.dp(6)),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
              );
            }).toList(),
          ),
        ],

      ],
    ),
  );

  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [image, meta],
  );

  Widget card = ClipRRect(
    borderRadius: BorderRadius.circular(env.r.dp(radiusDp)),
    child: DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
      child: body,
    ),
  );

  if (action != null) {
    card = InkWell(onTap: () => env.dispatchAction(context, action), child: card);
  }
  return card;
}

double _aspectFromIndex(int idx) {
  switch (idx) {
    case 0: // Smart
      return 1.0; // ✅ grid uniform chahiye, so safest square
    case 1: // Square
      return 1.0;
    case 2: // Portrait
      return 4 / 5;
    case 3: // Landscape
      return 16 / 9;
    default:
      return 1.0;
  }
}


TextAlign _alignFromIndex(int idx) {
  switch (idx) {
    case 1:
      return TextAlign.center;
    case 2:
      return TextAlign.right;
    default:
      return TextAlign.left;
  }
}

CrossAxisAlignment _cross(TextAlign a) => a == TextAlign.center
    ? CrossAxisAlignment.center
    : a == TextAlign.right
    ? CrossAxisAlignment.end
    : CrossAxisAlignment.start;

MainAxisAlignment _main(TextAlign a) => a == TextAlign.center
    ? MainAxisAlignment.center
    : a == TextAlign.right
    ? MainAxisAlignment.end
    : MainAxisAlignment.start;

double _discountSp(String size, dynamic r) {
  if (size == 'large') return r.sp(14, min: 12, max: 16);
  if (size == 'medium') return r.sp(12, min: 10, max: 14);
  return r.sp(10, min: 9, max: 12);
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
