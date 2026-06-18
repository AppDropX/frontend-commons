import 'package:flutter/material.dart';

import '../utils/color.dart';
import 'pdp_product_scope.dart';

/// Wishlist chrome settings read from the PDP product image block.
class PdpImageChromeSettings {
  const PdpImageChromeSettings({
    this.showWishlistButton = true,
    this.wishlistColor = const Color(0xFFE53935),
  });

  final bool showWishlistButton;
  final Color wishlistColor;

  static PdpImageChromeSettings fromPageJson(List<dynamic> pageJson) {
    for (final raw in pageJson) {
      if (raw is! Map) continue;
      if (raw['type']?.toString() != 'pdp_product_image') continue;
      final color = parseHexColor(raw['wishlist_color']?.toString() ?? '#E53935') ??
          const Color(0xFFE53935);
      return PdpImageChromeSettings(
        showWishlistButton: raw['show_wishlist_button'] != false,
        wishlistColor: color,
      );
    }
    return const PdpImageChromeSettings();
  }
}

/// Builds a wishlist tap handler for PDP chrome when none is supplied explicitly.
VoidCallback? resolvePdpWishlistTap({
  required BuildContext context,
  required bool hideAppBar,
  required bool showWishlistButton,
  required void Function(BuildContext context, Map<String, dynamic> action)? onAction,
  VoidCallback? onWishlistTap,
}) {
  if (!hideAppBar) return onWishlistTap;
  if (!showWishlistButton) return null;
  if (onWishlistTap != null) return onWishlistTap;
  if (onAction == null) return null;
  return () {
    final product = PdpProductScope.maybeOf(context)?.effectiveProduct;
    if (product == null) return;
    onAction(context, {
      'type': 'toggle_wishlist',
      'productId': (product['productId'] ?? product['id'])?.toString(),
      'product': product,
    });
  };
}
