import 'package:flutter/widgets.dart';

bool productBlockThemeBool(Map<String, dynamic> merged, String key, bool def) {
  final v = merged[key];
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return def;
}

String displayProductTitle(String title, bool upperCase) =>
    upperCase ? title.toUpperCase() : title;

FontWeight titleFontWeightFromVariation(String raw) {
  switch (raw.trim().toLowerCase()) {
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
