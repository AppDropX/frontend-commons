import 'package:flutter/material.dart';
import '../features/rating_review_feature.dart';
import '../pdp/pdp_product_scope.dart';
import '../theme_library.dart';
import '../transitions/pdp_enter_animation.dart';
import '../utils/color.dart';
import '../utils/network_image_url.dart';
import 'fullscreen_image_viewer.dart';
import 'product_hero_image.dart';
import 'wishlist_heart_button.dart';

/// Horizontal and below-image inset for product cards in [product_grid].
const double kGridProductCardContentPadDp = 8.0;

/// Content inset for standalone product cards and PDP sections.
const double kProductCardContentPadDp = 12.0;

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
  // Rating & Review feature temporarily disabled
  final showRating = kRatingReviewFeatureEnabled && b('show_rating', true);
  final showRatingCount =
      kRatingReviewFeatureEnabled && b('show_rating_count', true);
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
  final productImages = _productImages(product, imageUrl);

  final embedInGrid = b('embed_in_grid', false);
  final embedInPdp = b('embed_in_pdp', false);
  final pdpScope = embedInPdp ? PdpProductScope.maybeOf(context) : null;
  final sellingPrice =
      pdpScope?.sellingPrice ?? _toDouble(product['sellingPrice']);
  final retailPrice =
      pdpScope?.retailPrice ?? _toDouble(product['retailPrice']);
  final discountPercent =
      pdpScope?.discountPercent ?? _toInt(product['discountPercent']);

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

  final incomingHeroTag =
      (merged['heroTag'] ?? product['heroTag'])?.toString().trim();
  final sourceHeroTag = productId.isEmpty
      ? ''
      : ProductHeroTags.sourceInstance(productId, context);
  final resolvedHeroTag = embedInPdp
      ? (incomingHeroTag ?? '')
      : (incomingHeroTag != null && incomingHeroTag.isNotEmpty
          ? incomingHeroTag
          : sourceHeroTag);
  const pdpHorizontalInsetDp = 16.0;
  final imageRadius = embedInPdp
      ? BorderRadius.circular(env.r.dp(radiusDp))
      : embedInGrid
          ? BorderRadius.only(
              topLeft: Radius.circular(env.r.dp(radiusDp)),
              topRight: Radius.circular(env.r.dp(radiusDp)),
            )
          : BorderRadius.circular(env.r.dp(radiusDp));

  Widget image = embedInPdp && productImages.length > 1
      ? _PdpProductImageCarousel(
          images: productImages,
          productId: productId,
          aspectRatio: aspect,
          imageBg: imageBg,
          imageRadius: imageRadius,
          heroTag: resolvedHeroTag,
        )
      : buildProductHeroImage(
          productId: productId,
          imageUrl: imageUrl,
          aspectRatio: aspect,
          boxFit: boxFit,
          imageBg: imageBg,
          borderRadius: imageRadius,
          heroTag: resolvedHeroTag.isEmpty ? null : resolvedHeroTag,
          enableHero: productId.isNotEmpty && resolvedHeroTag.isNotEmpty,
        );
  if (embedInPdp && productImages.length == 1) {
    image = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openFullscreenImageViewer(
        context,
        images: productImages,
        initialIndex: 0,
      ),
      child: image,
    );
  }

  if (!embedInPdp) {
    image = Stack(
      children: [
        image,
        Positioned(
          right: env.r.dp(8),
          top: env.r.dp(8),
          child: WishlistHeartButton(
            isWishlisted: inWishlist,
            activeColor: wishlistColor,
            size: env.r.dp(18),
            showBackground: true,
            padding: EdgeInsets.all(env.r.dp(6)),
            onTap: wishlistAction == null
                ? null
                : () => env.dispatchAction(context, wishlistAction),
          ),
        ),
      ],
    );
  }

  final gridMetaPadH = kGridProductCardContentPadDp;
  final gridMetaPadTop = kGridProductCardContentPadDp;
  // Bottom inset for grid cards is applied on the add-to-cart row in [product_grid].
  final gridMetaPadBottom = 0.0;
  final metaPadH = embedInGrid ? gridMetaPadH : kProductCardContentPadDp;
  final metaPadTop = embedInGrid ? gridMetaPadTop : kProductCardContentPadDp;
  final metaPadBottom =
      embedInGrid ? gridMetaPadBottom : kProductCardContentPadDp;
  final vendorBottomGap = embedInGrid ? 2.0 : 6.0;
  final titlePriceGap = embedInGrid ? 4.0 : 10.0;
  final ratingBottomGap = embedInGrid ? 4.0 : 10.0;

  final meta = Padding(
    padding: EdgeInsets.fromLTRB(
      env.r.dp(metaPadH),
      env.r.dp(metaPadTop),
      env.r.dp(metaPadH),
      env.r.dp(metaPadBottom),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _cross(align),
      children: [
        if (showVendor && vendor.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: env.r.dp(vendorBottomGap)),
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
        SizedBox(height: env.r.dp(titlePriceGap)),
        if (showRating && rating > 0)
          Padding(
            padding: EdgeInsets.only(bottom: env.r.dp(ratingBottomGap)),
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
        onTap: action == null
            ? null
            : () {
                final payload = embedInPdp && pdpScope != null
                    ? {
                        ...action,
                        'direct': true,
                        'product': pdpScope.effectiveProduct,
                      }
                    : action;
                env.dispatchAction(context, payload);
              },
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

  // Grid tiles handle open-product taps at the card level in [product_grid].
  if (embedInGrid) {
    return body;
  }

  if (embedInPdp) {
    final pdpImage = wrapPdpStagger(context, PdpStaggerSlot.image, image);
    final pdpTitle = wrapPdpStagger(
      context,
      PdpStaggerSlot.title,
      _pdpTitleSection(
        env: env,
        align: align,
        showVendor: showVendor,
        vendor: vendor,
        title: title,
        titleMaxLines: titleMaxLines,
        titleColor: titleColor,
        showRating: showRating,
        rating: rating,
        showRatingCount: showRatingCount,
        ratingCount: ratingCount,
        ratingColor: ratingColor,
        ratingFontColor: ratingFontColor,
        showSwatches: false,
        swatches: swatches,
      ),
    );
    final pdpPrice = wrapPdpStagger(
      context,
      PdpStaggerSlot.price,
      _pdpPriceSection(
        env: env,
        align: align,
        showSelling: showSelling,
        sellingPrice: sellingPrice,
        showRetail: showRetail,
        retailPrice: retailPrice,
        showStrike: showStrike,
        showDiscount: showDiscount,
        discountPercent: discountPercent,
        priceWeight: priceWeight,
        priceColor: priceColor,
        discountSp: discountSp,
        discountColor: discountColor,
        showSwatches: showSwatches,
        swatches: swatches,
      ),
    );

    final staggeredDetails = ClipRRect(
      borderRadius: BorderRadius.circular(env.r.dp(radiusDp)),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            pdpTitle,
            pdpPrice,
            if (showAddToCart)
              wrapPdpStagger(
                context,
                PdpStaggerSlot.addToCart,
                addToCartButton,
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: env.r.dp(pdpHorizontalInsetDp),
          ),
          child: pdpImage,
        ),
        SizedBox(height: env.r.dp(12)),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: env.r.dp(pdpHorizontalInsetDp),
          ),
          child: staggeredDetails,
        ),
      ],
    );
  }

  Widget card = ClipRRect(
    borderRadius: BorderRadius.circular(env.r.dp(radiusDp)),
    child: DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: body,
    ),
  );

  if (action != null) {
    card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => env.dispatchAction(
        context,
        _actionWithHeroTag(action, product, resolvedHeroTag),
      ),
      child: card,
    );
  }
  return card;
}

Map<String, dynamic> _actionWithHeroTag(
  Map<String, dynamic> action,
  Map<String, dynamic> product,
  String heroTag,
) {
  if (action['type']?.toString() != 'open_product' || heroTag.isEmpty) {
    return action;
  }
  return {
    ...action,
    'heroTag': heroTag,
    'product': {
      ...product,
      'heroTag': heroTag,
    },
  };
}

List<String> _productImages(Map<String, dynamic> product, String? fallbackUrl) {
  final images = <String>[];
  final raw = product['images'];
  if (raw is List) {
    for (final item in raw) {
      final candidate = sanitizedNetworkImageUrl(item?.toString() ?? '');
      if (candidate != null && candidate.isNotEmpty) {
        images.add(candidate);
      }
    }
  }
  final fallback = sanitizedNetworkImageUrl(fallbackUrl ?? '');
  if (fallback != null && fallback.isNotEmpty && !images.contains(fallback)) {
    images.insert(0, fallback);
  }
  return images;
}

class _PdpProductImageCarousel extends StatefulWidget {
  const _PdpProductImageCarousel({
    required this.images,
    required this.productId,
    required this.aspectRatio,
    required this.imageBg,
    required this.imageRadius,
    required this.heroTag,
  });

  final List<String> images;
  final String productId;
  final double aspectRatio;
  final Color imageBg;
  final BorderRadius imageRadius;
  final String heroTag;

  @override
  State<_PdpProductImageCarousel> createState() =>
      _PdpProductImageCarouselState();
}

class _PdpProductImageCarouselState extends State<_PdpProductImageCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, i) {
              final imageWidget = i == 0 &&
                      widget.productId.isNotEmpty &&
                      widget.heroTag.isNotEmpty
                  ? buildProductHeroImage(
                      productId: widget.productId,
                      imageUrl: widget.images[i],
                      aspectRatio: widget.aspectRatio,
                      boxFit: BoxFit.cover,
                      imageBg: widget.imageBg,
                      borderRadius: widget.imageRadius,
                      heroTag: widget.heroTag,
                      enableHero: true,
                    )
                  : ClipRRect(
                      borderRadius: widget.imageRadius,
                      child: ColoredBox(
                        color: widget.imageBg,
                        child: Image.network(
                          widget.images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.expand(),
                        ),
                      ),
                    );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openFullscreenImageViewer(
                  context,
                  images: widget.images,
                  initialIndex: i,
                ),
                child: imageWidget,
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              return Container(
                width: i == _index ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _index ? Colors.white : Colors.white70,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
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
      return r.dp(8);
    case 'blunt':
    case 'pill':
      return r.dp(999);
    case 'corner':
    case 'sharp':
    default:
      return 0;
  }
}

/// PDP title block (vendor, title, rating) — stagger slot: [PdpStaggerSlot.title].
Widget _pdpTitleSection({
  required AppDropBuildEnv env,
  required TextAlign align,
  required bool showVendor,
  required String vendor,
  required String title,
  required int? titleMaxLines,
  required Color titleColor,
  required bool showRating,
  required double rating,
  required bool showRatingCount,
  required int ratingCount,
  required Color ratingColor,
  required Color ratingFontColor,
  required bool showSwatches,
  required List<Color> swatches,
}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
      env.r.dp(kProductCardContentPadDp),
      env.r.dp(kProductCardContentPadDp),
      env.r.dp(kProductCardContentPadDp),
      0,
    ),
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
                color: Colors.black54,
              ),
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
        if (showRating && rating > 0) ...[
          SizedBox(height: env.r.dp(10)),
          Row(
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
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

/// PDP price row (+ swatches) — stagger slot: [PdpStaggerSlot.price].
Widget _pdpPriceSection({
  required AppDropBuildEnv env,
  required TextAlign align,
  required bool showSelling,
  required double sellingPrice,
  required bool showRetail,
  required double retailPrice,
  required bool showStrike,
  required bool showDiscount,
  required int discountPercent,
  required FontWeight priceWeight,
  required Color priceColor,
  required double discountSp,
  required Color discountColor,
  required bool showSwatches,
  required List<Color> swatches,
}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
      env.r.dp(kProductCardContentPadDp),
      env.r.dp(10),
      env.r.dp(kProductCardContentPadDp),
      0,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _cross(align),
      children: [
        Row(
          mainAxisAlignment: _main(align),
          children: [
            if (showSelling && sellingPrice > 0)
              Text(
                '₹${sellingPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: env.r.sp(14),
                  fontWeight: priceWeight,
                  color: priceColor,
                ),
              ),
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
              Text(
                '$discountPercent% OFF',
                style: TextStyle(
                  fontSize: discountSp,
                  fontWeight: FontWeight.w700,
                  color: discountColor,
                ),
              ),
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
                  border: Border.all(color: Colors.black12),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );
}
