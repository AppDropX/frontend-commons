import '../pdp/pdp_image_banner_visibility.dart';

/// Ensures image banner props use the renderer keys (`fitWithImage`, `aspectRatio`, …).
void normalizeImageBannerProps(Map<String, dynamic> props) {
  if (props['fitWithImage'] == null && props['fit_with_image'] != null) {
    props['fitWithImage'] = props['fit_with_image'];
  }
  if (props['aspectRatio'] == null && props['aspect_ratio'] != null) {
    props['aspectRatio'] = props['aspect_ratio'];
  }
  if (props['radiusDp'] == null && props['radius_dp'] != null) {
    props['radiusDp'] = props['radius_dp'];
  }
  if (props['bgColor'] == null && props['bg_color'] != null) {
    props['bgColor'] = props['bg_color'];
  }
  normalizeImageBannerPdpVisibility(props);
}
