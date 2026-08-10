/// Runtime hydration for [product_grid] / [related_products] widgets.
///
/// Page JSON should store collection references and layout only — not product snapshots.
library;

import 'product_variant_model.dart';

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
  final fromApi = productIdFromApiProduct(item);
  if (fromApi.isNotEmpty) return fromApi;
  final action = item['action'];
  if (action is Map) {
    final nested = action['productId'] ?? action['id'];
    if (nested != null && nested.toString().trim().isNotEmpty) {
      return nested.toString();
    }
  }
  return null;
}

const List<String> _kGridItemIdKeys = [
  'productId',
  'product_id',
  'id',
  'shopifyProductId',
  'shopify_product_id',
  'handle',
];

/// Every id spelling a row may use, so collection rows still match catalog rows
/// when the two APIs differ (`product_id` vs `id`, `gid://…/Product/123` vs `123`).
List<String> gridItemIdCandidates(Map<String, dynamic> item) {
  final out = <String>[];

  void add(dynamic value) {
    if (value == null) return;
    final s = value.toString().trim();
    if (s.isEmpty) return;
    if (!out.contains(s)) out.add(s);
    final tail = s.split('/').last.trim();
    if (tail.isNotEmpty && tail != s && !out.contains(tail)) out.add(tail);
  }

  void addFrom(Map<dynamic, dynamic> source) {
    for (final key in _kGridItemIdKeys) {
      add(source[key]);
    }
  }

  addFrom(item);
  final action = item['action'];
  if (action is Map) {
    addFrom(action);
    final nested = action['product'];
    if (nested is Map) addFrom(nested);
  }
  final product = item['product'];
  if (product is Map) addFrom(product);

  return out;
}

Map<String, Map<String, dynamic>> _catalogIndexByIdCandidates(
  List<Map<String, dynamic>> catalogItems,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final item in catalogItems) {
    for (final candidate in gridItemIdCandidates(item)) {
      byId.putIfAbsent(candidate, () => item);
    }
  }
  return byId;
}

/// Id-only membership rows are useless without a catalog match — a tile with no
/// title and no image would render blank.
bool _rowHasRenderableContent(Map<String, dynamic> row) {
  final title = row['title']?.toString().trim() ?? '';
  if (title.isNotEmpty) return true;
  final image = row['imageUrl']?.toString().trim() ?? '';
  return image.isNotEmpty;
}

/// Live catalog row wins; keys it is missing (or left blank / zero for prices)
/// fall back to [row].
Map<String, dynamic> _mergeRowIntoLive(
  Map<String, dynamic> row,
  Map<String, dynamic> live,
) {
  const priceKeys = {'sellingPrice', 'retailPrice', 'discountPercent'};
  final merged = Map<String, dynamic>.from(live);
  row.forEach((key, value) {
    final current = merged[key];
    final missing = current == null ||
        (current is String && current.trim().isEmpty) ||
        (current is Iterable && current.isEmpty) ||
        (priceKeys.contains(key) && current is num && current <= 0);
    if (missing && value != null) merged[key] = value;
  });
  return merged;
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

const List<String> _kCollectionItemsKeys = [
  'items',
  'products',
  'productIds',
  'product_ids',
];

List<Map<String, dynamic>>? itemsFromCollectionRef(
  String ref,
  List<dynamic> collections,
) {
  if (isAllProductsCollectionRef(ref)) return null;
  final m = collectionMapForRef(ref, collections);
  if (m == null) return null;

  for (final key in _kCollectionItemsKeys) {
    final raw = m[key];
    if (raw is! List || raw.isEmpty) continue;
    final rows = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) {
        rows.add(Map<String, dynamic>.from(e));
        continue;
      }
      // Id-only membership lists — the catalog fills in the product data.
      final id = e?.toString().trim() ?? '';
      if (id.isNotEmpty) rows.add({'productId': id});
    }
    if (rows.isNotEmpty) return rows;
  }
  return null;
}

/// Replaces saved/stale rows with live catalog rows (same order, matched by product id).
///
/// Rows with no catalog match are dropped (deleted products must not linger),
/// unless [keepUnmatched] is set — collection rows are authoritative for
/// membership, so those are kept as-is instead of silently disappearing.
List<Map<String, dynamic>> refreshGridItemsFromCatalog(
  List<Map<String, dynamic>> catalogItems,
  List<dynamic> savedItems, {
  bool keepUnmatched = false,
}) {
  final byId = _catalogIndexByIdCandidates(catalogItems);
  if (byId.isEmpty) return [];

  final refreshed = <Map<String, dynamic>>[];
  for (final raw in savedItems) {
    if (raw is! Map) continue;
    final row = Map<String, dynamic>.from(raw);
    Map<String, dynamic>? live;
    for (final candidate in gridItemIdCandidates(row)) {
      live = byId[candidate];
      if (live != null) break;
    }
    if (live == null) {
      if (keepUnmatched && _rowHasRenderableContent(row)) refreshed.add(row);
      continue;
    }
    refreshed.add(_mergeRowIntoLive(row, live));
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
    final refreshed = refreshGridItemsFromCatalog(
      catalogItems,
      mapped,
      keepUnmatched: true,
    );
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
