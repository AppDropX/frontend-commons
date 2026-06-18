import 'package:flutter/material.dart';
import '../features/rating_review_feature.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/component_shadow.dart';

/// Horizontal and below-image inset for grid product cards.
/// Keep in sync with [kGridProductCardContentPadDp] in product_block.dart.
const double _gridProductCardContentPadDp = 8.0;
const double _gridAtcButtonDp = 32;
const double _gridAtcPaddingTopDp = 4.0;
const double _gridAtcPaddingBottomDp = _gridProductCardContentPadDp;

/// Resolves id for cart / PDP when CMS rows nest id under [action].
dynamic _gridItemProductId(Map<String, dynamic> item) {
  final top = item['productId'] ?? item['id'];
  if (top != null) return top;
  final a = item['action'];
  if (a is Map) return a['productId'] ?? a['id'];
  return null;
}

double _titleSpForVariation(String v, AppDropBuildEnv env) {
  switch (v.toLowerCase()) {
    case 'small':
      return env.r.sp(16, min: 14, max: 20);
    case 'medium':
      return env.r.sp(18, min: 15, max: 22);
    case 'large':
    default:
      return env.r.sp(20, min: 16, max: 24);
  }
}

double _viewAllSpForVariation(String v, AppDropBuildEnv env) {
  switch (v.toLowerCase()) {
    case 'large':
      return env.r.sp(16, min: 14, max: 18);
    case 'medium':
      return env.r.sp(14, min: 12, max: 16);
    case 'small':
    default:
      return env.r.sp(12, min: 11, max: 14);
  }
}

Widget _buildProductGridTile({
  required BuildContext context,
  required Map<String, dynamic> item,
  required WidgetNode node,
  required AppDropBuildEnv env,
  required bool showAddToCart,
  required String addToCartTitle,
  required bool addToCartIsOutlined,
  required String addToCartShape,
  required double addToCartTitleSize,
  required Color addToCartCtaColor,
  required Color addToCartCtaFontColor,
  required double tileW,
  required double tileH,
  required double radiusDp,
  required bool horizontalRow,
}) {
  final addToCartTextColor = addToCartCtaFontColor;

  final Map<String, dynamic>? gridAction = () {
    final a = item['action'];
    if (a is Map && a.isNotEmpty) {
      return Map<String, dynamic>.from(a);
    }
    final pid = _gridItemProductId(item);
    if (pid == null) return null;
    return {
      'type': 'open_product',
      'productId': pid,
      'product': item,
    };
  }();
  final productId = _gridItemProductId(item);
  final pidStr = productId?.toString() ?? '';
  final heroTag = pidStr.isEmpty
      ? ''
      : ProductHeroTags.sourceInstance(pidStr, item);

  final block = WidgetNode(
    type: 'product_block',
    props: {
      'embed_in_grid': true,
      'product': item,
      if (heroTag.isNotEmpty) 'heroTag': heroTag,
      if (gridAction != null) 'action': gridAction,
      'wishlistAction': {
        'type': 'toggle_wishlist',
        if (productId != null) 'productId': productId,
        'product': item,
      },
    },
  );

  final productContent = env.renderNode(context, block) as Widget;

  Widget wrapCardTap(Widget child) {
    if (gridAction == null) return child;
    final openAction = {
      ...gridAction,
      if (heroTag.isNotEmpty) 'heroTag': heroTag,
      'product': {
        ...item,
        if (heroTag.isNotEmpty) 'heroTag': heroTag,
      },
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => env.dispatchAction(context, openAction),
      child: child,
    );
  }

  final productArea = ClipRect(
    child: Align(
      alignment: Alignment.topCenter,
      child: productContent,
    ),
  );

  final radiusPx = BorderRadius.circular(env.r.dp(radiusDp));
  Widget gridCardShell({
    required Widget child,
    Widget? bottom,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: radiusPx,
        boxShadow: kAppDropComponentShadows,
      ),
      child: ClipRRect(
        borderRadius: radiusPx,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              if (bottom != null) bottom,
            ],
          ),
        ),
      ),
    );
  }

  if (!showAddToCart) {
    final card = gridCardShell(child: wrapCardTap(productArea));
    return SizedBox(
      width: horizontalRow ? tileW : double.infinity,
      height: tileH,
      child: card,
    );
  }

  final atcRadius = _addToCartRadiusFromStyle(addToCartShape, env.r);
  final atcButtonHeight = env.r.dp(_gridAtcButtonDp);
  final addPayload = {
    'type': 'add_to_cart',
    if (pidStr.isNotEmpty) 'productId': pidStr,
    'title': item['title'],
    'product': item,
  };

  final atcDecoration = BoxDecoration(
    color: addToCartIsOutlined ? Colors.transparent : addToCartCtaColor,
    borderRadius: BorderRadius.circular(atcRadius),
    border: addToCartIsOutlined
        ? Border.all(color: addToCartCtaColor, width: 1.5)
        : null,
    boxShadow: addToCartIsOutlined
        ? null
        : [
            BoxShadow(
              color: addToCartCtaColor.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
  );

  final atcButton = SizedBox(
    height: atcButtonHeight,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(atcRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => env.dispatchAction(context, addPayload),
        child: Ink(
          decoration: atcDecoration,
          child: Center(
            child: Text(
              addToCartTitle.isEmpty ? 'Add to Cart' : addToCartTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: addToCartTextColor,
                fontSize: env.r.sp(
                  addToCartTitleSize.clamp(12, 24).toDouble(),
                  min: 12,
                  max: 24,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final card = gridCardShell(
    child: wrapCardTap(productArea),
    bottom: Padding(
      padding: EdgeInsets.fromLTRB(
        env.r.dp(_gridProductCardContentPadDp),
        env.r.dp(_gridAtcPaddingTopDp),
        env.r.dp(_gridProductCardContentPadDp),
        env.r.dp(_gridAtcPaddingBottomDp),
      ),
      child: atcButton,
    ),
  );

  return SizedBox(
    width: horizontalRow ? tileW : double.infinity,
    height: tileH,
    child: card,
  );
}

Widget buildProductGrid(
    BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final itemsRawFull = node.l('items') ?? const [];
  if (itemsRawFull.isEmpty) return const SizedBox.shrink();

  final maxItems = node.i('maxItemsToShow', def: 0);
  final itemsRaw = (maxItems > 0 && itemsRawFull.length > maxItems)
      ? itemsRawFull.sublist(0, maxItems)
      : itemsRawFull;

  final spacingDp = node.d('spacingDp', def: 12);
  final collectionHeading = _gridCollectionHeading(node);
  final onHomePage = env.showProductGridHomeTitle;
  final showCollectionHeading =
      onHomePage && node.b('showCollectionHeading', def: true);
  final addToCartTitle = _addToCartTitle(node);
  final addToCartTitleSize = node.d('addToCartTitleSize', def: 16);

  final showGridTitle = onHomePage && node.b('showGridTitle', def: false);
  final showViewAllButton =
      onHomePage && node.b('showViewAllButton', def: false);
  final gridTitleText = node.s('gridTitleText', def: '').trim();
  final resolvedTitle =
      gridTitleText.isNotEmpty ? gridTitleText : collectionHeading;
  final gridTitleFontVariation = node.s('gridTitleFontVariation', def: 'large');
  final gridTitleAlign = node.s('gridTitleAlign', def: 'left').toLowerCase();
  final gridTitleColor =
      parseHexColor(node.s('gridTitleColor', def: '#000000')) ??
          const Color(0xFF000000);
  final viewAllRaw = node.s('viewAllLabel', def: 'View All').trim();
  final viewAllLabel = viewAllRaw.isEmpty ? 'View All' : viewAllRaw;
  final viewAllFontVariation = node.s('viewAllFontVariation', def: 'small');
  final viewAllFontColor =
      parseHexColor(node.s('viewAllFontColor', def: '#333333')) ??
          const Color(0xFF333333);
  final layoutMode = node.s('layoutMode', def: 'grid').toLowerCase();
  final isCarousel = layoutMode == 'carousel' || layoutMode == 'horizontal';

  const double maxTileDp = 190;
  final useSectionHeader = showGridTitle || showViewAllButton;
  final legacyHeader = !useSectionHeader &&
      showCollectionHeading &&
      collectionHeading.isNotEmpty;

  return LayoutBuilder(
    builder: (ctx, constraints) {
      final spacing = env.r.dp(spacingDp);
      final maxTileW = env.r.dp(maxTileDp);
      final width = constraints.maxWidth;
      if (width <= 0) {
        // Avoid layout exceptions/log spam in the first unconstrained pass.
        return const SizedBox.shrink();
      }

      final scope = AppDropThemeScope.maybeOf(ctx);
      final pb = scope?.productBlock ?? const <String, dynamic>{};
      final showAddToCart =
          _b(pb, 'add_to_cart', node.b('showAddToCart', def: false));
      final buttonStyleRaw =
          (pb['button_style'] ?? '').toString().toLowerCase().trim();
      final buttonParts = buttonStyleRaw
          .split(RegExp(r'[_\-\s]+'))
          .where((e) => e.isNotEmpty)
          .toList();
      final addToCartShape =
          buttonParts.isNotEmpty ? buttonParts.first : 'rounded';
      final addToCartType = buttonParts.length > 1 ? buttonParts[1] : 'filled';
      final addToCartIsOutlined = addToCartType == 'outlined';
      final addToCartCtaColor = addToCartIsOutlined
          ? (parseHexColor(
                  (pb['outlined_button_bg'] ?? '#FF6A00').toString()) ??
              const Color(0xFFFF6A00))
          : (parseHexColor((pb['filled_button_bg'] ?? '#FF6A00').toString()) ??
              const Color(0xFFFF6A00));
      final addToCartCtaFontColor = addToCartIsOutlined
          ? (parseHexColor(
                  (pb['outlined_button_color'] ?? '#FF6A00').toString()) ??
              const Color(0xFFFF6A00))
          : (parseHexColor(
                  (pb['filled_button_color'] ?? '#FFFFFF').toString()) ??
              const Color(0xFFFFFFFF));

      final radiusDp = _d(pb, 'corner_radius', 12);
      final maxLines = _i(pb, 'max_lines', 2);
      final showVendor = _b(pb, 'show_vendor', true);
      // Rating & Review feature temporarily disabled
      final showRating =
          kRatingReviewFeatureEnabled && _b(pb, 'show_rating', true);
      final showSwatches = _b(pb, 'show_swatches', true);
      final aspectIdx = _i(pb, 'image_aspect_ratio_index', 0);
      final aspect = _aspectFromIndex(aspectIdx);

      final addToCartExtra = showAddToCart
          ? env.r.dp(_gridAtcPaddingTopDp) +
              env.r.dp(_gridAtcButtonDp) +
              env.r.dp(_gridAtcPaddingBottomDp)
          : 0.0;

      late final double tileW;
      late final double tileH;
      late final int gridCols;

      if (isCarousel) {
        gridCols = 1;
        tileW = maxTileW.clamp(120.0, width * 0.48);
        final imageH = tileW / aspect;
        final metaH = _estimateMetaHeight(
            env, maxLines, showVendor, showRating, showSwatches);
        tileH = imageH + metaH + addToCartExtra;
      } else {
        gridCols = (width / maxTileW).floor().clamp(2, 3);
        tileW = (width - spacing * (gridCols - 1)) / gridCols;
        final imageH = tileW / aspect;
        final metaH = _estimateMetaHeight(
            env, maxLines, showVendor, showRating, showSwatches);
        tileH = imageH + metaH + addToCartExtra;
      }

      final mainGap = spacing * 0.65;

      Widget grid;
      if (isCarousel) {
        grid = SizedBox(
          height: tileH,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: itemsRaw.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (c, i) {
              final item = Map<String, dynamic>.from(itemsRaw[i] as Map);
              return _buildProductGridTile(
                context: c,
                item: item,
                node: node,
                env: env,
                showAddToCart: showAddToCart,
                addToCartTitle: addToCartTitle,
                addToCartIsOutlined: addToCartIsOutlined,
                addToCartShape: addToCartShape,
                addToCartTitleSize: addToCartTitleSize,
                addToCartCtaColor: addToCartCtaColor,
                addToCartCtaFontColor: addToCartCtaFontColor,
                tileW: tileW,
                tileH: tileH,
                radiusDp: radiusDp,
                horizontalRow: true,
              );
            },
          ),
        );
      } else {
        grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsRaw.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: mainGap,
            mainAxisExtent: tileH,
          ),
          itemBuilder: (c, i) {
            final item = Map<String, dynamic>.from(itemsRaw[i] as Map);
            return _buildProductGridTile(
              context: c,
              item: item,
              node: node,
              env: env,
              showAddToCart: showAddToCart,
              addToCartTitle: addToCartTitle,
              addToCartIsOutlined: addToCartIsOutlined,
              addToCartShape: addToCartShape,
              addToCartTitleSize: addToCartTitleSize,
              addToCartCtaColor: addToCartCtaColor,
              addToCartCtaFontColor: addToCartCtaFontColor,
              tileW: tileW,
              tileH: tileH,
              radiusDp: radiusDp,
              horizontalRow: false,
            );
          },
        );
      }

      Widget? header;
      if (useSectionHeader &&
          (showGridTitle && resolvedTitle.isNotEmpty || showViewAllButton)) {
        final titleStyle = TextStyle(
          fontSize: _titleSpForVariation(gridTitleFontVariation, env),
          fontWeight: FontWeight.w700,
          color: gridTitleColor,
        );
        final showTitleRow = showGridTitle && resolvedTitle.isNotEmpty;
        header = Padding(
          padding: EdgeInsets.only(bottom: env.r.dp(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showTitleRow)
                Expanded(
                  child: Align(
                    alignment: gridTitleAlign == 'center'
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: Text(
                      resolvedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                      textAlign: gridTitleAlign == 'center'
                          ? TextAlign.center
                          : TextAlign.left,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (showViewAllButton)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: env.r.dp(4), vertical: env.r.dp(4)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    final col =
                        node.s('gridCollectionId', def: '').trim().isEmpty
                            ? node.s('collection', def: 'all').trim()
                            : node.s('gridCollectionId', def: '').trim();
                    if (col.isEmpty || col.toLowerCase() == 'all') {
                      env.dispatchAction(ctx, {'type': 'open_collection'});
                    } else {
                      env.dispatchAction(ctx, {
                        'type': 'open_collection',
                        'collection': col,
                      });
                    }
                  },
                  child: Text(
                    viewAllLabel,
                    style: TextStyle(
                      fontSize:
                          _viewAllSpForVariation(viewAllFontVariation, env),
                      fontWeight: FontWeight.w600,
                      color: viewAllFontColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      } else if (legacyHeader) {
        header = Padding(
          padding: EdgeInsets.only(bottom: env.r.dp(6)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              collectionHeading,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: env.r.sp(16, min: 14, max: 18),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }

      if (header == null) return grid;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [header, grid],
      );
    },
  );
}

double _estimateMetaHeight(AppDropBuildEnv env, int maxLines, bool showVendor,
    bool showRating, bool showSwatches) {
  // Compact grid meta — mirrors [buildProductBlock] when embed_in_grid is true.
  const gridMetaPadTop = _gridProductCardContentPadDp;
  const gridMetaPadBottom = 0.0;
  const vendorBottomGap = 2.0;
  const vendorLineDp = 16.0;
  const titleLineDp = 20.0;
  const titlePriceGap = 4.0;
  const priceRowDp = 20.0;
  const ratingBlockDp = 24.0;
  const swatchGapDp = 8.0;
  const swatchRowDp = 18.0;
  // Buffer for font scaling / rounding vs [_gridAtcBlockDp] sum.
  const safetyDp = 4.0;

  double h = env.r.dp(gridMetaPadTop + gridMetaPadBottom + safetyDp);

  if (showVendor) {
    h += env.r.dp(vendorBottomGap + vendorLineDp);
  }

  final lines = maxLines <= 0 ? 2 : maxLines;
  h += env.r.dp(titleLineDp) * lines;

  h += env.r.dp(titlePriceGap);

  if (showRating) h += env.r.dp(ratingBlockDp);

  h += env.r.dp(priceRowDp);

  if (showSwatches) {
    h += env.r.dp(swatchGapDp + swatchRowDp);
  }

  return h;
}

bool _b(Map<String, dynamic> m, String k, bool def) {
  final v = m[k];
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return def;
}

int _i(Map<String, dynamic> m, String k, int def) {
  final v = m[k];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

double _d(Map<String, dynamic> m, String k, double def) {
  final v = m[k];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

double _aspectFromIndex(int idx) {
  switch (idx) {
    case 0:
      return 1.0;
    case 1:
      return 1.0;
    case 2:
      return 4 / 5;
    case 3:
      return 16 / 9;
    default:
      return 1.0;
  }
}

String _gridCollectionHeading(WidgetNode node) {
  final title = node.s('collectionTitle', def: '').trim();
  if (title.isNotEmpty) return title;
  final c = node.s('collection', def: '').trim();
  if (c.isEmpty || c.toLowerCase() == 'all') return '';
  return c;
}

String _addToCartTitle(WidgetNode node) {
  final a = node.s('addToCartButtonTitle', def: '').trim();
  if (a.isNotEmpty) return a;
  return node.s('addToCartLabel', def: 'Add to cart');
}

double _addToCartRadiusFromStyle(String style, R r) {
  switch (style) {
    case 'sharp':
      return 0;
    case 'blunt':
    case 'pill':
      return r.dp(999);
    case 'rounded':
    default:
      return r.dp(8);
  }
}
