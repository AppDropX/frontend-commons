import 'store_toolbar_resolve.dart';

/// Finds a page meta row for a builder catalog key (`home-page`, `pdp-page`, …).
Map<String, dynamic>? pageMetaForCatalogKey(
  List<Map<String, dynamic>> pagesMeta,
  String catalogKey,
) {
  final key = catalogKey.trim().toLowerCase();
  if (key.isEmpty) return null;

  for (final p in pagesMeta) {
    if (p['id']?.toString().trim().toLowerCase() == key) return p;
  }

  for (final p in pagesMeta) {
    final route = p['route']?.toString() ?? '';
    final name = p['name']?.toString();
    if (storeCatalogKeyForRoute(route, pageName: name) == key) return p;
  }

  for (final p in pagesMeta) {
    final name = (p['name'] ?? '').toString().trim().toLowerCase();
    final slug = (p['slug'] ?? '').toString().trim().toLowerCase();
    switch (key) {
      case 'home-page':
        if (name == 'home' || slug == 'home') return p;
        break;
      case 'plp-page':
        if (name == 'plp' || slug == 'plp') return p;
        break;
      case 'pdp-page':
        if (name == 'pdp' || slug == 'pdp') return p;
        break;
      case 'cart-page':
        if (name == 'cart' || slug == 'cart') return p;
        break;
      case 'wishlist-page':
        if (name == 'wishlist' || slug == 'wishlist') return p;
        break;
      case 'search-page':
        if (name == 'search' || slug == 'search') return p;
        break;
    }
  }
  return null;
}

/// Resolves the loaded CMS page document for [catalogKey].
Map<String, dynamic>? cmsDocForCatalogKey(
  List<Map<String, dynamic>> pagesMeta,
  List<Map<String, dynamic>> cmsPages,
  String catalogKey,
) {
  final meta = pageMetaForCatalogKey(pagesMeta, catalogKey);
  final metaId = meta?['id']?.toString();
  if (metaId != null && metaId.isNotEmpty) {
    for (final p in cmsPages) {
      if (p['id']?.toString() == metaId) return p;
    }
  }

  for (final p in cmsPages) {
    final id = p['id']?.toString().trim().toLowerCase() ?? '';
    if (id == catalogKey.trim().toLowerCase()) return p;
    final name = (p['name'] ?? '').toString().trim().toLowerCase();
    switch (catalogKey.trim().toLowerCase()) {
      case 'home-page':
        if (name == 'home') return p;
        break;
      case 'plp-page':
        if (name == 'plp') return p;
        break;
      case 'pdp-page':
        if (name == 'pdp') return p;
        break;
      case 'cart-page':
        if (name == 'cart') return p;
        break;
      case 'wishlist-page':
        if (name == 'wishlist') return p;
        break;
      case 'search-page':
        if (name == 'search') return p;
        break;
    }
  }
  return null;
}
