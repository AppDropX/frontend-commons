import 'pdp_image_banner_visibility.dart';

/// Injects live [product] data into PDP CMS blocks (product_block, product_variant, …).
List<Map<String, dynamic>> enrichPdpBlocksWithProduct(
  List<Map<String, dynamic>> cmsBlocks,
  Map<String, dynamic> product,
) {
  final p = Map<String, dynamic>.from(product);
  final productId = (p['productId'] ?? p['id'])?.toString() ?? '';

  final visible = filterPdpBlocksForProduct(cmsBlocks, productId);

  return visible.map((w) {
    final type = w['type']?.toString();
    final copy = Map<String, dynamic>.from(w);

    if (type == 'product_block') {
      copy['product'] = p;
      copy['embed_in_pdp'] = true;
      copy['action'] = {
        'type': 'add_to_cart',
        'direct': true,
        'productId': productId,
        'product': p,
      };
      copy['wishlistAction'] = {
        'type': 'toggle_wishlist',
        'productId': productId,
        'product': p,
      };
      return copy;
    }

    if (type == 'pdp_product_image' ||
        type == 'pdp_product_label' ||
        type == 'pdp_product_price' ||
        type == 'pdp_product_quantity' ||
        type == 'pdp_product_cta') {
      copy['product'] = p;
      if (type == 'pdp_product_image') {
        copy['wishlistAction'] = {
          'type': 'toggle_wishlist',
          'productId': productId,
          'product': p,
        };
      }
      if (type == 'pdp_product_cta') {
        copy['scrollStyle'] = pdpCtaResolvedScrollStyle(copy);
        copy['action'] = {
          'type': 'add_to_cart',
          'direct': true,
          'productId': productId,
          'product': p,
        };
      }
      return copy;
    }

    if (type == 'product_variant') {
      copy['product'] = p;
      return copy;
    }

    if (type == 'product_description') {
      final rawDesc = p['description']?.toString().trim() ?? '';
      copy['description'] = rawDesc.isEmpty
          ? (w['description']?.toString() ?? 'No description.')
          : rawDesc;
      return copy;
    }

    return copy;
  }).toList();
}

/// Column layout pins the two buttons in the page, so fixed-bottom scrolling stays off.
bool pdpCtaUsesColumnLayout(Map<String, dynamic> block) {
  final showBuyNow = block['show_buy_now'] == true;
  final layout =
      (block['button_layout'] ?? 'row').toString().trim().toLowerCase();
  return showBuyNow && layout == 'column';
}

/// Scaffold scroll key for a PDP CTA. Column layout always stays inline.
String pdpCtaResolvedScrollStyle(Map<String, dynamic> block) {
  if (pdpCtaUsesColumnLayout(block)) return 'inline';
  final scrollStyle =
      (block['scroll_style'] ?? block['scrollStyle'] ?? 'inline')
          .toString()
          .trim()
          .toLowerCase();
  if (scrollStyle == 'fixed_bottom' || scrollStyle == 'fixed_at_bottom') {
    return 'fixed_at_bottom';
  }
  return 'inline';
}
