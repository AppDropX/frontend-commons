/// Rating & Review feature temporarily disabled.
///
/// Set [kRatingReviewFeatureEnabled] to `true` to restore rating/review UI across
/// builder and storefront apps. API models and serialization are unchanged.
const bool kRatingReviewFeatureEnabled = false;

/// Safe default rating when API omits the field.
double catalogRatingFromApi(Map<String, dynamic> product) {
  final raw = product['rating'];
  if (raw is num) return raw.toDouble();
  return kRatingReviewFeatureEnabled ? 4.2 : 0;
}

/// Safe default review count when API omits the field.
int catalogRatingCountFromApi(Map<String, dynamic> product) {
  final raw = product['rating_count'] ?? product['ratingCount'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return kRatingReviewFeatureEnabled ? 48 : 0;
}
