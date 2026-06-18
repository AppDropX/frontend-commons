/// Stable [Hero] tags for product image shared-element transitions.
///
/// Tags are scoped per [productId] so grid rows do not collide during flight.
class ProductHeroTags {
  ProductHeroTags._();

  /// Hero tag for the product image flying from PLP card → PDP.
  static String image(String productId) => 'appdrop_product_image_$productId';

  /// Unique source tag for a concrete product tile/list row instance.
  static String sourceInstance(String productId, Object instanceId) {
    return '${image(productId)}_${instanceId.hashCode}';
  }
}
