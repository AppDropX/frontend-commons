import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/appdrop_snackbar.dart';
import '../utils/color.dart';

Widget buildPdpProductQuantityBlock(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  if (!node.b('enabled', def: true)) return const SizedBox.shrink();
  return _PdpQuantityBlock(node: node, env: env);
}

class _PdpQuantityBlock extends StatefulWidget {
  const _PdpQuantityBlock({required this.node, required this.env});

  final WidgetNode node;
  final AppDropBuildEnv env;

  @override
  State<_PdpQuantityBlock> createState() => _PdpQuantityBlockState();
}

class _PdpQuantityBlockState extends State<_PdpQuantityBlock> {
  int _localQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final env = widget.env;
    final scope = PdpProductScope.maybeOf(context);
    final product = _product(context, node);
    final variant = scope?.selectedVariant;
    final configuredMax = node.i('max_quantity', def: 10).clamp(1, 99);
    final ceiling = pdpQuantityCeiling(
      product: product,
      variant: variant,
      configuredMax: configuredMax,
    );
    scope?.syncCeiling(ceiling);

    final stored = scope?.quantity ?? _localQuantity;
    final shown = ceiling <= 0 ? 0 : stored.clamp(1, ceiling);
    final soldOut = ceiling <= 0;
    final canDecrease = !soldOut && shown > 1;
    final canIncrease = !soldOut && shown < ceiling;

    final outlined = node.s('style', def: 'outlined').toLowerCase() != 'filled';
    final styleColor =
        parseHexColor(node.s('style_color', def: '#111827')) ??
        const Color(0xFF111827);
    final onFill = styleColor.computeLuminance() > 0.55
        ? const Color(0xFF111827)
        : Colors.white;
    final ink = outlined ? styleColor : onFill;
    final fill = outlined ? Colors.white : styleColor;
    final dividerColor = outlined
        ? styleColor
        : onFill.withValues(alpha: 0.45);
    final fontSize = node.d('font_size', def: 16).clamp(12, 24).toDouble();
    final weight = _weight(node.s('font_variation', def: 'semi_bold'));
    final fontFamily =
        AppDropThemeScope.maybeOf(context)?.appStyling.fontFamily ?? 'Poppins';
    final textStyle = AppDropThemeData.textStyle(
      fontFamily: fontFamily,
      fontSize: env.r.sp(fontSize, min: 12, max: 24),
      fontWeight: weight,
      color: ink,
    );

    final showTitle = node.b('show_title', def: true);
    final heading = node.s('heading', def: 'Quantity').trim();
    final titleColor =
        parseHexColor(node.s('heading_color', def: '#111827')) ??
        const Color(0xFF111827);
    final titleSize = node.d('heading_size', def: 14).clamp(12, 24).toDouble();
    final titleWeight = _weight(
      node.s('heading_font_variation', def: 'semi_bold'),
    );

    void setQuantity(int next) {
      if (soldOut) return;
      final clamped = next.clamp(1, ceiling);
      if (clamped == shown) return;
      triggerQuantityChangeHaptic();
      if (scope != null) {
        scope.setQuantity(clamped);
      } else {
        setState(() => _localQuantity = clamped);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle && heading.isNotEmpty) ...[
          Text(
            heading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppDropThemeData.textStyle(
              fontFamily: fontFamily,
              fontSize: env.r.sp(titleSize, min: 12, max: 24),
              fontWeight: titleWeight,
              color: titleColor,
            ),
          ),
          SizedBox(height: env.r.dp(4)),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: env.r.dp(180),
            height: env.r.dp(48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: dividerColor, width: 1),
              ),
              child: Row(
                children: [
                  _cell(
                    label: 'Decrease quantity',
                    text: '−',
                    style: textStyle,
                    enabled: canDecrease,
                    dividerColor: dividerColor,
                    showTrailingDivider: true,
                    onTap: canDecrease ? () => setQuantity(shown - 1) : null,
                  ),
                  _cell(
                    label: 'Quantity $shown',
                    text: '$shown',
                    style: textStyle,
                    enabled: !soldOut,
                    dividerColor: dividerColor,
                    showTrailingDivider: true,
                    onTap: null,
                  ),
                  _cell(
                    label: 'Increase quantity',
                    text: '+',
                    style: textStyle,
                    enabled: canIncrease,
                    dividerColor: dividerColor,
                    showTrailingDivider: false,
                    onTap: canIncrease ? () => setQuantity(shown + 1) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell({
    required String label,
    required String text,
    required TextStyle style,
    required bool enabled,
    required Color dividerColor,
    required bool showTrailingDivider,
    required VoidCallback? onTap,
  }) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        border: showTrailingDivider
            ? Border(right: BorderSide(color: dividerColor, width: 1))
            : null,
      ),
      child: Center(
        child: Text(
          text,
          style: style.copyWith(
            color: enabled
                ? style.color
                : style.color?.withValues(alpha: 0.35),
          ),
        ),
      ),
    );

    return Expanded(
      child: Semantics(
        button: onTap != null,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _product(BuildContext context, WidgetNode node) {
  final scope = PdpProductScope.maybeOf(context);
  if (scope != null) return scope.product;
  final fromNode = node.m('product');
  if (fromNode == null) return <String, dynamic>{};
  return Map<String, dynamic>.from(fromNode);
}

FontWeight _weight(String raw) {
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
