import 'package:flutter/material.dart';
import '../features/rating_review_feature.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/product_image_frame.dart';
import '../utils/component_shadow.dart';
import '../utils/appdrop_snackbar.dart';
import '../utils/product_block_theme_helpers.dart';
import 'product_list_card.dart';

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

FontWeight _gridTitleFontWeight(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'regular':
      return FontWeight.w400;
    case 'semi_bold':
    case 'semibold':
      return FontWeight.w600;
    case 'bold':
    default:
      return FontWeight.w700;
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

/// Tile styling resolved from the theme scope and the grid's CMS node.
///
/// Extracted from [buildProductGrid] so a paginated sliver grid can render
/// tiles identical to the inline one instead of re-deriving the same values.
class ProductGridTileStyle {
  const ProductGridTileStyle({
    required this.showAddToCart,
    required this.addToCartTitle,
    required this.addToCartIsOutlined,
    required this.addToCartRadiusDp,
    required this.addToCartTitleSize,
    required this.addToCartCtaColor,
    required this.addToCartCtaFontColor,
    required this.radiusDp,
    required this.aspect,
    required this.maxLines,
    required this.showVendor,
    required this.showRating,
    required this.showSwatches,
    required this.titleSize,
    required this.stackedPrice,
    required this.showRetailPrice,
    required this.showDiscountValue,
  });

  factory ProductGridTileStyle.resolve(BuildContext context, WidgetNode node) {
    final pb = AppDropThemeScope.maybeOf(context)?.productBlock ??
        const <String, dynamic>{};
    final isOutlined = productBlockButtonOutlined(pb);

    return ProductGridTileStyle(
      showAddToCart: _b(pb, 'add_to_cart', node.b('showAddToCart', def: false)),
      addToCartTitle: _addToCartTitle(node),
      addToCartIsOutlined: isOutlined,
      addToCartRadiusDp: productButtonCornerRadiusDp(pb),
      addToCartTitleSize: node.d('addToCartTitleSize', def: 16),
      addToCartCtaColor: isOutlined
          ? (parseHexColor(
                  (pb['outlined_button_bg'] ?? '#FF6A00').toString()) ??
              const Color(0xFFFF6A00))
          : (parseHexColor((pb['filled_button_bg'] ?? '#FF6A00').toString()) ??
              const Color(0xFFFF6A00)),
      addToCartCtaFontColor: isOutlined
          ? (parseHexColor(
                  (pb['outlined_button_color'] ?? '#FF6A00').toString()) ??
              const Color(0xFFFF6A00))
          : (parseHexColor(
                  (pb['filled_button_color'] ?? '#FFFFFF').toString()) ??
              const Color(0xFFFFFFFF)),
      radiusDp: _d(pb, 'corner_radius', 12),
      aspect: _aspectFromIndex(_i(pb, 'image_aspect_ratio_index', 0)),
      maxLines: _i(pb, 'max_lines', 2),
      showVendor: _b(pb, 'show_vendor', true),
      // Rating & Review feature temporarily disabled
      showRating: kRatingReviewFeatureEnabled && _b(pb, 'show_rating', true),
      showSwatches: _b(pb, 'show_swatches', true),
      titleSize: productBlockSetting(pb, 'title_size', 'Medium'),
      stackedPrice:
          productBlockSetting(pb, 'price_layout', 'row').toLowerCase() ==
              'column',
      showRetailPrice: _b(pb, 'show_retail_price', true),
      showDiscountValue: _b(pb, 'show_discount', true),
    );
  }

  final bool showAddToCart;
  final String addToCartTitle;
  final bool addToCartIsOutlined;
  final double addToCartRadiusDp;
  final double addToCartTitleSize;
  final Color addToCartCtaColor;
  final Color addToCartCtaFontColor;
  final double radiusDp;
  final double aspect;
  final int maxLines;
  final bool showVendor;
  final bool showRating;
  final bool showSwatches;
  final String titleSize;
  final bool stackedPrice;
  final bool showRetailPrice;
  final bool showDiscountValue;

  /// Height the add-to-cart row adds below the card body.
  double addToCartExtent(R r) => showAddToCart
      ? r.dp(_gridAtcPaddingTopDp) +
          r.dp(_gridAtcButtonDp) +
          r.dp(_gridAtcPaddingBottomDp)
      : 0.0;

  /// Total tile height for a tile [tileWidth] wide.
  ///
  /// [reserveVendor] and [reserveSwatches] stay false when none of the
  /// visible products actually paint those rows. Reserving them anyway
  /// leaves a blank band between the price and the add-to-cart button.
  double tileHeight(
    AppDropBuildEnv env,
    double tileWidth, {
    bool reserveVendor = true,
    bool reserveSwatches = true,
  }) {
    final imageH = tileWidth / aspect;
    final metaH = _estimateMetaHeight(
      env,
      maxLines,
      showVendor && reserveVendor,
      showRating,
      showSwatches && reserveSwatches,
      titleSize: titleSize,
      stackedPrice: stackedPrice,
      showRetailPrice: showRetailPrice,
      showDiscountValue: showDiscountValue,
    );
    return imageH + metaH + addToCartExtent(env.r);
  }
}

/// Column count and tile size for one product grid.
class ProductGridMetrics {
  const ProductGridMetrics({
    required this.columns,
    required this.tileWidth,
    required this.tileHeight,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
  });

  final int columns;
  final double tileWidth;
  final double tileHeight;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
}

/// Resolves grid geometry for a viewport [width] logical pixels wide.
ProductGridMetrics resolveProductGridMetrics({
  required AppDropBuildEnv env,
  required ProductGridTileStyle style,
  required double width,
  required double spacingDp,
  bool carousel = false,
  bool reserveVendor = true,
  bool reserveSwatches = true,
}) {
  final spacing = env.r.dp(spacingDp);
  final maxTileW = env.r.dp(kProductGridMaxTileDp);

  final int columns;
  final double tileWidth;
  if (carousel) {
    columns = 1;
    tileWidth = maxTileW.clamp(120.0, width * 0.48);
  } else {
    columns = (width / maxTileW).floor().clamp(2, 3);
    tileWidth = productGridImageWidth(
      viewportWidth: width,
      spacing: spacing,
      maxTileWidth: maxTileW,
    );
  }

  return ProductGridMetrics(
    columns: columns,
    tileWidth: tileWidth,
    tileHeight: style.tileHeight(
      env,
      tileWidth,
      reserveVendor: reserveVendor,
      reserveSwatches: reserveSwatches,
    ),
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing * 0.65,
  );
}

/// Builds one product-grid tile.
///
/// Public so a paginated sliver grid renders tiles identical to the inline
/// [buildProductGrid].
Widget buildProductGridTile({
  required BuildContext context,
  required Map<String, dynamic> item,
  required WidgetNode node,
  required AppDropBuildEnv env,
  required ProductGridTileStyle style,
  required ProductGridMetrics metrics,
  required bool horizontalRow,
  bool listLayout = false,
  bool hugContent = false,
}) {
  return _buildProductGridTile(
    context: context,
    item: item,
    node: node,
    env: env,
    showAddToCart: style.showAddToCart,
    addToCartTitle: style.addToCartTitle,
    addToCartIsOutlined: style.addToCartIsOutlined,
    addToCartRadiusDp: style.addToCartRadiusDp,
    addToCartTitleSize: style.addToCartTitleSize,
    addToCartCtaColor: style.addToCartCtaColor,
    addToCartCtaFontColor: style.addToCartCtaFontColor,
    tileW: metrics.tileWidth,
    tileH: metrics.tileHeight,
    radiusDp: style.radiusDp,
    horizontalRow: horizontalRow,
    listLayout: listLayout,
    hugContent: hugContent,
  );
}

Widget _buildProductGridTile({
  required BuildContext context,
  required Map<String, dynamic> item,
  required WidgetNode node,
  required AppDropBuildEnv env,
  required bool showAddToCart,
  required String addToCartTitle,
  required bool addToCartIsOutlined,
  required double addToCartRadiusDp,
  required double addToCartTitleSize,
  required Color addToCartCtaColor,
  required Color addToCartCtaFontColor,
  required double tileW,
  required double tileH,
  required double radiusDp,
  required bool horizontalRow,
  bool listLayout = false,
  bool hugContent = false,
}) {
  final addToCartTextColor = addToCartCtaFontColor;
  final pb = AppDropThemeScope.maybeOf(context)?.productBlock ??
      const <String, dynamic>{};
  final cardView = productBlockThemeBool(pb, 'card_view', true);
  final cardBg = parseHexColor(
        (pb['card_bg_color'] ?? pb['image_bg_color'] ?? '#FFFFFF').toString(),
      ) ??
      Colors.white;
  final ctaText = _themeCtaText(pb, 'cta_text', addToCartTitle);
  final variantCtaText = _themeCtaText(pb, 'variant_cta_text', 'Choose options');
  final ctaFontVariation =
      productBlockSetting(pb, 'cta_font_variation', 'semibold');
  final ctaSizeName = productBlockSetting(pb, 'cta_font_size', 'Medium');

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
  final heroTag =
      pidStr.isEmpty ? '' : ProductHeroTags.sourceInstance(pidStr, item);

  final openAction = gridAction == null
      ? null
      : {
          ...gridAction,
          if (heroTag.isNotEmpty) 'heroTag': heroTag,
          'product': {
            ...item,
            if (heroTag.isNotEmpty) 'heroTag': heroTag,
          },
        };

  final block = WidgetNode(
    type: 'product_block',
    props: {
      'embed_in_grid': !listLayout,
      'embed_in_list': listLayout,
      'product': item,
      if (heroTag.isNotEmpty) 'heroTag': heroTag,
      if (openAction != null) 'action': openAction,
      'wishlistAction': {
        'type': 'toggle_wishlist',
        if (productId != null) 'productId': productId,
        'product': item,
      },
    },
  );

  final productContent = env.renderNode(context, block) as Widget;

  if (listLayout) {
    final listRadius = BorderRadius.circular(env.r.dp(radiusDp));
    if (!cardView) return productContent;
    return Container(
      decoration: BoxDecoration(
        borderRadius: listRadius,
        boxShadow: appDropBlockShadowsFor(context, node),
      ),
      child: ClipRRect(
        borderRadius: listRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: cardBg),
          child: productContent,
        ),
      ),
    );
  }

  Widget wrapCardTap(Widget child) {
    if (listLayout || openAction == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => env.dispatchAction(context, openAction),
      child: child,
    );
  }

  final radiusPx = BorderRadius.circular(env.r.dp(radiusDp));
  Widget gridCardShell({
    required Widget child,
    Widget? bottom,
  }) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (bottom != null) const Spacer(),
        if (bottom != null) bottom,
      ],
    );
    if (!cardView) return column;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radiusPx,
        boxShadow: appDropBlockShadowsFor(context, node),
      ),
      child: ClipRRect(
        borderRadius: radiusPx,
        child: DecoratedBox(
          decoration: BoxDecoration(color: cardBg),
          child: column,
        ),
      ),
    );
  }

  if (!showAddToCart) {
    return _gridTileBox(
      horizontalRow: horizontalRow,
      tileW: tileW,
      tileH: tileH,
      hugContent: hugContent,
      child: gridCardShell(child: wrapCardTap(productContent)),
    );
  }

  final atcRadius = env.r.dp(addToCartRadiusDp);
  final atcButtonHeight = env.r.dp(_gridAtcButtonDp);
  final soldOutCta = productSoldOutCta(pb, item);
  final atcFill = soldOutCta == null
      ? addToCartCtaColor
      : soldOutCta.background;
  final atcTextColor =
      soldOutCta?.foreground ?? addToCartTextColor;
  final addPayload = {
    'type': 'add_to_cart',
    if (pidStr.isNotEmpty) 'productId': pidStr,
    'title': item['title'],
    'product': item,
  };

  final atcDecoration = BoxDecoration(
    color: addToCartIsOutlined ? Colors.transparent : atcFill,
    borderRadius: BorderRadius.circular(atcRadius),
    border: addToCartIsOutlined
        ? Border.all(color: atcFill, width: 1.5)
        : null,
    boxShadow: addToCartIsOutlined || soldOutCta != null
        ? null
        : [
            BoxShadow(
              color: atcFill.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
  );

  final atcButton = Builder(
    builder: (buttonContext) {
      return SizedBox(
    height: atcButtonHeight,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(atcRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (soldOutCta != null) {
            showProductSoldOutSnackBar(buttonContext);
            return;
          }
          env.dispatchAction(buttonContext, addPayload);
        },
        child: Ink(
          decoration: atcDecoration,
          child: Center(
            child: Text(
              soldOutCta?.label ??
                  productListCtaLabel(
                    item,
                    ctaText,
                    variantLabel: variantCtaText,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppDropThemeData.textStyle(
                fontFamily: AppDropThemeScope.maybeOf(context)
                        ?.appStyling
                        .fontFamily ??
                    'Poppins',
                color: atcTextColor,
                fontSize: productCtaFontSize(ctaSizeName, env.r),
                fontWeight: productCtaFontWeight(ctaFontVariation),
              ),
            ),
          ),
        ),
      ),
    ),
      );
    },
  );

  final card = gridCardShell(
    child: wrapCardTap(productContent),
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

  return _gridTileBox(
    horizontalRow: horizontalRow,
    tileW: tileW,
    tileH: tileH,
    hugContent: hugContent,
    child: card,
  );
}

/// Carousel and sliver cells have a fixed height. The card fills that height
/// and pins the button to the bottom. The inline grid passes [hugContent]
/// and stretches each row to its tallest card.
Widget _gridTileBox({
  required bool horizontalRow,
  required double tileW,
  required double tileH,
  required bool hugContent,
  required Widget child,
}) {
  final Widget tile = horizontalRow ? SizedBox(width: tileW, child: child) : child;
  if (hugContent) return tile;
  return SizedBox(
    width: horizontalRow ? tileW : double.infinity,
    height: tileH,
    child: tile,
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

  final showGridTitle = onHomePage && node.b('showGridTitle', def: false);
  final showViewAllButton =
      onHomePage && node.b('showViewAllButton', def: false);
  final gridTitleText = node.s('gridTitleText', def: '').trim();
  final resolvedTitle =
      gridTitleText.isNotEmpty ? gridTitleText : collectionHeading;
  final gridTitleFontVariation = node.s('gridTitleFontVariation', def: 'large');
  final gridTitleFontSize = node.d('gridTitleFontSize', def: 0);
  final gridTitleFontWeight = _gridTitleFontWeight(
    node.s('gridTitleFontWeight', def: 'bold'),
  );
  final fontFamily =
      AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';
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

  final useSectionHeader = showGridTitle || showViewAllButton;
  final legacyHeader = !useSectionHeader &&
      showCollectionHeading &&
      collectionHeading.isNotEmpty;

  return LayoutBuilder(
    builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      if (width <= 0) {
        // Avoid layout exceptions/log spam in the first unconstrained pass.
        return const SizedBox.shrink();
      }

      final style = ProductGridTileStyle.resolve(ctx, node);
      final isList = PlpLayoutScope.watch(ctx)?.isList ?? false;
      final metrics = resolveProductGridMetrics(
        env: env,
        style: style,
        width: width,
        spacingDp: spacingDp,
        carousel: isCarousel,
        reserveVendor: _gridItemsHaveVendor(itemsRaw),
        reserveSwatches: _gridItemsHaveSwatches(itemsRaw),
      );

      Widget grid;
      if (isList) {
        grid = ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsRaw.length,
          separatorBuilder: (_, __) => SizedBox(height: env.r.dp(spacingDp)),
          itemBuilder: (c, i) {
            final item = Map<String, dynamic>.from(itemsRaw[i] as Map);
            return buildProductGridTile(
              context: c,
              item: item,
              node: node,
              env: env,
              style: style,
              metrics: metrics,
              horizontalRow: false,
              listLayout: true,
            );
          },
        );
      } else if (isCarousel) {
        grid = SizedBox(
          height: metrics.tileHeight,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: itemsRaw.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: metrics.crossAxisSpacing),
            itemBuilder: (c, i) {
              final item = Map<String, dynamic>.from(itemsRaw[i] as Map);
              return buildProductGridTile(
                context: c,
                item: item,
                node: node,
                env: env,
                style: style,
                metrics: metrics,
                horizontalRow: true,
              );
            },
          ),
        );
      } else {
        grid = _contentSizedProductGrid(
          columns: metrics.columns,
          crossAxisSpacing: metrics.crossAxisSpacing,
          mainAxisSpacing: metrics.mainAxisSpacing,
          itemCount: itemsRaw.length,
          itemBuilder: (i) {
            final item = Map<String, dynamic>.from(itemsRaw[i] as Map);
            return buildProductGridTile(
              context: ctx,
              item: item,
              node: node,
              env: env,
              style: style,
              metrics: metrics,
              horizontalRow: false,
              hugContent: true,
            );
          },
        );
      }

      Widget? header;
      if (useSectionHeader &&
          (showGridTitle && resolvedTitle.isNotEmpty || showViewAllButton)) {
        final titleStyle = AppDropThemeData.textStyle(
          fontFamily: fontFamily,
          fontSize: gridTitleFontSize > 0
              ? env.r.sp(gridTitleFontSize, min: 11, max: 24)
              : _titleSpForVariation(gridTitleFontVariation, env),
          fontWeight: gridTitleFontWeight,
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

/// Rows of product cards. Every card in a row matches the tallest card, and
/// the add-to-cart buttons sit on the same line.
Widget _contentSizedProductGrid({
  required int columns,
  required double crossAxisSpacing,
  required double mainAxisSpacing,
  required int itemCount,
  required Widget Function(int index) itemBuilder,
}) {
  final safeColumns = columns < 1 ? 1 : columns;
  final rows = (itemCount / safeColumns).ceil();
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var row = 0; row < rows; row++) ...[
        if (row > 0) SizedBox(height: mainAxisSpacing),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var col = 0; col < safeColumns; col++) ...[
                if (col > 0) SizedBox(width: crossAxisSpacing),
                Expanded(
                  child: row * safeColumns + col < itemCount
                      ? itemBuilder(row * safeColumns + col)
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

double _estimateMetaHeight(
  AppDropBuildEnv env,
  int maxLines,
  bool showVendor,
  bool showRating,
  bool showSwatches, {
  String titleSize = 'Medium',
  bool stackedPrice = false,
  bool showRetailPrice = true,
  bool showDiscountValue = true,
}) {
  // Compact grid meta — mirrors [buildProductBlock] when embed_in_grid is true.
  const gridMetaPadTop = _gridProductCardContentPadDp;
  const gridMetaPadBottom = 0.0;
  const vendorBottomGap = 2.0;
  const vendorLineDp = 16.0;
  final normalizedTitle = titleSize.trim().toLowerCase();
  final titleLineDp = normalizedTitle == 'large'
      ? 24.0
      : normalizedTitle == 'small'
          ? 16.0
          : 20.0;
  const titlePriceGap = 4.0;
  // One line per visible price, sized to the rendered font plus the 2px
  // gap the column layout inserts. Extra multiples here become blank space
  // under the discount, above the add-to-cart button.
  final priceRowDp = stackedPrice
      ? 18.0 + (showRetailPrice ? 16.0 : 0) + (showDiscountValue ? 14.0 : 0)
      : 20.0;
  const ratingBlockDp = 24.0;
  const swatchGapDp = 8.0;
  const swatchRowDp = 18.0;
  // Carousel and catalog slivers still use a fixed row height. Font metrics
  // run a few pixels past the line estimate; this keeps that cell from
  // clipping the discount. The inline grid sizes each card to its content.
  const safetyDp = 12.0;

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

bool _gridItemsHaveVendor(List<dynamic> items) {
  for (final raw in items) {
    if (raw is! Map) continue;
    if ((raw['vendor'] ?? '').toString().trim().isNotEmpty) return true;
  }
  return false;
}

bool _gridItemsHaveSwatches(List<dynamic> items) {
  for (final raw in items) {
    if (raw is! Map) continue;
    final swatches = raw['swatches'];
    if (swatches is List && swatches.isNotEmpty) return true;
  }
  return false;
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

String _themeCtaText(Map<String, dynamic> pb, String key, String fallback) {
  final value = productBlockSetting(pb, key, '').trim();
  return value.isEmpty ? fallback : value;
}

String _addToCartTitle(WidgetNode node) {
  final a = node.s('addToCartButtonTitle', def: '').trim();
  if (a.isNotEmpty) return a;
  return node.s('addToCartLabel', def: 'Add to cart');
}
