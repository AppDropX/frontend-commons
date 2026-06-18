import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/appdrop_snackbar.dart';
import '../utils/color.dart';
import '../utils/network_image_url.dart';
import '../utils/component_shadow.dart';

/// Cart item row for cart page. Fixed block on cart page (not in add-block library).
/// Props: enabled, imageUrl, productTitle, price (line subtotal), variant, quantity,
/// optional productId + product map for quantity stepper ([decrement_cart] / [add_to_cart]).
Widget buildCartItem(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final imageUrl = sanitizedNetworkImageUrl(node.s('imageUrl', def: ''));
  final productTitle = node.s('productTitle', def: 'Product title');
  final price = node.s('price', def: '₹999');
  final variant = node.s('variant', def: '');
  final quantity = node.i('quantity', def: 1);
  final productId = node.s('productId', def: '').trim();
  Map<String, dynamic>? productMap;
  final rawProduct = node.props['product'];
  if (rawProduct is Map) {
    productMap = Map<String, dynamic>.from(rawProduct);
  }

  final variantLabel = variant.trim().isNotEmpty
      ? variant.trim()
      : (productMap != null ? variantLabelFromProductMap(productMap) : '');

  final inWishlist = productId.isNotEmpty
      ? env.wishlistContainsProduct?.call(productId) ?? false
      : false;

  return _CartItemWidget(
    r: r,
    env: env,
    imageUrl: imageUrl,
    productTitle: productTitle,
    price: price,
    variant: variantLabel,
    quantity: quantity,
    productId: productId,
    productMap: productMap,
    inWishlist: inWishlist,
  );
}

Color _resolveWishlistColor(BuildContext context) {
  final cfg = AppDropThemeScope.maybeOf(context);
  if (cfg != null) {
    final c = parseHexColor(cfg.productBlock['product_wishlist_color']?.toString());
    if (c != null) return c;
  }
  return const Color(0xFFE53935);
}

class _CartItemWidget extends StatelessWidget {
  const _CartItemWidget({
    required this.r,
    required this.env,
    required this.imageUrl,
    required this.productTitle,
    required this.price,
    required this.variant,
    required this.quantity,
    required this.productId,
    required this.productMap,
    required this.inWishlist,
  });

  final R r;
  final AppDropBuildEnv env;
  final String? imageUrl;
  final String productTitle;
  final String price;
  final String variant;
  final int quantity;
  final String productId;
  final Map<String, dynamic>? productMap;
  final bool inWishlist;

  static const double _imageSizeDp = 80;

  @override
  Widget build(BuildContext context) {
    final primaryColor = resolveAppDropPrimaryColor(context);
    final wishlistColor = _resolveWishlistColor(context);
    final imageSize = r.dp(_imageSizeDp);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.dp(16), vertical: r.dp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.dp(12)),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: kAppDropComponentShadows,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(r.dp(8)),
            child: Container(
              width: imageSize,
              height: imageSize,
              color: Colors.grey.shade200,
              child: imageUrl == null
                  ? Icon(
                      Icons.image_not_supported,
                      size: r.dp(32),
                      color: Colors.grey.shade400,
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: imageSize,
                      height: imageSize,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        size: r.dp(32),
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          ),
          SizedBox(width: r.dp(12)),
          Expanded(
            child: SizedBox(
              height: imageSize,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          productTitle.isEmpty ? 'Product title' : productTitle,
                          style: TextStyle(
                            fontSize: r.sp(14, min: 12, max: 16),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (productId.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(left: r.dp(4)),
                          child: WishlistHeartButton(
                            isWishlisted: inWishlist,
                            activeColor: wishlistColor,
                            inactiveColor: Colors.grey.shade600,
                            size: r.dp(20),
                            borderRadius: r.dp(4),
                            onTap: () {
                              if (!inWishlist) {
                                triggerWishlistAddHaptic();
                              }
                              env.dispatchAction(context, {
                                'type': 'toggle_wishlist',
                                'productId': productId,
                                'product': productMap ?? <String, dynamic>{},
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  if (variant.isNotEmpty) ...[
                    SizedBox(height: r.dp(2)),
                    Text(
                      variant,
                      style: TextStyle(
                        fontSize: r.sp(12, min: 10, max: 14),
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          price.isEmpty ? '₹0' : price,
                          style: TextStyle(
                            fontSize: r.sp(14, min: 12, max: 16),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (productId.isNotEmpty)
                        _CartQtyStepper(
                          r: r,
                          quantity: quantity,
                          accentColor: primaryColor,
                          onDecrement: () => env.dispatchAction(context, {
                            'type': 'decrement_cart',
                            'productId': productId,
                          }),
                          onIncrement: () => env.dispatchAction(context, {
                            'type': 'add_to_cart',
                            'direct': true,
                            'productId': productId,
                            'product': productMap ?? <String, dynamic>{},
                          }),
                        )
                      else
                        Text(
                          'Qty: $quantity',
                          style: TextStyle(
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartQtyStepper extends StatelessWidget {
  const _CartQtyStepper({
    required this.r,
    required this.quantity,
    required this.accentColor,
    required this.onDecrement,
    required this.onIncrement,
  });

  final R r;
  final int quantity;
  final Color accentColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(r.dp(8)),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(r.dp(8)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onDecrement,
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(r.dp(8))),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.dp(8),
                  vertical: r.dp(6),
                ),
                child: Icon(Icons.remove, size: r.dp(18), color: accentColor),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: r.dp(24)),
              child: Center(
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: r.sp(14, min: 12, max: 16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onIncrement,
              borderRadius:
                  BorderRadius.horizontal(right: Radius.circular(r.dp(8))),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.dp(8),
                  vertical: r.dp(6),
                ),
                child: Icon(Icons.add, size: r.dp(18), color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
