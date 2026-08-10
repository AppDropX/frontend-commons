/// PDP image banner visibility: [pdpVisibility] `all` (default) or `specific`.
const kImageBannerPdpVisibilityAll = 'all';
const kImageBannerPdpVisibilitySpecific = 'specific';

/// Normalizes PDP visibility keys on image banner props (`pdpVisibility`, `productIds`).
void normalizeImageBannerPdpVisibility(Map<String, dynamic> props) {
  final rawVis = (props['pdpVisibility'] ?? props['pdp_visibility'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (rawVis == kImageBannerPdpVisibilitySpecific) {
    props['pdpVisibility'] = kImageBannerPdpVisibilitySpecific;
  } else {
    props['pdpVisibility'] = kImageBannerPdpVisibilityAll;
  }

  final ids = props['productIds'] ?? props['product_ids'];
  if (ids is List) {
    props['productIds'] = [
      for (final e in ids)
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
  } else if (ids == null) {
    props.putIfAbsent('productIds', () => <String>[]);
  }
}

List<String> imageBannerTargetProductIds(Map<String, dynamic> block) {
  normalizeImageBannerPdpVisibility(block);
  final raw = block['productIds'];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
  ];
}

bool imageBannerShowsForProduct(Map<String, dynamic> block, String productId) {
  final type = (block['type'] ?? '').toString().toLowerCase();
  if (type != 'image_banner') return true;

  normalizeImageBannerPdpVisibility(block);
  final visibility = (block['pdpVisibility'] ?? kImageBannerPdpVisibilityAll)
      .toString()
      .trim()
      .toLowerCase();
  if (visibility != kImageBannerPdpVisibilitySpecific) return true;

  final targets = imageBannerTargetProductIds(block);
  if (targets.isEmpty) return false;

  final id = productId.trim();
  if (id.isEmpty) return false;
  return targets.any((t) => t == id);
}

/// Removes PDP [image_banner] blocks that do not target [productId].
List<Map<String, dynamic>> filterPdpBlocksForProduct(
  List<Map<String, dynamic>> cmsBlocks,
  String productId,
) {
  return [
    for (final w in cmsBlocks)
      if (imageBannerShowsForProduct(w, productId)) w,
  ];
}
