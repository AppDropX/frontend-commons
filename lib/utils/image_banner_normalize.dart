import '../pdp/pdp_image_banner_visibility.dart';
import '../plp/plp_image_banner_visibility.dart';

/// Maps snake_case padding flags used by some CMS payloads onto renderer keys.
void normalizeBannerPaddingProps(Map<String, dynamic> props) {
  if (props['horizontalPadding'] == null && props['horizontal_padding'] != null) {
    props['horizontalPadding'] = props['horizontal_padding'];
  }
  if (props['verticalPadding'] == null && props['vertical_padding'] != null) {
    props['verticalPadding'] = props['vertical_padding'];
  }
}

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
  normalizeBannerPaddingProps(props);
  normalizeImageBannerPdpVisibility(props);
  normalizeImageBannerPlpVisibility(props);
}
