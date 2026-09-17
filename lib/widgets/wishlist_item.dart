import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';
import '../utils/network_image_url.dart';
import 'wishlist_remove_confirm_dialog.dart';

/// Wishlist product card — mirrors [buildProductBlock] pricing, image, and actions.
Widget buildWishlistItem(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  Map<String, dynamic>? productMap;
  final rawProduct = node.props['product'];
  if (rawProduct is Map) {
    productMap = Map<String, dynamic>.from(rawProduct);
  }

  final productId = node.s('productId', def: '').trim();
  final productTitle = node.s('productTitle', def: 'Product');

  return _WishlistItemWidget(
    r: r,
    env: env,
    productMap: productMap,
    productId: productId,
    fallbackTitle: productTitle,
  );
}

class _WishlistItemWidget extends StatelessWidget {
  const _WishlistItemWidget({
    required this.r,
    required this.env,
    required this.productMap,
    required this.productId,
    required this.fallbackTitle,
  });

  final R r;
  final AppDropBuildEnv env;
  final Map<String, dynamic>? productMap;
  final String productId;
  final String fallbackTitle;

  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFEBEDF0);
  static const double _outerHorizontalDp = 16;
  static const double _innerPadDp = 12;
  static const double _imageSizeDp = 88;
  static const double _imageGapDp = 10;
  static const double _cardRadiusDp = 12;

  Future<void> _confirmAndRemove(BuildContext context) async {
    final confirmed = await showWishlistRemoveConfirmDialog(context);
    if (!confirmed || !context.mounted) return;
    env.dispatchAction(context, {
      'type': 'remove_from_wishlist',
      'productId': productId,
      'product': productMap,
    });
  }

  void _openProduct(BuildContext context, Map<String, dynamic> productMap) {
    final heroTag = ProductHeroTags.sourceInstance(productId, context);
    env.dispatchAction(context, {
      'type': 'open_product',
      'productId': productId,
      'heroTag': heroTag,
      'product': {...productMap, 'heroTag': heroTag},
    });
  }

  void _onAddToCart(BuildContext context, Map<String, dynamic> product) {
    env.dispatchAction(context, {
      'type': 'add_to_cart',
      'productId': productId,
      'product': product,
    });
  }

  @override
  Widget build(BuildContext context) {
    final productMap = this.productMap;

    if (productMap == null || productId.isEmpty) {
      return const SizedBox.shrink();
    }

    final entry = ProductSearchEntry.fromRow(productMap);
    final title = entry.title.isNotEmpty ? entry.title : fallbackTitle;
    final imageUrl = sanitizedNetworkImageUrl(entry.thumbnailUrl);
    final heroTag = ProductHeroTags.sourceInstance(productId, context);

    final cfg = AppDropThemeScope.maybeOf(context);
    final pb = cfg?.productBlock ?? const <String, dynamic>{};
    final titleColor =
        parseHexColor(pb['title_color']?.toString()) ?? const Color(0xFF111827);
    final fontFamily = cfg?.appStyling.fontFamily ?? 'Poppins';
    final priceDisplay = ProductPriceDisplayConfig.fromContext(context, r: r);

    final imageSize = r.dp(_imageSizeDp);
    final radius = BorderRadius.circular(r.dp(_cardRadiusDp));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.dp(_outerHorizontalDp)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: radius,
          border: Border.all(color: _borderColor),
          boxShadow: kAppDropCartItemShadows,
        ),
        child: Padding(
          padding: EdgeInsets.all(r.dp(_innerPadDp)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openProduct(context, productMap),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r.dp(10)),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: imageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFF3F4F6),
                            child: Center(
                              child: Icon(
                                FluentIcons.image_off_20_regular,
                                size: 24,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          )
                        : buildProductHeroImage(
                            productId: productId,
                            imageUrl: imageUrl,
                            aspectRatio: 1,
                            boxFit: BoxFit.cover,
                            imageBg: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(r.dp(10)),
                            heroTag: heroTag,
                          ),
                  ),
                ),
              ),
              SizedBox(width: r.dp(_imageGapDp)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openProduct(context, productMap),
                            child: Text(
                              title.isEmpty ? 'Product' : title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppDropThemeData.textStyle(
                                fontFamily: fontFamily,
                                fontSize: r.sp(14, min: 13, max: 15),
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ).copyWith(height: 1.2),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(r.dp(6), -r.dp(4)),
                          child: _WishlistDeleteButton(
                            r: r,
                            onTap: () => _confirmAndRemove(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.dp(6)),
                    ProductPriceRow(
                      sellingPrice: entry.price,
                      retailPrice: entry.retailPrice,
                      discountPercent: entry.discountPercent,
                      config: priceDisplay,
                      layout: ProductPriceRowLayout.wrap,
                    ),
                    SizedBox(height: r.dp(10)),
                    ProductBlockAddToCartButton(
                      r: r,
                      onTap: () => _onAddToCart(context, productMap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistDeleteButton extends StatelessWidget {
  const _WishlistDeleteButton({required this.r, required this.onTap});

  final R r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove from wishlist',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r.dp(18)),
          child: SizedBox(
            width: r.dp(28),
            height: r.dp(28),
            child: Icon(
              FluentIcons.delete_24_regular,
              size: r.dp(16),
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}
