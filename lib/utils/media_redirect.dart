import '../src/widget_node.dart';

/// Builder / theme JSON for "Redirect to" on media blocks (banner, slider, carousel, grid, video).
///
/// Fields:
/// - [enabled]: master toggle
/// - [kind]: `collection` | `product` | `url`
/// - [collectionId]: theme collection id (e.g. `best-sellers`, or `all`)
/// - [productId]: catalog product id
/// - [product]: optional snapshot map for PDP when storefront merges catalog
/// - [url] / [urlScope]: `internal` (in-app webview) | `external` (device browser)
Map<String, dynamic>? actionFromMediaRedirect(Map<String, dynamic>? redirect) {
  if (redirect == null || redirect.isEmpty) return null;
  if (redirect['enabled'] != true) return null;

  final kind = redirect['kind']?.toString().trim().toLowerCase() ?? '';
  switch (kind) {
    case 'collection':
      final id = redirect['collectionId']?.toString().trim() ?? '';
      if (id.isEmpty) return null;
      return {'type': 'open_collection', 'collection': id};
    case 'product':
      final id = redirect['productId']?.toString().trim() ?? '';
      if (id.isEmpty) return null;
      final snap = redirect['product'];
      return {
        'type': 'open_product',
        'productId': id,
        if (snap is Map) 'product': Map<String, dynamic>.from(snap),
      };
    case 'url':
      final url = redirect['url']?.toString().trim() ?? '';
      if (url.isEmpty) return null;
      final scope =
          (redirect['urlScope'] ?? redirect['url_scope'] ?? 'internal')
              .toString()
              .trim()
              .toLowerCase();
      if (scope == 'external') {
        return {'type': 'open_url_external', 'url': url};
      }
      return {'type': 'open_url_internal', 'url': url};
    default:
      return null;
  }
}

/// Prefers [redirect] when enabled; otherwise legacy [action] from blocks.
Map<String, dynamic>? effectiveMediaTapAction(WidgetNode node) {
  final fromRedirect = actionFromMediaRedirect(node.m('redirect'));
  if (fromRedirect != null) return fromRedirect;
  return node.m('action');
}

/// Parallel to [images] / carousel slides: `imageRedirects[index]` is a redirect map.
Map<String, dynamic>? actionFromImageRedirectsAt(List<dynamic>? imageRedirects, int index) {
  if (imageRedirects == null || index < 0 || index >= imageRedirects.length) return null;
  final item = imageRedirects[index];
  if (item is! Map) return null;
  return actionFromMediaRedirect(Map<String, dynamic>.from(item));
}

List<dynamic>? imageRedirectsListFromNode(WidgetNode node) {
  final v = node.props['imageRedirects'] ?? node.props['image_redirects'];
  if (v is List) return v;
  return null;
}
