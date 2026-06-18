/// Injects live [product] data into PDP CMS blocks (product_block, product_variant, …).
List<Map<String, dynamic>> enrichPdpBlocksWithProduct(
  List<Map<String, dynamic>> cmsBlocks,
  Map<String, dynamic> product,
) {
  final p = Map<String, dynamic>.from(product);
  final productId = (p['productId'] ?? p['id'])?.toString() ?? '';

  return cmsBlocks.map((w) {
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
      final rawDesc = p['description']?.toString() ?? '';
      final stripped = _stripHtml(rawDesc);
      copy['description'] = stripped.isEmpty
          ? (w['description']?.toString() ?? 'No description.')
          : stripped;
      return copy;
    }

    return copy;
  }).toList();
}

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
