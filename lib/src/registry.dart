import 'package:flutter/widgets.dart';
import 'widget_node.dart';

// widget builders
import '../widgets/spacer.dart';
import '../widgets/text_widget.dart';
import '../widgets/rich_text.dart';
import '../widgets/image_banner.dart';
import '../widgets/image_slider.dart';
import '../widgets/image_grid.dart';
import '../widgets/carousel.dart';
import '../widgets/product_block.dart';
import '../widgets/product_grid.dart';
import '../widgets/video_block.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/cta_button.dart';
import '../widgets/discount_code.dart';
import '../widgets/product_description.dart';
import '../widgets/product_variant.dart';
import '../widgets/sort_filter.dart';
import '../widgets/cart_item.dart';

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
    r.register('video', buildVideoBlock);
    r.register('countdown_timer', buildCountdownTimer);
    r.register('cta_button', buildCtaButton);
    r.register('discount_code', buildDiscountCode);
    r.register('product_description', buildProductDescription);
    r.register('product_variant', buildProductVariant);
    r.register('sort_filter', buildSortFilter);
    r.register('cart_item', buildCartItem);
    return r;
  }
}
