import 'package:flutter/widgets.dart';

import '../product/product_variant_model.dart';
import '../src/responsive.dart';
import 'color.dart';

/// Theme API stores newer product-block options under `config` because
/// top-level keys outside the schema are rejected. Block data may still
/// set the same key at the top level; `config` wins when both exist.
String productBlockSetting(
  Map<String, dynamic> block,
  String key,
  String fallback,
) {
  final config = block['config'];
  if (config is Map) {
    final nested = config[key];
    if (nested != null) {
      final text = nested.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  final top = block[key];
  if (top != null) {
    final text = top.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

bool productBlockThemeBool(Map<String, dynamic> merged, String key, bool def) {
  final v = merged[key];
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return def;
}

String displayProductTitle(String title, bool upperCase) =>
    upperCase ? title.toUpperCase() : title;

double productTitleFontSize(String size, R r) {
  final normalized = size.trim().toLowerCase();
  if (normalized == 'large') return r.sp(16, min: 14, max: 20);
  if (normalized == 'small') return r.sp(12, min: 11, max: 14);
  return r.sp(14, min: 12, max: 16);
}

double productCtaFontSize(String size, R r) {
  final normalized = size.trim().toLowerCase();
  if (normalized == 'large') return r.sp(14, min: 13, max: 15);
  if (normalized == 'small') return r.sp(12, min: 11, max: 13);
  return r.sp(13, min: 12, max: 14);
}

FontWeight productCtaFontWeight(String raw) {
  final normalized =
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  switch (normalized) {
    case 'bold':
      return FontWeight.w800;
    case 'semibold':
      return FontWeight.w600;
    case 'regular':
    default:
      return FontWeight.w400;
  }
}

bool productBlockSettingBool(
  Map<String, dynamic> block,
  String key,
  bool fallback,
) {
  final config = block['config'];
  dynamic raw;
  if (config is Map && config.containsKey(key)) {
    raw = config[key];
  } else if (block.containsKey(key)) {
    raw = block[key];
  }
  if (raw == null) return fallback;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final text = raw.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

/// Outlined vs filled comes from `button_type`. Older themes only stored it
/// inside `button_style` (`rounded_outlined`).
/// Label and colors for a product card Add to cart button when the product
/// is sold out. Null while the product can still be bought.
class ProductSoldOutCta {
  const ProductSoldOutCta({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

ProductSoldOutCta? productSoldOutCta(
  Map<String, dynamic> productBlock,
  Map<String, dynamic> product,
) {
  if (catalogProductIsInStock(product)) return null;
  final label = productBlockSetting(productBlock, 'sold_out_cta_text', 'Sold Out');
  return ProductSoldOutCta(
    label: label.trim().isEmpty ? 'Sold Out' : label,
    background: parseHexColor(
          productBlockSetting(productBlock, 'sold_out_button_bg', '#9CA3AF'),
        ) ??
        const Color(0xFF9CA3AF),
    foreground: parseHexColor(
          productBlockSetting(productBlock, 'sold_out_button_color', '#FFFFFF'),
        ) ??
        const Color(0xFFFFFFFF),
  );
}

bool productBlockButtonOutlined(Map<String, dynamic> block) {
  final type = productBlockSetting(block, 'button_type', '').toLowerCase();
  if (type == 'outlined') return true;
  if (type == 'filled' || type == 'text') return false;
  final style = (block['button_style'] ?? '').toString().toLowerCase();
  return style.contains('outlined');
}

/// Corner radius in logical pixels. `config.button_corner_radius` wins.
/// Older Corner / Rounded / Blunt styles map to 0 / 8 / 24.
double productButtonCornerRadiusDp(Map<String, dynamic> block) {
  final raw = productBlockSetting(block, 'button_corner_radius', '');
  final parsed = double.tryParse(raw);
  if (parsed != null) return parsed.clamp(0, 24);
  final style = (block['button_style'] ?? '').toString().toLowerCase();
  final shape = style.split(RegExp(r'[_\-\s]+')).firstWhere(
        (part) => part.isNotEmpty,
        orElse: () => '',
      );
  switch (shape) {
    case 'blunt':
    case 'pill':
      return 24;
    case 'rounded':
      return 8;
    default:
      return 0;
  }
}

FontWeight titleFontWeightFromVariation(String raw) {
  final normalized =
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  switch (normalized) {
    case 'bold':
      return FontWeight.w700;
    case 'semibold':
      return FontWeight.w600;
    case 'regular':
    default:
      return FontWeight.w400;
  }
}

class WishlistBadgeMetrics {
  const WishlistBadgeMetrics({required this.iconDp, required this.padDp});

  final double iconDp;
  final double padDp;
}

WishlistBadgeMetrics wishlistBadgeMetrics(String size) {
  switch (size.trim().toLowerCase()) {
    case 'large':
      return const WishlistBadgeMetrics(iconDp: 16, padDp: 5);
    case 'medium':
      return const WishlistBadgeMetrics(iconDp: 14, padDp: 4);
    case 'small':
    default:
      return const WishlistBadgeMetrics(iconDp: 12, padDp: 3);
  }
}

enum ProductBadgeCorner { topLeft, topRight, bottomLeft, bottomRight }

ProductBadgeCorner productBadgeCornerFromApi(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(' ', '_');
  switch (normalized) {
    case 'top_left':
      return ProductBadgeCorner.topLeft;
    case 'bottom_left':
      return ProductBadgeCorner.bottomLeft;
    case 'bottom_right':
      return ProductBadgeCorner.bottomRight;
    case 'top_right':
    default:
      return ProductBadgeCorner.topRight;
  }
}

Widget productBadgePositioned({
  required ProductBadgeCorner corner,
  required double inset,
  required Widget child,
}) {
  switch (corner) {
    case ProductBadgeCorner.topLeft:
      return Positioned(left: inset, top: inset, child: child);
    case ProductBadgeCorner.bottomLeft:
      return Positioned(left: inset, bottom: inset, child: child);
    case ProductBadgeCorner.bottomRight:
      return Positioned(right: inset, bottom: inset, child: child);
    case ProductBadgeCorner.topRight:
      return Positioned(right: inset, top: inset, child: child);
  }
}

@Deprecated('Use ProductBadgeCorner')
typedef WishlistBadgeCorner = ProductBadgeCorner;

@Deprecated('Use productBadgeCornerFromApi')
WishlistBadgeCorner wishlistBadgeCornerFromApi(String raw) =>
    productBadgeCornerFromApi(raw);

@Deprecated('Use productBadgePositioned')
Widget wishlistBadgePositioned({
  required WishlistBadgeCorner corner,
  required double inset,
  required Widget child,
}) =>
    productBadgePositioned(corner: corner, inset: inset, child: child);

class DiscountBadgeMetrics {
  const DiscountBadgeMetrics({
    required this.fontSp,
    required this.padH,
    required this.padV,
    required this.squareSide,
  });

  final double fontSp;
  final double padH;
  final double padV;
  final double squareSide;
}

DiscountBadgeMetrics discountBadgeMetrics(String size) {
  final wishlist = wishlistBadgeMetrics(size);
  final side = wishlist.iconDp + wishlist.padDp * 2;
  return DiscountBadgeMetrics(
    fontSp: wishlist.iconDp * 0.7,
    padH: wishlist.padDp,
    padV: wishlist.padDp,
    squareSide: side,
  );
}

String normalizeDiscountBadgeShapeApi(String raw) {
  final v = raw.trim().toLowerCase();
  if (v == 'rounded' || v == 'rectangle') return 'rounded';
  return 'square';
}

bool isDiscountBadgeSquare(String shapeApi) =>
    normalizeDiscountBadgeShapeApi(shapeApi) == 'square';

double discountBadgeBorderRadiusDp({required double cornerRadiusDp}) {
  return cornerRadiusDp < 0 ? 0.0 : cornerRadiusDp;
}
