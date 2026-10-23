import '../src/widget_node.dart';

/// Builder / theme JSON for "Redirect to" on media blocks (banner, slider, carousel, grid, video).
///
/// Fields:
/// - [enabled]: master toggle
/// - [kind]: `collection` | `product` | `url` | `page`
/// - [collectionId]: theme collection id (e.g. `best-sellers`, or `all`)
/// - [productId]: catalog product id
/// - [product]: optional snapshot map for PDP when storefront merges catalog
/// - [pageId]: theme page id (Home or merchant-created; not PLP / PDP / cart / search / wishlist)
/// - [pageName]: optional display title for preview
/// - [url] / [urlScope]: `internal` (in-app webview) | `external` (device browser)
bool _redirectEnabled(dynamic value) {
  if (value == true) return true;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}

String _redirectField(Map<String, dynamic> redirect, List<String> keys) {
  for (final key in keys) {
    final value = redirect[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

Map<String, dynamic>? actionFromMediaRedirect(Map<String, dynamic>? redirect) {
  if (redirect == null || redirect.isEmpty) return null;
  if (!_redirectEnabled(redirect['enabled'])) return null;

  final kind = redirect['kind']?.toString().trim().toLowerCase() ?? '';
  switch (kind) {
    case 'collection':
      final id =
          _redirectField(redirect, const ['collectionId', 'collection_id']);
      if (id.isEmpty) return null;
      return {'type': 'open_collection', 'collection': id};
    case 'product':
      final id = _redirectField(redirect, const ['productId', 'product_id']);
      if (id.isEmpty) return null;
      final snap = redirect['product'];
      return {
        'type': 'open_product',
        'productId': id,
        if (snap is Map) 'product': Map<String, dynamic>.from(snap),
      };
    case 'page':
      final id = _redirectField(redirect, const ['pageId', 'page_id']);
      if (id.isEmpty) return null;
      final name = _redirectField(redirect, const ['pageName', 'page_name']);
      return {
        'type': 'open_page',
        'pageId': id,
        if (name.isNotEmpty) 'title': name,
      };
    case 'url':
      final url = _redirectField(redirect, const ['url']);
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
Map<String, dynamic>? actionFromImageRedirectsAt(
    List<dynamic>? imageRedirects, int index) {
  if (imageRedirects == null || index < 0 || index >= imageRedirects.length) {
    return null;
  }
  final item = imageRedirects[index];
  if (item is! Map) return null;
  return actionFromMediaRedirect(Map<String, dynamic>.from(item));
}

List<dynamic>? imageRedirectsListFromNode(WidgetNode node) {
  final v = node.props['imageRedirects'] ?? node.props['image_redirects'];
  if (v is List) return v;
  return null;
}
