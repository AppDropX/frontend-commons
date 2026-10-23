import 'network_image_url.dart';

/// Transfer width requested for product thumbnails in cards, grids, and list rows.
///
/// Shopify resizes on its CDN, so a 300 px request replaces a ~200 KB original
/// with ~46 KB over the wire.
const int kProductThumbnailWidth = 300;

/// Shopify width for the PDP product photo. A 300 px thumbnail looks soft when
/// it is painted across the full screen.
const int kPdpProductImageWidth = 1600;

/// Hosts that honour Shopify's `width` image transform.
const List<String> _kShopifyCdnHostSuffixes = [
  'cdn.shopify.com',
  'shopifycdn.net',
  'shopifycloud.com',
  'myshopify.com',
];

/// True when [raw] is Shopify-hosted, i.e. when appending `width` actually resizes.
bool isShopifyCdnImageUrl(String? raw) {
  final normalized = sanitizedNetworkImageUrl(raw);
  if (normalized == null) return false;
  final host = Uri.parse(normalized).host.toLowerCase();
  for (final suffix in _kShopifyCdnHostSuffixes) {
    if (host == suffix || host.endsWith('.$suffix')) return true;
  }
  return false;
}

/// Adds Shopify's `width` transform to [raw], keeping every existing query
/// parameter (notably the `v=` cache buster).
///
/// Non-Shopify hosts are returned sanitized but untransformed, so this is safe
/// to apply across a mixed catalog. Idempotent: re-applying replaces the
/// previous `width` instead of appending a second one.
String? shopifyResizedImageUrl(
  String? raw, {
  int width = kProductThumbnailWidth,
}) {
  final normalized = sanitizedNetworkImageUrl(raw);
  if (normalized == null || width <= 0) return normalized;
  if (!isShopifyCdnImageUrl(normalized)) return normalized;

  final uri = Uri.parse(normalized);
  if (uri.queryParameters['width'] == '$width') return normalized;
  return uri.replace(
    queryParameters: <String, String>{
      ...uri.queryParameters,
      'width': '$width',
    },
  ).toString();
}

/// Single-image thumbnail fields, checked before falling back to the primary image.
const List<String> _kProductThumbnailKeys = [
  'thumbnail',
  'thumbnailUrl',
  'thumbnail_url',
];

/// Drops a Shopify `width` transform so a tap can open the original file.
///
/// Non-Shopify URLs are returned unchanged. Cards keep the narrowed thumbnail;
/// the fullscreen viewer asks for this original.
String hdProductImageUrl(String raw) {
  final normalized = sanitizedNetworkImageUrl(raw);
  if (normalized == null) return raw.trim();
  if (!isShopifyCdnImageUrl(normalized)) return normalized;
  final uri = Uri.parse(normalized);
  if (!uri.queryParameters.containsKey('width')) return normalized;
  final params = Map<String, String>.from(uri.queryParameters)..remove('width');
  return uri.replace(queryParameters: params).toString();
}

/// Thumbnail URL for a product row, or `''` when the row has no usable image.
///
/// Prefers an explicit `thumbnail` from the API, else narrows the primary image.
/// Gallery URLs (`images`) are deliberately left alone so PDP and the fullscreen
/// viewer keep full-resolution originals.
String productThumbnailUrl(
  Map<String, dynamic> product, {
  int width = kProductThumbnailWidth,
}) {
  String? explicit;
  for (final key in _kProductThumbnailKeys) {
    explicit = imageUrlFromApiValue(product[key]);
    if (explicit != null) break;
  }
  final source = explicit ?? bestApiProductImageUrl(product);
  return shopifyResizedImageUrl(source, width: width) ?? '';
}
