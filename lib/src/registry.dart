import 'package:flutter/widgets.dart';
import 'widget_node.dart';

// widget builders
import '../widgets/spacer.dart';
import '../widgets/text_widget.dart';
import '../widgets/rich_text_widget.dart';
import '../widgets/image_banner.dart';
import '../widgets/image_slider.dart';
import '../widgets/image_grid.dart';
import '../widgets/carousel.dart';
import '../widgets/product_block.dart';
import '../widgets/product_grid.dart';

typedef NodeBuilder = Widget Function(BuildContext ctx, WidgetNode node, AppDropBuildEnv env);

class WidgetRegistry {
  final Map<String, NodeBuilder> _map = {};

  void register(String type, NodeBuilder builder) => _map[type] = builder;

  NodeBuilder? builderFor(String type) => _map[type];

  static WidgetRegistry defaults() {
    final r = WidgetRegistry();
    r.register('spacer', buildSpacer);
    r.register('text', buildTextWidget);
    r.register('rich_text', buildRichTextWidget);
    r.register('image_banner', buildImageBanner);
    r.register('image_slider', buildImageSlider);
    r.register('image_grid', buildImageGrid);
    r.register('carousel', buildCarousel);
    r.register('product_block', buildProductBlock);
    r.register('product_grid', buildProductGrid);
    return r;
  }
}
