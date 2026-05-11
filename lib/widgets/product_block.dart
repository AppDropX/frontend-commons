import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/network_image_url.dart';

Widget buildProductBlock(
    BuildContext context, WidgetNode node, AppDropBuildEnv env) {
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
  final showAddToCart = b('add_to_cart', true);

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

  final imageBg =
      parseHexColor(s('image_bg_color', '#E0E0E0')) ?? const Color(0xFFE0E0E0);
  final priceColor = parseHexColor(s('price_color', '#000000')) ?? Colors.black;
  final discountColor =
      parseHexColor(s('discount_color', '#FF0000')) ?? Colors.red;
  final ratingColor =
      parseHexColor(s('rating_color', '#FFA500')) ?? Colors.orange;
  final ratingFontColor =
      parseHexColor(s('rating_font_color', '#000000')) ?? Colors.black;
  final titleColor = parseHexColor(s('title_color', '#000000')) ?? Colors.black;
  final filledButtonBg = parseHexColor(s('filled_button_bg', '#B63E3E')) ??
      const Color(0xFFB63E3E);
  final filledButtonColor =
      parseHexColor(s('filled_button_color', '#FFFFFF')) ?? Colors.white;
  final outlinedButtonBg =
      parseHexColor(s('outlined_button_bg', '#FFFFFF')) ?? Colors.white;
  final outlinedButtonColor =
      parseHexColor(s('outlined_button_color', '#B63E3E')) ??
          const Color(0xFFB63E3E);
  final wishlistColor = parseHexColor(s('product_wishlist_color', '#E53935')) ??
      const Color(0xFFE53935);
  final buttonStyleRaw = s('button_style', 'sharp_filled').toLowerCase();
  final buttonStyleParts = buttonStyleRaw.split(RegExp(r'[_\-\s]+'));
  final buttonShape =
      buttonStyleParts.isNotEmpty ? buttonStyleParts.first : 'sharp';
  final buttonType =
      buttonStyleParts.length > 1 ? buttonStyleParts[1] : 'filled';

  final product = node.m('product') ?? <String, dynamic>{};
  final productId = (product['productId'] ?? product['id'])?.toString() ?? '';
  final inWishlist = productId.isNotEmpty
      ? env.wishlistContainsProduct?.call(productId) ?? b('inWishlist', false)
      : b('inWishlist', false);
  final title = (product['title'] ?? '').toString();
  final vendor = (product['vendor'] ?? '').toString();
  final imageUrl =
      sanitizedNetworkImageUrl((product['imageUrl'] ?? '').toString());

  final sellingPrice = _toDouble(product['sellingPrice']);
  final retailPrice = _toDouble(product['retailPrice']);
  final discountPercent = _toInt(product['discountPercent']);

  final rating = _toDouble(product['rating']);
  final ratingCount = _toInt(product['ratingCount']);

  final swatchesRaw =
      (product['swatches'] is List) ? (product['swatches'] as List) : const [];
  final swatches = swatchesRaw
      .map((e) => parseHexColor(e.toString()))
      .whereType<Color>()
      .toList();

  final action = node.m('action');
  final wishlistAction = node.m('wishlistAction');

  final aspect = _aspectFromIndex(aspectIdx);
  final align = _alignFromIndex(titleAlignIdx);
  final titleMaxLines =
      (titleBehaviorIdx == 1) ? 1 : (maxLines <= 0 ? null : maxLines);
  final priceWeight = priceFont == 'bold' ? FontWeight.w700 : FontWeight.w400;
  final discountSp = _discountSp(discountSize, env.r);

  final embedInGrid = b('embed_in_grid', false);
  final imageRadius = embedInGrid
      ? BorderRadius.only(
          topLeft: Radius.circular(env.r.dp(radiusDp)),
          topRight: Radius.circular(env.r.dp(radiusDp)),
        )
      : BorderRadius.circular(env.r.dp(radiusDp));

  final image = ClipRRect(
    borderRadius: imageRadius,
    child: AspectRatio(
      aspectRatio: aspect,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: imageBg,
              child: imageUrl == null
                  ? const SizedBox.expand()
                  : Image.network(
                      imageUrl,
                      fit: boxFit, // crop/fit toggle works
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => ColoredBox(
                          color: imageBg, child: const SizedBox.expand()),
                    ),
            ),
          ),
          Positioned(
            right: env.r.dp(8),
            top: env.r.dp(8),
            child: Material(
              color: Colors.white.withValues(alpha: 0.86),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: wishlistAction == null
                    ? null
                    : () => env.dispatchAction(context, wishlistAction),
                child: Padding(
                  padding: EdgeInsets.all(env.r.dp(6)),
                  child: Icon(
                    inWishlist ? Icons.favorite : Icons.favorite_border,
                    color: wishlistColor,
                    size: env.r.dp(18),
                  ),
                ),
              ),
            ),
          ),
        ],
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
              style: TextStyle(
                  fontSize: env.r.sp(12, min: 10, max: 14),
                  color: Colors.black54),
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
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: env.r.sp(12),
                    fontWeight: FontWeight.w600,
                    color: ratingFontColor,
                  ),
                ),
                if (showRatingCount && ratingCount > 0) ...[
                  SizedBox(width: env.r.dp(6)),
                  Text(
                    '($ratingCount)',
                    style: TextStyle(
                      fontSize: env.r.sp(12),
                      color: ratingFontColor.withValues(alpha: 0.54),
                    ),
                  ),
                ]
              ],
            ),
          ),
        Row(
          mainAxisAlignment: _main(align),
          children: [
            if (showSelling && sellingPrice > 0)
              Text('₹${sellingPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: env.r.sp(14),
                      fontWeight: priceWeight,
                      color: priceColor)),
            if (showRetail && retailPrice > 0) ...[
              SizedBox(width: env.r.dp(8)),
              Text(
                '₹${retailPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: env.r.sp(12),
                  color: Colors.black54,
                  decoration: showStrike
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ],
            if (showDiscount && discountPercent > 0) ...[
              SizedBox(width: env.r.dp(5)),
              Text('$discountPercent% OFF',
                  style: TextStyle(
                      fontSize: discountSp,
                      fontWeight: FontWeight.w700,
                      color: discountColor)),
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
                decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12)),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );

  final addToCartRadius = _addToCartRadius(buttonShape, env.r);
  final isOutlined = buttonType == 'outlined';
  final addToCartBg = isOutlined ? Colors.transparent : filledButtonBg;
  final addToCartFg = isOutlined ? outlinedButtonColor : filledButtonColor;

  final addToCartButton = Padding(
    padding: EdgeInsets.fromLTRB(env.r.dp(8), 0, env.r.dp(8), env.r.dp(10)),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(addToCartRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(addToCartRadius),
        onTap:
            action == null ? null : () => env.dispatchAction(context, action),
        child: Ink(
          height: env.r.dp(36),
          decoration: BoxDecoration(
            color: addToCartBg,
            borderRadius: BorderRadius.circular(addToCartRadius),
            border: isOutlined
                ? Border.all(color: outlinedButtonBg, width: 1.2)
                : Border.all(color: filledButtonBg, width: 1),
          ),
          child: Center(
            child: Text(
              'Add to Cart',
              style: TextStyle(
                color: addToCartFg,
                fontSize: env.r.sp(13, min: 11, max: 15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      image,
      meta,
      if (showAddToCart && !embedInGrid) addToCartButton,
    ],
  );

  if (embedInGrid) {
    Widget inner = body;
    if (action != null) {
      inner = InkWell(
          onTap: () => env.dispatchAction(context, action), child: inner);
    }
    return inner;
  }

  Widget card = ClipRRect(
    borderRadius: BorderRadius.circular(env.r.dp(radiusDp)),
    child: DecoratedBox(
      decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.black12)),
      child: body,
    ),
  );

  if (action != null) {
    card =
        InkWell(onTap: () => env.dispatchAction(context, action), child: card);
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

double _addToCartRadius(String style, dynamic r) {
  switch (style) {
    case 'rounded':
      return r.dp(12);
    case 'blunt':
    case 'pill':
      return r.dp(999);
    case 'corner':
    case 'sharp':
    default:
      return 0;
  }
}
