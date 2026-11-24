import 'package:flutter/widgets.dart';
import 'responsive.dart';
import 'widget_node.dart';
import 'registry.dart';
import '../plp/plp_layout_scope.dart';
import '../utils/component_shadow.dart';
import '../utils/media_block_padding.dart';
import '../widgets/animated_block_column.dart';
import '../widgets/preview_block_anchor.dart';

/// Default vertical space between blocks when rendered in a column.
const double kDefaultBlockSpacing = 12.0;

/// Default page inset (horizontal + bottom). Content sits flush under the toolbar.
const double kPageContentInset = 8.0;

bool _isPaddingToggleBlock(WidgetNode node) => isMediaPaddingToggleBlock(node);

bool _horizontalPaddingEnabled(WidgetNode node) =>
    mediaBlockHorizontalPaddingEnabled(node);

bool _verticalPaddingEnabled(WidgetNode node) =>
    mediaBlockVerticalPaddingEnabled(node);

bool _usesFullBleedPdpBlock(WidgetNode node) {
  final type = node.type.toLowerCase().trim();
  if (type == 'product_block' && node.b('embed_in_pdp')) return true;
  // Edge-to-edge under app bar / top tabs (no page-level horizontal inset).
  switch (type) {
    case 'carousel':
    case 'image_slider':
      return true;
    case 'custom_block':
    case 'image_banner':
    case 'image_grid':
    case 'video':
    case 'pdp_product_image':
    case 'expandable_info':
      return !_horizontalPaddingEnabled(node);
    default:
      return false;
  }
}

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
    case 'expandable_info':
    case 'wishlist_item':
    case 'discount_code':
    case 'cta_button':
    case 'sort_filter':
    case 'popular_choices':
    case 'search_bar':
    case 'custom_block':
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
    case 'pdp_product_quantity':
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
  if (t == 'product_block' &&
      (node.b('embed_in_grid') || node.b('embed_in_list'))) {
    return true;
  }
  if (t == 'product_block' && node.b('embed_in_pdp')) return true;
  return false;
}

/// Soft elevation behind CMS blocks ([AppDropRenderer] / nested [env.renderNode]).
Widget _maybeApplyComponentShadow(
  BuildContext context,
  WidgetNode node,
  Widget child,
) {
  if (_shadowExcludedForWidget(node) || !blockShadowEnabled(node)) return child;

  return DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: appDropRendererBlockShadowsOf(context),
    ),
    child: child,
  );
}

bool _isSpacerBlock(WidgetNode node) =>
    node.type.toLowerCase().trim() == 'spacer';

double _spacerSizeDp(WidgetNode node) => node.d('sizeDp', def: 12);

bool _isZeroHeightSpacer(WidgetNode node) =>
    _isSpacerBlock(node) && _spacerSizeDp(node) <= 0;

/// Shell-only blocks rendered outside [AppDropRenderer] (search field, toolbar).
bool _isNonVisualShellBlock(WidgetNode node) {
  switch (node.type.toLowerCase().trim()) {
    case 'search_bar':
    case 'app_toolbar':
      return true;
    default:
      return false;
  }
}

String _uniqueBlockChangeId(
  WidgetNode node,
  int index,
  Set<String> used,
) {
  var id = node.id.trim();
  if (id.isEmpty) id = '${node.type}#$index';
  if (used.add(id)) return id;
  var n = 1;
  while (!used.add('$id~$n')) {
    n++;
  }
  return '$id~$n';
}

/// Default [kDefaultBlockSpacing] is skipped next to non-zero spacer blocks — gap comes from [sizeDp].
/// Zero-height spacers are omitted so neighboring blocks keep their normal spacing.
bool _shouldAddBlockSpacing(WidgetNode previous, WidgetNode current) {
  if (_isSpacerBlock(previous) || _isSpacerBlock(current)) return false;
  return true;
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

  /// Default horizontal inset applied per block (non-PDP pages).
  /// Image / video banners skip this when their horizontal padding toggle is off.
  final double parentHorizontalInset;

  /// Top inset from the parent scroll view. The first image / video banner uses
  /// this to sit flush when its vertical padding toggle is off.
  final double parentTopInset;

  /// Home-only product grid title / view-all header row.
  final bool showProductGridHomeTitle;

  /// When false, disables storefront-only tap behaviors in the theme builder preview.
  final bool interactiveFeaturesEnabled;

  /// When true, later insert/remove of page blocks animates in the preview.
  /// First paint of a page is still instant.
  final bool animateBlockChanges;

  /// When true, each block is anchored so [scrollToBlockId] can bring it on screen.
  final bool syncScrollToBlock;

  /// Builder left-panel selection. When this id appears, that block scrolls to
  /// the top of the preview viewport.
  final String? scrollToBlockId;

  /// Bumped when preview should re-scroll to [scrollToBlockId] (reorder / re-click).
  final int scrollGeneration;

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
    this.parentHorizontalInset = 0,
    this.parentTopInset = 0,
    this.showProductGridHomeTitle = false,
    this.interactiveFeaturesEnabled = true,
    this.animateBlockChanges = false,
    this.syncScrollToBlock = false,
    this.scrollToBlockId,
    this.scrollGeneration = 0,
  });

  @override
  Widget build(BuildContext context) {
    final reg = registry ?? WidgetRegistry.defaults();

    final page = LayoutBuilder(
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
          return _maybeApplyComponentShadow(context, node, builder(ctx, node, env));
        }

        final children = <Widget>[];
        final animatedItems = <AnimatedBlockItem>[];
        final usedIds = <String>{};
        final layoutSignature = [
          for (final node in nodes)
            if (!_isZeroHeightSpacer(node) && !_isNonVisualShellBlock(node))
              node.id,
        ].join('|');
        var lastRenderedIndex = -1;
        for (var i = 0; i < nodes.length; i++) {
          if (_isZeroHeightSpacer(nodes[i])) continue;
          if (_isNonVisualShellBlock(nodes[i])) continue;

          final node = nodes[i];
          final isToggleBlock = _isPaddingToggleBlock(node);
          final addSpacing = lastRenderedIndex >= 0 &&
              blockSpacing > 0 &&
              _shouldAddBlockSpacing(
                nodes[lastRenderedIndex],
                node,
              ) &&
              !(isToggleBlock && !_verticalPaddingEnabled(node));
          if (!animateBlockChanges && addSpacing) {
            children.add(SizedBox(height: blockSpacing));
          }
          var block = renderNode(context, node);
          final pdpInset = contentHorizontalPadding;
          if (pdpInset != null &&
              pdpInset > 0 &&
              !_usesFullBleedPdpBlock(node)) {
            block = Padding(
              padding: EdgeInsets.symmetric(horizontal: pdpInset),
              child: block,
            );
          } else if (pdpInset == null &&
              parentHorizontalInset > 0 &&
              !_usesFullBleedPdpBlock(node)) {
            block = Padding(
              padding: EdgeInsets.symmetric(horizontal: parentHorizontalInset),
              child: block,
            );
          }
          if (isToggleBlock &&
              lastRenderedIndex < 0 &&
              !_verticalPaddingEnabled(node) &&
              parentTopInset > 0) {
            block = Transform.translate(
              offset: Offset(0, -parentTopInset),
              child: block,
            );
          }
          final blockId = (animateBlockChanges || syncScrollToBlock)
              ? _uniqueBlockChangeId(node, i, usedIds)
              : '';
          if (syncScrollToBlock && blockId.isNotEmpty) {
            block = PreviewBlockAnchor(
              key: ValueKey<String>(blockId),
              blockId: blockId,
              scrollToBlockId: scrollToBlockId,
              scrollGeneration: scrollGeneration,
              layoutSignature: layoutSignature,
              child: block,
            );
          }
          if (animateBlockChanges) {
            block = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (addSpacing) SizedBox(height: blockSpacing),
                block,
              ],
            );
            animatedItems.add(
              AnimatedBlockItem(
                id: blockId,
                child: block,
              ),
            );
          } else {
            children.add(block);
          }
          lastRenderedIndex = i;
        }
        if (animateBlockChanges) {
          return AnimatedBlockColumn(items: animatedItems);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );

    if (context.getInheritedWidgetOfExactType<PlpLayoutScope>() != null) {
      return page;
    }
    return PlpLayoutHost(child: page);
  }
}
