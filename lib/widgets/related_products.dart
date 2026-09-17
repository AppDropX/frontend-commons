import 'package:flutter/material.dart';

import '../src/widget_node.dart';
import 'product_grid.dart';

/// PDP block: horizontal carousel of products from a linked collection.
Widget buildRelatedProducts(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final showSectionTitle = node.b('showSectionTitle', def: true);
  final sectionTitle = node.s('sectionTitle', def: 'Related Products').trim();
  final collectionTitle = node.s('collectionTitle', def: '').trim();

  final adaptedProps = Map<String, dynamic>.from(node.props);
  adaptedProps['layoutMode'] = 'carousel';
  adaptedProps['showGridTitle'] = showSectionTitle;
  adaptedProps['gridTitleText'] = sectionTitle.isNotEmpty
      ? sectionTitle
      : (collectionTitle.isNotEmpty ? collectionTitle : 'Related Products');
  adaptedProps['showViewAllButton'] = false;
  adaptedProps['showCollectionHeading'] = false;
  final sizeKey = node.s('sectionTitleFontVariation', def: 'small').toLowerCase();
  adaptedProps['gridTitleFontVariation'] = sizeKey;
  adaptedProps['gridTitleFontSize'] = _relatedTitleSizeDp(sizeKey);
  adaptedProps['gridTitleFontWeight'] =
      node.s('sectionTitleWeight', def: 'semi_bold');
  adaptedProps['gridTitleAlign'] =
      node.s('sectionTitleAlign', def: 'left').toLowerCase();

  final adaptedNode = WidgetNode(type: 'product_grid', props: adaptedProps);
  final adaptedEnv = AppDropBuildEnv(
    r: env.r,
    renderNode: env.renderNode,
    onAction: env.onAction,
    cartQuantityForProduct: env.cartQuantityForProduct,
    wishlistContainsProduct: env.wishlistContainsProduct,
    showProductGridHomeTitle: true,
    interactiveFeaturesEnabled: env.interactiveFeaturesEnabled,
  );

  return buildProductGrid(context, adaptedNode, adaptedEnv);
}

double _relatedTitleSizeDp(String variation) {
  switch (variation) {
    case 'large':
      return 16;
    case 'medium':
      return 14;
    case 'small':
    default:
      return 13;
  }
}
