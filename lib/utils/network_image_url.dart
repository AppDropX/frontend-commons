/// Guards [Image.network] / [NetworkImage]: rejects empty strings, whitespace-only,
/// and URIs without a usable http(s) host (avoids `NetworkImage("")` and `https://` alone).
String? sanitizedNetworkImageUrl(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  final normalized = (t.startsWith('http://') || t.startsWith('https://'))
      ? t
      : 'https://$t';
  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (!uri.hasAuthority || uri.host.isEmpty) return null;
  return normalized;
}

/// URL keys used by dashboard / Shopify style image objects.
const List<String> _kImageObjectUrlKeys = [
  'src',
  'url',
  'imageUrl',
  'image_url',
  'originalSrc',
  'original_src',
  'secureUrl',
  'secure_url',
  'transformedSrc',
  'href',
];

/// Wrapper keys used by media nodes (`{preview: {image: {src}}}`, `{node: {...}}`).
const List<String> _kImageObjectWrapperKeys = ['image', 'preview', 'node'];

/// Single-image fields, checked before list fields.
const List<String> _kProductImageKeys = [
  'imageUrl',
  'image_url',
  'image',
  'featuredImage',
  'featured_image',
  'thumbnail',
  'thumbnailUrl',
  'thumbnail_url',
];

/// Gallery fields holding several images.
const List<String> _kProductImageListKeys = [
  'images',
  'imageUrls',
  'image_urls',
  'media',
];

/// Reads an image URL out of an API value that may be a plain string, an image
/// object (`{src: …}`), a media node, or a list of either.
///
/// Never falls back to `toString()`, so maps no longer leak `"{src: …}"` into
/// [Image.network].
String? imageUrlFromApiValue(dynamic value, {int depth = 0}) {
  if (value == null || depth > 3) return null;

  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  if (value is Map) {
    for (final key in _kImageObjectUrlKeys) {
      final found = imageUrlFromApiValue(value[key], depth: depth + 1);
      if (found != null) return found;
    }
    for (final key in _kImageObjectWrapperKeys) {
      final found = imageUrlFromApiValue(value[key], depth: depth + 1);
      if (found != null) return found;
    }
    return null;
  }

  if (value is Iterable) {
    for (final entry in value) {
      final found = imageUrlFromApiValue(entry, depth: depth + 1);
      if (found != null) return found;
    }
  }

  return null;
}

/// Primary image for an API product/collection row, or `''` when none is usable.
///
/// Handles flat strings, image objects, gallery lists, and variant images so
/// collection rows (which often differ in shape from the products API) still
/// render an image.
String bestApiProductImageUrl(Map<String, dynamic> product) {
  String? pick(dynamic raw) {
    final candidate = imageUrlFromApiValue(raw);
    if (candidate == null) return null;
    return sanitizedNetworkImageUrl(candidate) == null ? null : candidate;
  }

  for (final key in _kProductImageKeys) {
    final found = pick(product[key]);
    if (found != null) return found;
  }
  for (final key in _kProductImageListKeys) {
    final found = pick(product[key]);
    if (found != null) return found;
  }

  final variants = product['variants'];
  if (variants is Iterable) {
    for (final variant in variants) {
      if (variant is! Map) continue;
      for (final key in [..._kProductImageKeys, ..._kProductImageListKeys]) {
        final found = pick(variant[key]);
        if (found != null) return found;
      }
    }
  }

  return '';
}

/// All gallery images for an API product row, sanitized and de-duplicated.
List<String> apiProductImageUrls(Map<String, dynamic> product) {
  final out = <String>[];
  void add(dynamic raw) {
    final candidate = imageUrlFromApiValue(raw);
    if (candidate == null) return;
    final sanitized = sanitizedNetworkImageUrl(candidate);
    if (sanitized == null || out.contains(sanitized)) return;
    out.add(sanitized);
  }

  for (final key in _kProductImageListKeys) {
    final raw = product[key];
    if (raw is Iterable) {
      for (final entry in raw) {
        add(entry);
      }
    } else {
      add(raw);
    }
  }
  return out;
}

/// Gallery images from a raw list value (`product['images']` and friends).
List<String> sanitizedNetworkImageUrls(dynamic raw) {
  final out = <String>[];
  if (raw is Iterable) {
    for (final entry in raw) {
      final candidate = imageUrlFromApiValue(entry);
      if (candidate == null) continue;
      final sanitized = sanitizedNetworkImageUrl(candidate);
      if (sanitized == null || out.contains(sanitized)) continue;
      out.add(sanitized);
    }
    return out;
  }
  final candidate = imageUrlFromApiValue(raw);
  if (candidate == null) return out;
  final sanitized = sanitizedNetworkImageUrl(candidate);
  if (sanitized != null) out.add(sanitized);
  return out;
}
