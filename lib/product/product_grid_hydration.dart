/// Runtime hydration for [product_grid] / [related_products] widgets.
///
/// Page JSON should store collection references and layout only — not product snapshots.
library;

const kAllProductsCollectionId = 'all';

/// Maps raw API product rows into grid line items (see pilot/builder mappers).
typedef CatalogItemsFromRaw = List<Map<String, dynamic>> Function(
  List<dynamic> productsRaw,
);

bool isAllProductsCollectionRef(String ref) {
  final lower = ref.toLowerCase().trim();
  return lower.isEmpty ||
      lower == kAllProductsCollectionId ||
      lower == 'all products';
}

/// Collection id/title/slug from a grid widget config (PLP override wins).
String collectionRefFromGridWidget(Map<String, dynamic> w) {
  final override = w['gridCollectionId']?.toString().trim();
  if (override != null && override.isNotEmpty) return override;
  for (final key in ['collection', 'collection_id', 'collectionId']) {
    final s = w[key]?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
  }
  return kAllProductsCollectionId;
}

String? productIdFromGridItem(Map<String, dynamic> item) {
  final top = item['productId'] ?? item['id'];
  if (top != null && top.toString().trim().isNotEmpty) {
    return top.toString();
  }
  final action = item['action'];
  if (action is Map) {
    final nested = action['productId'] ?? action['id'];
    if (nested != null && nested.toString().trim().isNotEmpty) {
      return nested.toString();
    }
  }
  return null;
}

String slugifyCollectionKey(String s) {
  return s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// Collection document from API matching [ref] (id, title, or slug), or null.
Map<String, dynamic>? collectionMapForRef(
  String ref,
  List<dynamic> collections,
) {
  final refSlug = slugifyCollectionKey(ref);
  for (final raw in collections) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id']?.toString().trim();
    if (id != null && id.isNotEmpty) {
      if (id == ref || slugifyCollectionKey(id) == refSlug) {
        return m;
      }
    }
    final title = m['title']?.toString() ?? '';
    if (title.isEmpty) continue;
    if (title.toLowerCase() == ref.toLowerCase() ||
        slugifyCollectionKey(title) == refSlug) {
      return m;
    }
  }
  return null;
}

/// Display name for app bar when a collection tab opens PLP.
String? collectionTitleForRef(String ref, List<dynamic> collections) {
  if (isAllProductsCollectionRef(ref)) return 'All products';
  final m = collectionMapForRef(ref, collections);
  final t = m?['title']?.toString().trim();
  if (t != null && t.isNotEmpty) return t;
  return null;
}

List<Map<String, dynamic>>? itemsFromCollectionRef(
  String ref,
  List<dynamic> collections,
) {
  if (isAllProductsCollectionRef(ref)) return null;
  final m = collectionMapForRef(ref, collections);
  if (m == null) return null;
  final raw = m['items'];
  if (raw is! List || raw.isEmpty) return null;
  return [
    for (final e in raw)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

/// Replaces saved/stale rows with live catalog rows (same order, matched by product id).
List<Map<String, dynamic>> refreshGridItemsFromCatalog(
  List<Map<String, dynamic>> catalogItems,
  List<dynamic> savedItems,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final item in catalogItems) {
    final id = productIdFromGridItem(item);
    if (id != null) byId[id] = item;
  }
  if (byId.isEmpty) return [];

  final refreshed = <Map<String, dynamic>>[];
  for (final raw in savedItems) {
    if (raw is! Map) continue;
    final id = productIdFromGridItem(Map<String, dynamic>.from(raw));
    final live = id == null ? null : byId[id];
    if (live == null) continue;
    refreshed.add(live);
  }
  return refreshed;
}

/// Resolves live grid line items for one widget from catalog + collection APIs.
List<Map<String, dynamic>> resolveProductGridItems({
  required Map<String, dynamic> gridWidget,
  required List<dynamic> productsRaw,
  required List<dynamic> collectionsRaw,
  required CatalogItemsFromRaw mapProducts,
}) {
  final catalogItems = mapProducts(productsRaw);
  if (catalogItems.isEmpty) return [];

  final ref = collectionRefFromGridWidget(gridWidget);
  if (isAllProductsCollectionRef(ref)) {
    return catalogItems;
  }

  final colItems = itemsFromCollectionRef(ref, collectionsRaw);
  if (colItems != null && colItems.isNotEmpty) {
    final mapped = mapProducts(colItems);
    final refreshed = refreshGridItemsFromCatalog(catalogItems, mapped);
    return refreshed.isEmpty ? mapped : refreshed;
  }

  // Legacy pages: honor saved item order via id match, else full catalog.
  final saved = gridWidget['items'];
  if (saved is List && saved.isNotEmpty) {
    final refreshed = refreshGridItemsFromCatalog(catalogItems, saved);
    if (refreshed.isNotEmpty) return refreshed;
  }

  return catalogItems;
}

/// Injects live [items] into every [product_grid] / [related_products] block.
List<Map<String, dynamic>> hydrateProductGridsFromCatalog(
  List<Map<String, dynamic>> pageJson, {
  required List<dynamic> productsRaw,
  required List<dynamic> collectionsRaw,
  required CatalogItemsFromRaw mapProducts,
}) {
  return [
    for (final w in pageJson)
      if (w['type'] == 'product_grid' || w['type'] == 'related_products')
        {
          ...w,
          'items': resolveProductGridItems(
            gridWidget: w,
            productsRaw: productsRaw,
            collectionsRaw: collectionsRaw,
            mapProducts: mapProducts,
          ),
        }
      else
        w,
  ];
}

/// PLP tab override: set collection ref on grids (items filled by [hydrateProductGridsFromCatalog]).
List<Map<String, dynamic>> applyCollectionRefToProductGrids(
  List<Map<String, dynamic>> pageJson,
  String collectionRef,
) {
  final ref = collectionRef.trim();
  if (ref.isEmpty) return pageJson;
  return [
    for (final w in pageJson)
      if (w['type'] == 'product_grid' || w['type'] == 'related_products')
        {
          ...w,
          'gridCollectionId': ref,
          'showCollectionHeading': false,
          'collectionTitle': '',
          'showGridTitle': false,
          'showViewAllButton': false,
        }
      else
        w,
  ];
}
