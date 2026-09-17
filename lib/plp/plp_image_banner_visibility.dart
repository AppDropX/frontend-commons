import '../product/product_grid_hydration.dart';

/// PLP image banner visibility: [plpVisibility] `all` (default) or `specific`.
const kImageBannerPlpVisibilityAll = 'all';
const kImageBannerPlpVisibilitySpecific = 'specific';

/// Normalizes PLP visibility keys on image banner props (`plpVisibility`, `collectionIds`).
void normalizeImageBannerPlpVisibility(Map<String, dynamic> props) {
  final rawVis = (props['plpVisibility'] ?? props['plp_visibility'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (rawVis == kImageBannerPlpVisibilitySpecific) {
    props['plpVisibility'] = kImageBannerPlpVisibilitySpecific;
  } else {
    props['plpVisibility'] = kImageBannerPlpVisibilityAll;
  }

  final ids = props['collectionIds'] ?? props['collection_ids'];
  if (ids is List) {
    props['collectionIds'] = [
      for (final e in ids)
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
  } else if (ids == null) {
    props.putIfAbsent('collectionIds', () => <String>[]);
  }
}

List<String> imageBannerTargetCollectionIds(Map<String, dynamic> block) {
  normalizeImageBannerPlpVisibility(block);
  final raw = block['collectionIds'];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
  ];
}

bool imageBannerShowsForCollection(
  Map<String, dynamic> block,
  String? collectionRef, {
  List<dynamic> collectionsRaw = const [],
}) {
  final type = (block['type'] ?? '').toString().toLowerCase();
  if (type != 'image_banner') return true;

  normalizeImageBannerPlpVisibility(block);
  final visibility = (block['plpVisibility'] ?? kImageBannerPlpVisibilityAll)
      .toString()
      .trim()
      .toLowerCase();
  if (visibility != kImageBannerPlpVisibilitySpecific) return true;

  final targets = imageBannerTargetCollectionIds(block);
  if (targets.isEmpty) return false;

  final ref = (collectionRef ?? '').trim();
  if (isAllProductsCollectionRef(ref)) {
    return targets.any(isAllProductsCollectionRef);
  }

  return targets.any(
    (t) => _collectionRefsMatch(t, ref, collectionsRaw),
  );
}

/// Removes PLP [image_banner] blocks that do not target [collectionRef].
List<Map<String, dynamic>> filterPlpBlocksForCollection(
  List<Map<String, dynamic>> cmsBlocks,
  String? collectionRef, {
  List<dynamic> collectionsRaw = const [],
}) {
  return [
    for (final w in cmsBlocks)
      if (imageBannerShowsForCollection(
        w,
        collectionRef,
        collectionsRaw: collectionsRaw,
      ))
        w,
  ];
}

bool _collectionRefsMatch(
  String a,
  String b,
  List<dynamic> collections,
) {
  final left = a.trim();
  final right = b.trim();
  if (left.isEmpty || right.isEmpty) return false;
  if (left == right) return true;
  if (left.toLowerCase() == right.toLowerCase()) return true;

  final leftSlug = slugifyCollectionKey(left);
  final rightSlug = slugifyCollectionKey(right);
  if (leftSlug.isNotEmpty && leftSlug == rightSlug) return true;

  if (collections.isEmpty) return false;
  final mapA = collectionMapForRef(left, collections);
  final mapB = collectionMapForRef(right, collections);
  final idA = (mapA?['id'] ?? '').toString().trim();
  final idB = (mapB?['id'] ?? '').toString().trim();
  if (idA.isNotEmpty && idB.isNotEmpty && idA == idB) return true;
  if (idA.isNotEmpty && _collectionRefsMatch(idA, right, const [])) return true;
  if (idB.isNotEmpty && _collectionRefsMatch(left, idB, const [])) return true;
  return false;
}
