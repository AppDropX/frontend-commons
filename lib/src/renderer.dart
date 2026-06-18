import 'package:flutter/widgets.dart';
import 'responsive.dart';
import 'widget_node.dart';
import 'registry.dart';

/// Default vertical space between blocks when rendered in a column.
const double kDefaultBlockSpacing = 12.0;

bool _shadowExcludedForWidgetType(String type) {
  switch (type.toLowerCase().trim()) {
    case 'spacer':
      return true;
    // Radius-matched shadow is drawn inside each block builder below — avoid stacking.
    case 'image_banner':
    case 'image_grid':
    case 'carousel':
    case 'video':
    case 'image_slider':
    case 'product_grid':
    case 'related_products':
    case 'product_description':
    case 'wishlist_item':
    case 'discount_code':
    case 'cta_button':
    case 'sort_filter':
      return true;
    // Full-bleed cart / wishlist empty state: renderer shadow wraps a tall [SizedBox],
    // producing a heavy edge vignette — no per-block elevation needed.
    case 'empty_cart':
    // Cart rows are list tiles; outer shadow on each row reads as a dirty border.
    case 'cart_item':
    case 'product_variant':
    case 'pdp_product_image':
    case 'pdp_product_label':
    case 'pdp_product_price':
    case 'pdp_product_cta':
      return true;
    default:
      return false;
  }
}

/// Nested [product_block] inside [product_grid] already sits under [kAppDropComponentShadows]
/// on the tile wrapper — skipping renderer shadow avoids a second layer on the meta card.
bool _shadowExcludedForWidget(WidgetNode node) {
  if (_shadowExcludedForWidgetType(node.type)) return true;
  final t = node.type.toLowerCase().trim();
  if (t == 'product_block' && node.b('embed_in_grid')) return true;
  if (t == 'product_block' && node.b('embed_in_pdp')) return true;
  return false;
}

/// Soft elevation behind CMS blocks ([AppDropRenderer] / nested [env.renderNode]).
Widget _maybeApplyComponentShadow(WidgetNode node, Widget child) {
  if (_shadowExcludedForWidget(node)) return child;

  return DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: const Color(0x24000000),
          blurRadius: 14,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ],
    ),
    child: child,
  );
}

class AppDropRenderer extends StatelessWidget {
  final List<WidgetNode> nodes;
  final WidgetRegistry? registry;
  final double baseWidth;
  final AppDropActionHandler? onAction;

  /// Vertical space between each block. Default is [kDefaultBlockSpacing].
  final double blockSpacing;
  final CartQuantityResolver? cartQuantityForProduct;
  final WishlistContainsResolver? wishlistContainsProduct;

  /// When set (e.g. PDP without app bar), inset blocks that are not full-bleed.
  final double? contentHorizontalPadding;

  /// Home-only product grid title / view-all header row.
  final bool showProductGridHomeTitle;

  /// When false, disables storefront-only tap behaviors in the theme builder preview.
  final bool interactiveFeaturesEnabled;

  const AppDropRenderer({
    super.key,
    required this.nodes,
    this.registry,
    this.baseWidth = 320,
    this.onAction,
    this.blockSpacing = kDefaultBlockSpacing,
    this.cartQuantityForProduct,
    this.wishlistContainsProduct,
    this.contentHorizontalPadding,
    this.showProductGridHomeTitle = false,
    this.interactiveFeaturesEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final reg = registry ?? WidgetRegistry.defaults();

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth <= 0 || c.maxHeight <= 0) {
          // Parent has not been laid out yet; skip this build pass.
          return const SizedBox.shrink();
        }
        final rr = R.fromConstraints(context, c, baseWidth: baseWidth);

        Widget renderNode(BuildContext ctx, WidgetNode node) {
          final builder = reg.builderFor(node.type);
          final env = AppDropBuildEnv(
            r: rr,
            renderNode: (ctx2, n2) => renderNode(ctx2 as BuildContext, n2),
            onAction: onAction,
            cartQuantityForProduct: cartQuantityForProduct,
            wishlistContainsProduct: wishlistContainsProduct,
            showProductGridHomeTitle: showProductGridHomeTitle,
            interactiveFeaturesEnabled: interactiveFeaturesEnabled,
          );
          if (builder == null) return const SizedBox.shrink();
          return _maybeApplyComponentShadow(node, builder(ctx, node, env));
        }

        final children = <Widget>[];
        for (var i = 0; i < nodes.length; i++) {
          if (i > 0 && blockSpacing > 0) {
            children.add(SizedBox(height: blockSpacing));
          }
          var block = renderNode(context, nodes[i]);
          final inset = contentHorizontalPadding;
          if (inset != null &&
              inset > 0 &&
              !_usesFullBleedPdpBlock(nodes[i])) {
            block = Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: block,
            );
          }
          children.add(block);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}

bool _usesFullBleedPdpBlock(WidgetNode node) {
  return node.type == 'product_block' && node.b('embed_in_pdp');
}
