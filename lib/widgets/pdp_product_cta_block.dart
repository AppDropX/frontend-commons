import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../theme/appdrop_theme_scope.dart';
import '../theme_library.dart';
import '../utils/appdrop_snackbar.dart';
import '../utils/color.dart';

Color resolvePdpCtaBackgroundColor(
  BuildContext context,
  WidgetNode node, {
  String customKey = 'cta_bg_color_custom',
  String colorKey = 'cta_bg_color',
}) {
  final themeDefault =
      AppDropThemeScope.maybeOf(context)?.appStyling.defaultColor ??
          const Color(0xFFB63E3E);
  if (!node.b(customKey, def: false)) {
    return themeDefault;
  }
  final raw = node.s(colorKey, def: '').trim();
  return parseHexColor(raw) ?? themeDefault;
}

Widget buildPdpProductCtaBlock(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();
  final action = node.m('action');
  final showBuyNow = node.b('show_buy_now', def: false);
  final layout = node.s('button_layout', def: 'row').trim().toLowerCase();
  final column = showBuyNow && layout == 'column';
  final title = node.s('button_title', def: 'Add to Cart').trim();
  final buyNowTitle = node.s('buy_now_title', def: 'Buy Now').trim();
  final scope = PdpProductScope.maybeOf(context);
  final soldOut = _isSoldOut(context, node, action);
  final canTap = env.interactiveFeaturesEnabled && action != null && !soldOut;
  final quantity = scope?.quantity ?? 1;

  void dispatchCart() {
    if (action == null || soldOut || quantity < 1) return;
    final product = _effectiveProduct(context, node, action);
    env.dispatchAction(context, {
      ...action,
      'direct': true,
      'quantity': quantity,
      if (product != null) 'product': product,
    });
    PdpProductScope.maybeOf(context)?.resetQuantity();
  }

  void dispatchBuyNow() {
    if (soldOut || quantity < 1) return;
    final product = _effectiveProduct(context, node, action) ?? <String, dynamic>{};
    final variantId = _checkoutVariantId(product);
    env.dispatchAction(context, {
      'type': 'buy_now',
      'direct': true,
      'quantity': quantity,
      'productId': (product['productId'] ?? product['id'])?.toString(),
      'variantId': variantId,
      'product': product,
    });
  }

  final titleSize = node.d('title_size', def: 13).clamp(12, 24).toDouble();
  final fontWeight = _ctaWeight(node.s('font_variation', def: 'semi_bold'));
  final fontFamily =
      AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';
  final fontSize = env.r.sp(titleSize, min: 11, max: 24);

  final cartButton = _faceFor(
    context,
    node,
    env,
    title: title.isEmpty ? 'Add to Cart' : title,
    shapeKey: 'button_shape',
    typeKey: 'button_type',
    typeDefault: 'filled',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
    colorCustomKey: 'cta_bg_color_custom',
    colorKey: 'cta_bg_color',
    titleColorKey: 'cta_title_color',
    titleColorDefault: '#FFFFFF',
    soldOut: soldOut,
    soldOutPrefix: 'sold_out',
    onTap: canTap ? dispatchCart : null,
  );

  if (!showBuyNow) return cartButton;

  final buyNowButton = _faceFor(
    context,
    node,
    env,
    title: buyNowTitle.isEmpty ? 'Buy Now' : buyNowTitle,
    shapeKey: 'buy_now_shape',
    typeKey: 'buy_now_type',
    typeDefault: 'outlined',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
    colorCustomKey: 'buy_now_bg_color_custom',
    colorKey: 'buy_now_bg_color',
    titleColorKey: 'buy_now_title_color',
    titleColorDefault: '#111827',
    soldOut: soldOut,
    soldOutPrefix: 'buy_now_sold_out',
    onTap: canTap ? dispatchBuyNow : null,
  );

  if (column) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cartButton,
        const SizedBox(height: 8),
        buyNowButton,
      ],
    );
  }

  return Row(
    children: [
      Expanded(child: cartButton),
      const SizedBox(width: 8),
      Expanded(child: buyNowButton),
    ],
  );
}

Widget _faceFor(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env, {
  required String title,
  required String shapeKey,
  required String typeKey,
  required String typeDefault,
  required double fontSize,
  required FontWeight fontWeight,
  required String fontFamily,
  required String colorCustomKey,
  required String colorKey,
  required String titleColorKey,
  required String titleColorDefault,
  required bool soldOut,
  required String soldOutPrefix,
  required VoidCallback? onTap,
}) {
  final shape = node.s(shapeKey, def: 'corner').toLowerCase();
  final liveOutlined =
      node.s(typeKey, def: typeDefault).toLowerCase() == 'outlined';
  final face = soldOut
      ? _soldOutFace(
          node,
          title,
          soldOutPrefix,
          liveOutlined: liveOutlined,
        )
      : _liveFace(
          context,
          node,
          title: title,
          typeKey: typeKey,
          typeDefault: typeDefault,
          colorCustomKey: colorCustomKey,
          colorKey: colorKey,
          titleColorKey: titleColorKey,
          titleColorDefault: titleColorDefault,
        );
  return _CtaFace(
    title: face.title,
    height: env.r.dp(48),
    radius: _radius(shape, env.r),
    background: face.background,
    foreground: face.foreground,
    outlined: face.outlined,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
    onTap: onTap,
    soldOut: soldOut,
  );
}

FontWeight _ctaWeight(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'regular':
      return FontWeight.w400;
    case 'bold':
      return FontWeight.w700;
    case 'semi_bold':
    case 'semibold':
    default:
      return FontWeight.w600;
  }
}

class _FacePaint {
  const _FacePaint({
    required this.title,
    required this.background,
    required this.foreground,
    required this.outlined,
  });

  final String title;
  final Color background;
  final Color foreground;
  final bool outlined;
}

const Color _kDullFill = Color(0xFFE5E7EB);
const Color _kDullInk = Color(0xFF9CA3AF);
const Color _kDullLine = Color(0xFFD1D5DB);

_FacePaint _liveFace(
  BuildContext context,
  WidgetNode node, {
  required String title,
  required String typeKey,
  required String typeDefault,
  required String colorCustomKey,
  required String colorKey,
  required String titleColorKey,
  required String titleColorDefault,
}) {
  final outlined =
      node.s(typeKey, def: typeDefault).toLowerCase() == 'outlined';
  final background = resolvePdpCtaBackgroundColor(
    context,
    node,
    customKey: colorCustomKey,
    colorKey: colorKey,
  );
  final foreground =
      parseHexColor(node.s(titleColorKey, def: titleColorDefault)) ??
          Colors.white;
  return _FacePaint(
    title: title,
    background: background,
    foreground: foreground,
    outlined: outlined,
  );
}

_FacePaint _soldOutFace(
  WidgetNode node,
  String liveTitle,
  String prefix, {
  required bool liveOutlined,
}) {
  final dull = node.b('${prefix}_dull', def: true);
  if (dull) {
    return _FacePaint(
      title: liveTitle,
      background: liveOutlined ? _kDullLine : _kDullFill,
      foreground: _kDullInk,
      outlined: liveOutlined,
    );
  }
  final typeDefault = prefix.contains('buy_now') ? 'outlined' : 'filled';
  final outlined =
      node.s('${prefix}_type', def: typeDefault).toLowerCase() == 'outlined';
  final customTitle = node.s('${prefix}_title', def: 'Sold Out').trim();
  final background =
      parseHexColor(node.s('${prefix}_bg_color', def: '#9CA3AF')) ??
          const Color(0xFF9CA3AF);
  final foreground =
      parseHexColor(node.s('${prefix}_title_color', def: '#FFFFFF')) ??
          Colors.white;
  return _FacePaint(
    title: customTitle.isEmpty ? 'Sold Out' : customTitle,
    background: background,
    foreground: foreground,
    outlined: outlined,
  );
}

bool _isSoldOut(
  BuildContext context,
  WidgetNode node,
  Map<String, dynamic>? action,
) {
  final scope = PdpProductScope.maybeOf(context);
  final product = scope?.product ??
      _effectiveProduct(context, node, action) ??
      <String, dynamic>{};
  return pdpSelectionIsSoldOut(
    product: product,
    variant: scope?.selectedVariant,
  );
}

Map<String, dynamic>? _effectiveProduct(
  BuildContext context,
  WidgetNode node,
  Map<String, dynamic>? action,
) {
  final fromScope = PdpProductScope.maybeOf(context)?.effectiveProduct;
  if (fromScope != null) return Map<String, dynamic>.from(fromScope);
  final fromAction = action?['product'];
  if (fromAction is Map) return Map<String, dynamic>.from(fromAction);
  return node.m('product');
}

String _checkoutVariantId(Map<String, dynamic> product) {
  final selected = selectedVariantIdFromProductMap(product);
  if (selected.isNotEmpty) return selected;
  String? fallback;
  for (final variant in parseProductVariants(product)) {
    if (variant.id.isEmpty) continue;
    fallback ??= variant.id;
    if (!variant.isOutOfStock) return variant.id;
  }
  return fallback ?? '';
}

class _CtaFace extends StatelessWidget {
  const _CtaFace({
    required this.title,
    required this.height,
    required this.radius,
    required this.background,
    required this.foreground,
    required this.outlined,
    required this.fontSize,
    required this.fontWeight,
    required this.fontFamily,
    required this.onTap,
    required this.soldOut,
  });

  final String title;
  final double height;
  final double radius;
  final Color background;
  final Color foreground;
  final bool outlined;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final VoidCallback? onTap;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final face = Ink(
      height: height,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: background, width: outlined ? 1.2 : 1),
      ),
      child: Center(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppDropThemeData.textStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: outlined ? background : foreground,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: soldOut
              ? () => showProductSoldOutSnackBar(context)
              : onTap,
          child: face,
        ),
      ),
    );
  }
}

double _radius(String shape, dynamic r) {
  switch (shape) {
    case 'rounded':
      return r.dp(8);
    case 'blunt':
      return r.dp(999);
    case 'corner':
    default:
      return 0;
  }
}
