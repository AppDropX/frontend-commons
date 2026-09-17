import 'package:flutter/material.dart';

import '../src/registry.dart';
import '../src/responsive.dart';
import '../src/widget_node.dart';
import 'product_grid.dart';

/// Product grid rendered as a real sliver, so tiles build and lay out lazily.
///
/// The inline [buildProductGrid] uses `GridView(shrinkWrap: true)` because it has
/// to sit inside the page-level [SingleChildScrollView] that [AppDropRenderer]
/// feeds. `shrinkWrap` makes the grid measure itself by laying out *every* child,
/// which defeats `.builder` entirely — acceptable for a home row capped by
/// `maxItemsToShow`, ruinous for a full catalog where it builds thousands of
/// tiles (and starts thousands of image loads) in a single frame.
///
/// Hosting the same tiles in a sliver restores laziness: only rows within the
/// viewport plus `cacheExtent` are ever built.
class AppDropProductSliverGrid extends StatelessWidget {
  const AppDropProductSliverGrid({
    super.key,
    required this.items,
    required this.node,
    required this.viewportWidth,
    required this.viewportHeight,
    this.registry,
    this.onAction,
    this.cartQuantityForProduct,
    this.wishlistContainsProduct,
    this.baseWidth = 320,
  });

  final List<Map<String, dynamic>> items;

  /// CMS node the tile styling derives from (`spacingDp`, `showAddToCart`, …).
  final WidgetNode node;

  final double viewportWidth;
  final double viewportHeight;
  final WidgetRegistry? registry;
  final AppDropActionHandler? onAction;
  final CartQuantityResolver? cartQuantityForProduct;
  final WishlistContainsResolver? wishlistContainsProduct;
  final double baseWidth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final reg = registry ?? WidgetRegistry.defaults();
    final r = R.fromConstraints(
      context,
      BoxConstraints(maxWidth: viewportWidth, maxHeight: viewportHeight),
      baseWidth: baseWidth,
    );

    // Mirrors [AppDropRenderer]'s nested env so `product_block` renders the same
    // way here as it does inline.
    Widget renderNode(BuildContext ctx, WidgetNode child) {
      final builder = reg.builderFor(child.type);
      if (builder == null) return const SizedBox.shrink();
      return builder(ctx, child, _envFor(renderNode, r));
    }

    final env = _envFor(renderNode, r);
    final style = ProductGridTileStyle.resolve(context, node);
    final metrics = resolveProductGridMetrics(
      env: env,
      style: style,
      width: viewportWidth,
      spacingDp: node.d('spacingDp', def: 12),
    );

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: metrics.columns,
        crossAxisSpacing: metrics.crossAxisSpacing,
        mainAxisSpacing: metrics.mainAxisSpacing,
        mainAxisExtent: metrics.tileHeight,
      ),
      delegate: SliverChildBuilderDelegate(
        (ctx, index) {
          final item = items[index];
          return KeyedSubtree(
            // Keys element identity to the product rather than the index, so
            // appending a page never re-associates state with a different row.
            key: ValueKey<String>(_tileKey(item, index)),
            child: buildProductGridTile(
              context: ctx,
              item: item,
              node: node,
              env: env,
              style: style,
              metrics: metrics,
              horizontalRow: false,
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  AppDropBuildEnv _envFor(
    Widget Function(BuildContext, WidgetNode) render,
    R r,
  ) {
    return AppDropBuildEnv(
      r: r,
      renderNode: (ctx, child) => render(ctx as BuildContext, child),
      onAction: onAction,
      cartQuantityForProduct: cartQuantityForProduct,
      wishlistContainsProduct: wishlistContainsProduct,
    );
  }
}

String _tileKey(Map<String, dynamic> item, int index) {
  final id = (item['productId'] ?? item['id'])?.toString().trim() ?? '';
  return id.isEmpty ? 'index_$index' : id;
}
