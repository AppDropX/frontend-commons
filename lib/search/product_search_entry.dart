import '../product/product_variant_model.dart';
import '../utils/shopify_image_url.dart';

/// How much of a description contributes to matching.
const int kProductSearchDescriptionChars = 240;

/// One searchable product with match text precomputed once.
class ProductSearchEntry {
  const ProductSearchEntry({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.price,
    required this.retailPrice,
    required this.discountPercent,
    required this.haystack,
    this.product,
  });

  factory ProductSearchEntry.fromRow(Map<String, dynamic> row) {
    final id = _productId(row);
    final title = (row['title'] ?? '').toString();
    final vendor = (row['vendor'] ?? '').toString();
    final description = _plainText(row['description']?.toString() ?? '');
    final selling = sellingPriceFromApiProduct(row);
    final retail = retailPriceFromApiProduct(row, selling);
    final discount = _discountPercent(row, selling, retail);
    return ProductSearchEntry(
      id: id,
      title: title,
      thumbnailUrl: productThumbnailUrl(row),
      price: selling,
      retailPrice: retail,
      discountPercent: discount,
      haystack:
          '$title\u0000$vendor\u0000$id\u0000$description'.toLowerCase(),
      product: row,
    );
  }

  final String id;
  final String title;
  final String thumbnailUrl;

  /// Selling / current price.
  final double price;

  /// Compare-at / MRP when above [price].
  final double retailPrice;

  /// Whole-number percent off when [retailPrice] > [price].
  final int discountPercent;
  final String haystack;

  /// Full product row for instant navigation without another lookup.
  final Map<String, dynamic>? product;

  /// Product-grid tile payload — prefers the full catalog row when present.
  Map<String, dynamic> toGridItem() {
    final row = product;
    if (row != null && row.isNotEmpty) {
      return Map<String, dynamic>.from(row);
    }
    return {
      'id': id,
      'productId': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': thumbnailUrl,
      'price': price,
      'sellingPrice': price,
      'retailPrice': retailPrice,
      'discountPercent': discountPercent,
    };
  }
}

/// In-memory search index over a product list.
class LocalProductSearchIndex {
  LocalProductSearchIndex(Iterable<Map<String, dynamic>> rows)
      : _entries = [
          for (final row in rows)
            if (_productId(row).isNotEmpty) ProductSearchEntry.fromRow(row),
        ];

  final List<ProductSearchEntry> _entries;

  int get length => _entries.length;

  List<ProductSearchEntry> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return [
      for (final entry in _entries)
        if (entry.haystack.contains(needle)) entry,
    ];
  }
}

int _discountPercent(
  Map<String, dynamic> row,
  double selling,
  double retail,
) {
  final direct = row['discountPercent'];
  if (direct is num && direct > 0) return direct.round();
  if (retail > selling && retail > 0) {
    return (((retail - selling) / retail) * 100).round();
  }
  return 0;
}

String _productId(Map<String, dynamic> row) {
  for (final key in const [
    'productId',
    'product_id',
    'id',
    'shopifyProductId',
    'shopify_product_id',
  ]) {
    final value = row[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _plainText(String html) {
  if (html.isEmpty) return '';
  final stripped = html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return stripped.length <= kProductSearchDescriptionChars
      ? stripped
      : stripped.substring(0, kProductSearchDescriptionChars);
}
