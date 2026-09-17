import '../src/widget_node.dart';

/// Missing keys default to on so existing banners keep the current padded look.
bool mediaBlockPaddingToggleEnabled(
  WidgetNode node,
  String camel,
  String snake,
) {
  final v = node.props[camel] ?? node.props[snake];
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() != 'false';
  return true;
}

bool mediaBlockHorizontalPaddingEnabled(WidgetNode node) =>
    mediaBlockPaddingToggleEnabled(node, 'horizontalPadding', 'horizontal_padding');

bool mediaBlockVerticalPaddingEnabled(WidgetNode node) =>
    mediaBlockPaddingToggleEnabled(node, 'verticalPadding', 'vertical_padding');

bool isMediaPaddingToggleBlock(WidgetNode node) {
  final type = node.type.toLowerCase().trim();
  return type == 'image_banner' ||
      type == 'video' ||
      type == 'pdp_product_image' ||
      type == 'expandable_info' ||
      type == 'custom_block';
}
