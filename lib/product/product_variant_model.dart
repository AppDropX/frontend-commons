/// Parsed product variant option from catalog / Shopify-style API payloads.
class ProductVariantOption {
  const ProductVariantOption({
    required this.id,
    required this.label,
    required this.sellingPrice,
    this.retailPrice,
    this.available = true,
    required this.raw,
  });

  final String id;
  final String label;
  final double sellingPrice;
  final double? retailPrice;
  final bool available;
  final Map<String, dynamic> raw;

  bool get hasPrice => sellingPrice > 0;
}

double parseApiNumber(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
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

/// Parses [product]['variants'] into displayable, available options.
List<ProductVariantOption> parseProductVariants(Map<String, dynamic> product) {
  final variants = product['variants'];
  if (variants is! List || variants.isEmpty) return [];

  final parsed = <ProductVariantOption>[];
  for (final entry in variants) {
    if (entry is! Map) continue;
    final option = _parseVariantOption(Map<String, dynamic>.from(entry));
    if (option != null && option.available) parsed.add(option);
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
    raw: variant,
  );
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

  return '';
}

double _variantSellingPrice(Map<String, dynamic> variant) {
  final selling = variant['sellingPrice'];
  if (selling != null) {
    final parsed = parseApiNumber(selling);
    if (parsed > 0) return parsed;
  }
  return parseApiNumber(variant['price']);
}

double? _variantRetailPrice(Map<String, dynamic> variant, double selling) {
  for (final key in ['retailPrice', 'compare_at_price', 'compareAtPrice', 'mrp']) {
    final raw = variant[key];
    if (raw == null) continue;
    final parsed = parseApiNumber(raw);
    if (parsed > 0) return parsed;
  }
  return selling > 0 ? selling : null;
}

bool _variantIsAvailable(Map<String, dynamic> variant) {
  final available = variant['available'];
  if (available is bool) return available;

  final inStock = variant['in_stock'] ?? variant['inStock'];
  if (inStock is bool) return inStock;

  final inventory = variant['inventory_quantity'] ?? variant['inventoryQuantity'];
  if (inventory is num) return inventory > 0;

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
