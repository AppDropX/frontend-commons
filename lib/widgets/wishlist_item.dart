import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/network_image_url.dart';
import '../utils/component_shadow.dart';
import 'product_hero_image.dart';

/// Wishlist row: image, title, price, remove; row tap opens product.
Widget buildWishlistItem(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final imageUrl = sanitizedNetworkImageUrl(node.s('imageUrl', def: ''));
  final productTitle = node.s('productTitle', def: 'Product');
  final price = node.s('price', def: '');
  final productId = node.s('productId', def: '').trim();
  final heroTag = productId.isEmpty
      ? ''
      : ProductHeroTags.sourceInstance(productId, context);
  Map<String, dynamic>? productMap;
  final rawProduct = node.props['product'];
  if (rawProduct is Map) {
    productMap = Map<String, dynamic>.from(rawProduct);
  }

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: r.dp(16), vertical: r.dp(6)),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r.dp(12)),
        onTap: productId.isEmpty || productMap == null
            ? null
            : () => env.dispatchAction(context, {
                  'type': 'open_product',
                  'productId': productId,
                  'heroTag': heroTag,
                  'product': {
                    ...productMap!,
                    'heroTag': heroTag,
                  },
                }),
        child: Container(
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
            SizedBox(
              width: r.dp(80),
              height: r.dp(80),
              child: productId.isEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(r.dp(8)),
                      child: ColoredBox(
                        color: Colors.grey.shade200,
                        child: Icon(
                          FluentIcons.image_off_20_regular,
                          size: r.dp(32),
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                  : buildProductHeroImage(
                      productId: productId,
                      imageUrl: imageUrl,
                      aspectRatio: 1,
                      boxFit: BoxFit.cover,
                      imageBg: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(r.dp(8)),
                      heroTag: heroTag,
                    ),
            ),
            SizedBox(width: r.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productTitle.isEmpty ? 'Product' : productTitle,
                    style: TextStyle(
                      fontSize: r.sp(14, min: 12, max: 16),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (price.isNotEmpty) ...[
                    SizedBox(height: r.dp(8)),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: r.sp(14, min: 12, max: 16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: productId.isEmpty
                  ? null
                  : () => env.dispatchAction(context, {
                        'type': 'remove_from_wishlist',
                        'productId': productId,
                      }),
              icon: Icon(FluentIcons.heart_20_filled, color: Colors.red.shade400, size: r.dp(22)),
            ),
          ],
        ),
      ),
    ),
  ),
  );
}
