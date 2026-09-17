/// Parsed product variant option from catalog / Shopify-style API payloads.
class ProductVariantOption {
  const ProductVariantOption({
    required this.id,
    required this.label,
    required this.sellingPrice,
    this.retailPrice,
    this.available = true,
    this.inventoryQuantity,
    required this.raw,
  });

  final String id;
  final String label;
  final double sellingPrice;
  final double? retailPrice;
  final bool available;
  final int? inventoryQuantity;
  final Map<String, dynamic> raw;

  bool get hasPrice => sellingPrice > 0;

  bool get isOutOfStock => !available;
}

double parseApiNumber(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

/// Primary product id from dashboard / Shopify-style JSON.
String productIdFromApiProduct(Map<String, dynamic> p) {
  for (final key in [
    'productId',
    'product_id',
    'id',
    'shopifyProductId',
    'shopify_product_id',
  ]) {
    final s = p[key]?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
}

/// Parses a price field when present and strictly positive.
double? optionalApiPrice(dynamic value) {
  if (value == null) return null;
  final parsed = parseApiNumber(value);
  return parsed > 0 ? parsed : null;
}

/// Selling price from dashboard / Shopify-style product JSON.
double sellingPriceFromApiProduct(Map<String, dynamic> p) {
  for (final key in ['sellingPrice', 'selling_price']) {
    final v = optionalApiPrice(p[key]);
    if (v != null) return v;
  }
  final root = optionalApiPrice(p['price']);
  if (root != null) return root;
  return _firstVariantSellingPriceFromApi(p) ?? 0;
}

/// Retail / compare-at price from dashboard / Shopify-style product JSON.
double retailPriceFromApiProduct(Map<String, dynamic> p, double selling) {
  for (final key in [
    'retailPrice',
    'retail_price',
    'compare_at_price',
    'compareAtPrice',
    'mrp',
  ]) {
    final v = optionalApiPrice(p[key]);
    if (v != null) return v;
  }
  return _firstVariantRetailPriceFromApi(p) ?? selling;
}

double? _firstVariantSellingPriceFromApi(Map<String, dynamic> p) {
  final variants = p['variants'];
  if (variants is! List) return null;
  for (final v in variants) {
    if (v is! Map) continue;
    final variant = Map<String, dynamic>.from(v);
    final selling = optionalApiPrice(variant['sellingPrice']) ??
        optionalApiPrice(variant['selling_price']) ??
        optionalApiPrice(variant['price']);
    if (selling != null) return selling;
  }
  return null;
}

double? _firstVariantRetailPriceFromApi(Map<String, dynamic> p) {
  final variants = p['variants'];
  if (variants is! List) return null;
  for (final v in variants) {
    if (v is! Map) continue;
    final variant = Map<String, dynamic>.from(v);
    for (final key in [
      'retailPrice',
      'retail_price',
      'compare_at_price',
      'compareAtPrice',
      'mrp',
    ]) {
      final parsed = optionalApiPrice(variant[key]);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

/// Label for the variant dimension row (e.g. Size, Color).
String productVariantGroupLabel(Map<String, dynamic> product) {
  final options = product['options'];
  if (options is List && options.isNotEmpty) {
    final first = options.first;
    if (first is Map) {
      final name = first['name'] ?? first['title'];
      final s = name?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
  }

  for (final key in ['option1_name', 'option1Name', 'variantLabel']) {
    final s = product[key]?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }

  return 'Variant';
}

/// True when the product payload includes a non-empty variants list
/// (including Shopify GraphQL `{edges: [{node: ...}]}` envelopes).
bool productHasVariantPayload(Map<String, dynamic> product) {
  return rawProductVariantMaps(product).isNotEmpty;
}

/// Flattens catalog / Shopify variant payloads into raw variant maps.
List<Map<String, dynamic>> rawProductVariantMaps(Map<String, dynamic> product) {
  return _variantMapsFrom(product['variants']) ??
      _variantMapsFrom(product['productVariants']) ??
      const [];
}

List<Map<String, dynamic>>? _variantMapsFrom(dynamic raw) {
  if (raw is Map) {
    final edges = raw['edges'] ?? raw['nodes'];
    if (edges is List) return _variantMapsFrom(edges);
    if (raw['node'] is Map) {
      return [Map<String, dynamic>.from(raw['node'] as Map)];
    }
    return null;
  }
  if (raw is! List || raw.isEmpty) return null;

  final out = <Map<String, dynamic>>[];
  for (final entry in raw) {
    if (entry is Map && entry['node'] is Map) {
      out.add(Map<String, dynamic>.from(entry['node'] as Map));
      continue;
    }
    if (entry is Map) {
      out.add(Map<String, dynamic>.from(entry));
    }
  }
  return out.isEmpty ? null : out;
}

/// Parses [product]['variants'] into displayable options.
///
/// Unavailable variants stay in the list so size/color chips still appear when
/// only one option is in stock. Options without a label are skipped.
List<ProductVariantOption> parseProductVariants(Map<String, dynamic> product) {
  final variants = rawProductVariantMaps(product);
  if (variants.isEmpty) return [];

  final parsed = <ProductVariantOption>[];
  for (final entry in variants) {
    final option = _parseVariantOption(entry);
    if (option != null) parsed.add(option);
  }
  return parsed;
}

ProductVariantOption? _parseVariantOption(Map<String, dynamic> variant) {
  final label = _variantDisplayLabel(variant);
  if (label.isEmpty) return null;

  final selling = _variantSellingPrice(variant);
  final retail = _variantRetailPrice(variant, selling);
  final id = _variantId(variant);

  return ProductVariantOption(
    id: id,
    label: label,
    sellingPrice: selling,
    retailPrice: retail,
    available: _variantIsAvailable(variant),
    inventoryQuantity: parseVariantInventoryQuantity(variant),
    raw: variant,
  );
}

/// Remaining units from catalog / Shopify-style variant payloads.
int? parseVariantInventoryQuantity(Map<String, dynamic> variant) {
  for (final key in [
    'inventory_quantity',
    'inventoryQuantity',
    'available_quantity',
    'availableQuantity',
    'quantity',
    'stock',
    'inventory',
  ]) {
    final value = variant[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }

  final availableQty = variant['available'];
  if (availableQty is num) return availableQty.toInt();

  final item = variant['inventoryItem'] ?? variant['inventory_item'];
  if (item is Map) {
    return parseVariantInventoryQuantity(Map<String, dynamic>.from(item));
  }
  return null;
}

/// Caption such as `2 left` when stock is at or below [threshold].
String? remainingStockCaption(
  int? quantity, {
  required bool show,
  required int threshold,
}) {
  if (!show || quantity == null) return null;
  if (quantity <= 0 || quantity > threshold) return null;
  return '$quantity left';
}

String _variantId(Map<String, dynamic> variant) {
  for (final key in ['variant_id', 'variantId', 'id']) {
    final s = variant[key]?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
}

String _variantDisplayLabel(Map<String, dynamic> variant) {
  for (final key in ['title', 'name', 'label', 'value']) {
    final s = variant[key]?.toString().trim() ?? '';
    if (s.isNotEmpty && s.toLowerCase() != 'default title') return s;
  }

  final parts = <String>[];
  for (final key in ['option1', 'option2', 'option3']) {
    final s = variant[key]?.toString().trim() ?? '';
    if (s.isNotEmpty) parts.add(s);
  }
  if (parts.isNotEmpty) return parts.join(' / ');

  final selected = variant['selectedOptions'] ?? variant['selected_options'];
  if (selected is List) {
    for (final option in selected) {
      if (option is! Map) continue;
      final value =
          (option['value'] ?? option['option'])?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'default title') {
        parts.add(value);
      }
    }
    if (parts.isNotEmpty) return parts.join(' / ');
  }

  return '';
}

double _variantSellingPrice(Map<String, dynamic> variant) {
  final selling = optionalApiPrice(variant['sellingPrice']) ??
      optionalApiPrice(variant['selling_price']);
  if (selling != null) return selling;
  return parseApiNumber(variant['price']);
}

double? _variantRetailPrice(Map<String, dynamic> variant, double selling) {
  for (final key in [
    'retailPrice',
    'retail_price',
    'compare_at_price',
    'compareAtPrice',
    'mrp',
  ]) {
    final parsed = optionalApiPrice(variant[key]);
    if (parsed != null) return parsed;
  }
  return selling > 0 ? selling : null;
}

bool _variantIsAvailable(Map<String, dynamic> variant) {
  final inventory = parseVariantInventoryQuantity(variant);
  if (inventory != null) return inventory > 0;

  final available = variant['available'];
  if (available is bool) return available;

  final inStock = variant['in_stock'] ?? variant['inStock'];
  if (inStock is bool) return inStock;

  final availableForSale =
      variant['availableForSale'] ?? variant['available_for_sale'];
  if (availableForSale is bool) return availableForSale;

  return true;
}

/// Display label for a cart / wishlist line from product payload (selected variant or `variant` key).
String variantLabelFromProductMap(Map<String, dynamic> product) {
  final direct = product['variant']?.toString().trim() ?? '';
  if (direct.isNotEmpty && direct.toLowerCase() != 'default title') {
    return direct;
  }

  final selected = product['selectedVariant'];
  if (selected is Map) {
    final label = _variantDisplayLabel(Map<String, dynamic>.from(selected));
    if (label.isNotEmpty) return label;
  }

  return '';
}

/// Selected Shopify / catalog variant id from a cart line product map.
String selectedVariantIdFromProductMap(Map<String, dynamic> product) {
  for (final key in ['selectedVariantId', 'variant_id', 'variantId']) {
    final s = product[key]?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  final selected = product['selectedVariant'];
  if (selected is Map) {
    final id = _variantId(Map<String, dynamic>.from(selected));
    if (id.isNotEmpty) return id;
  }
  return '';
}

/// Stable cart line key: `productId` plus selected variant so size/color
/// choices stay as separate rows.
String cartLineKey({
  required String productId,
  Map<String, dynamic>? product,
}) {
  final pid = productId.trim();
  if (pid.isEmpty) return '';
  final map = product ?? const <String, dynamic>{};
  var variantId = selectedVariantIdFromProductMap(map);
  if (variantId.isEmpty) {
    variantId = variantLabelFromProductMap(map);
  }
  if (variantId.isEmpty) return pid;
  return '$pid::$variantId';
}

/// True when the product can be sold: any parsed variant is in stock, or
/// product-level availability when there are no variants.
bool catalogProductIsInStock(Map<String, dynamic> product) {
  final variants = parseProductVariants(product);
  if (variants.isNotEmpty) {
    return variants.any((v) => !v.isOutOfStock);
  }
  if (product['available'] is bool) return product['available'] as bool;
  final inStock = product['in_stock'] ?? product['inStock'];
  if (inStock is bool) return inStock;
  final availableForSale =
      product['availableForSale'] ?? product['available_for_sale'];
  if (availableForSale is bool) return availableForSale;
  final qty = parseVariantInventoryQuantity(product);
  if (qty != null) return qty > 0;
  return true;
}

/// Merges the selected variant into a product map for cart / checkout actions.
Map<String, dynamic> productWithSelectedVariant(
  Map<String, dynamic> product,
  ProductVariantOption variant,
) {
  final retail = variant.retailPrice ?? variant.sellingPrice;
  var discount = 0;
  if (retail > variant.sellingPrice && retail > 0) {
    discount = (((retail - variant.sellingPrice) / retail) * 100).round();
  }

  return {
    ...product,
    'sellingPrice': variant.sellingPrice,
    'retailPrice': retail,
    'price': variant.sellingPrice.toString(),
    'discountPercent': discount,
    'selectedVariantId': variant.id,
    'selectedVariant': variant.raw,
    'variant_id': variant.id.isNotEmpty ? variant.id : product['variant_id'],
    'variant': variant.label,
  };
}
