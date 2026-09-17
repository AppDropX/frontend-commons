/// Catalog query helpers shared by the PLP sort/filter bar and the products API.
library;

/// One selectable sort mapping onto `sort` + `order` query params.
class ProductSortChoice {
  const ProductSortChoice({
    required this.label,
    required this.sort,
    required this.order,
  });

  final String label;
  final String sort;
  final String order;

  bool matches(String? sortValue, String? orderValue) {
    return sortValue == sort &&
        (orderValue ?? '').toLowerCase() == order.toLowerCase();
  }
}

/// Sort values accepted by `GET /api/mobile/products`.
const List<ProductSortChoice> kProductSortChoices = [
  ProductSortChoice(label: 'Title A–Z', sort: 'title', order: 'asc'),
  ProductSortChoice(label: 'Title Z–A', sort: 'title', order: 'desc'),
  ProductSortChoice(
    label: 'Price: Low to High',
    sort: 'price',
    order: 'asc',
  ),
  ProductSortChoice(
    label: 'Price: High to Low',
    sort: 'price',
    order: 'desc',
  ),
  ProductSortChoice(label: 'Newest', sort: 'created_at', order: 'desc'),
  ProductSortChoice(
    label: 'Recently updated',
    sort: 'updated_at',
    order: 'desc',
  ),
];

/// One option facet (e.g. Size → [40, 42]).
class ProductFilterOption {
  const ProductFilterOption({required this.name, required this.values});

  final String name;
  final List<String> values;
}

/// Facets from `GET /api/mobile/products/filters`.
class ProductFilterFacets {
  const ProductFilterFacets({
    this.options = const [],
    this.minPrice,
    this.maxPrice,
  });

  final List<ProductFilterOption> options;
  final double? minPrice;
  final double? maxPrice;

  bool get hasPriceRange =>
      minPrice != null && maxPrice != null && maxPrice! > minPrice!;

  bool get isEmpty => options.isEmpty && !hasPriceRange;
}

/// Currently applied price + option filters.
class ProductFilterSelection {
  const ProductFilterSelection({
    this.minPrice,
    this.maxPrice,
    this.options = const {},
  });

  final double? minPrice;
  final double? maxPrice;

  /// Option name → selected values. Same name is OR; different names are AND.
  final Map<String, List<String>> options;

  bool get isEmpty =>
      minPrice == null &&
      maxPrice == null &&
      options.values.every((values) => values.isEmpty);

  ProductFilterSelection copyWith({
    double? minPrice,
    double? maxPrice,
    Map<String, List<String>>? options,
    bool clearPrices = false,
  }) {
    return ProductFilterSelection(
      minPrice: clearPrices ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrices ? null : (maxPrice ?? this.maxPrice),
      options: options ?? this.options,
    );
  }
}

bool isDummyProductOptionName(String name) {
  final n = name.trim().toLowerCase();
  return n.isEmpty ||
      n == 'title' ||
      n == 'dummy title' ||
      n == 'default title';
}

/// Parses the filters endpoint from a bare map, `data` envelope, or mixed keys.
ProductFilterFacets productFilterFacetsFromJson(dynamic raw) {
  final root = _asMap(raw);
  if (root == null) return const ProductFilterFacets();
  final data = _asMap(root['data']) ?? root;

  final minPrice = _numFrom(data, const [
        'min_price',
        'minPrice',
        'price_min',
        'priceMin',
      ]) ??
      _numFrom(_asMap(data['price']), const ['min', 'min_price', 'minPrice']);
  final maxPrice = _numFrom(data, const [
        'max_price',
        'maxPrice',
        'price_max',
        'priceMax',
      ]) ??
      _numFrom(_asMap(data['price']), const ['max', 'max_price', 'maxPrice']);

  final options = <ProductFilterOption>[];
  final seen = <String>{};

  void addOption(String name, Iterable<dynamic> values) {
    if (isDummyProductOptionName(name) || !seen.add(name.toLowerCase())) {
      return;
    }
    final cleaned = <String>[];
    final valueSeen = <String>{};
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty || !valueSeen.add(text.toLowerCase())) continue;
      cleaned.add(text);
    }
    if (cleaned.isEmpty) return;
    options.add(ProductFilterOption(name: name, values: cleaned));
  }

  final optionsRaw =
      data['options'] ?? data['filters'] ?? data['option_filters'];
  if (optionsRaw is List) {
    for (final entry in optionsRaw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final name = (map['name'] ?? map['key'] ?? map['option'] ?? '')
          .toString()
          .trim();
      final values = map['values'] ?? map['options'] ?? map['choices'];
      if (values is List) addOption(name, values);
    }
  } else if (optionsRaw is Map) {
    optionsRaw.forEach((key, value) {
      final name = key.toString().trim();
      if (value is List) {
        addOption(name, value);
      } else if (value is Map) {
        final nested = value['values'] ?? value['options'];
        if (nested is List) addOption(name, nested);
      }
    });
  }

  return ProductFilterFacets(
    options: options,
    minPrice: minPrice,
    maxPrice: maxPrice,
  );
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

double? _numFrom(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}
