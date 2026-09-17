import 'package:flutter/material.dart';

import '../src/registry.dart';
import '../src/renderer.dart';
import '../src/widget_node.dart';
import 'product_sliver_grid.dart';

/// Search hits rendered with the same tiles as the storefront product grid.
class AppDropSearchResultGrid extends StatelessWidget {
  const AppDropSearchResultGrid({
    super.key,
    required this.items,
    required this.scrollController,
    this.pageJson = const [],
    this.registry,
    this.onAction,
    this.cartQuantityForProduct,
    this.wishlistContainsProduct,
    this.footer,
    this.pageStorageKey,
  });

  final List<Map<String, dynamic>> items;
  final ScrollController scrollController;
  final List<Map<String, dynamic>> pageJson;
  final WidgetRegistry? registry;
  final AppDropActionHandler? onAction;
  final CartQuantityResolver? cartQuantityForProduct;
  final WishlistContainsResolver? wishlistContainsProduct;
  final Widget? footer;
  final Key? pageStorageKey;

  @override
  Widget build(BuildContext context) {
    final node = searchResultGridNodeFromPageJson(pageJson);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0) return const SizedBox.shrink();
        return CustomScrollView(
          key: pageStorageKey,
          controller: scrollController,
          cacheExtent: 720,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                kPageContentInset,
                0,
                kPageContentInset,
                8,
              ),
              sliver: AppDropProductSliverGrid(
                items: items,
                node: node,
                viewportWidth: width - kPageContentInset * 2,
                viewportHeight: constraints.maxHeight,
                registry: registry,
                onAction: onAction,
                cartQuantityForProduct: cartQuantityForProduct,
                wishlistContainsProduct: wishlistContainsProduct,
              ),
            ),
            if (footer != null) SliverToBoxAdapter(child: footer),
          ],
        );
      },
    );
  }
}

/// Styling node for search hits. Reuses a search-page `product_grid` when present.
WidgetNode searchResultGridNodeFromPageJson(
  List<Map<String, dynamic>> pageJson,
) {
  Map<String, dynamic>? grid;
  for (final block in pageJson) {
    if ((block['type'] ?? '').toString() == 'product_grid') {
      grid = Map<String, dynamic>.from(block);
      break;
    }
  }
  final json = grid ??
      <String, dynamic>{
        'type': 'product_grid',
        'spacingDp': 10.0,
        'showAddToCart': false,
      };
  json['type'] = 'product_grid';
  json['layoutMode'] = 'grid';
  json['showGridTitle'] = false;
  json['showViewAllButton'] = false;
  json['showCollectionHeading'] = false;
  json.remove('items');
  json.remove('maxItemsToShow');
  return WidgetNode.fromJson(json);
}
