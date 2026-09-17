import 'package:flutter/material.dart';

import '../pdp/pdp_product_scope.dart';
import '../product/product_variant_model.dart';
import '../theme_library.dart';
import '../utils/color.dart';
import 'variant_choice_chips.dart';

/// API-driven variant selector for PDP. Renders Material 3 choice chips from
/// [product]['variants']; selection updates [PdpProductScope] for live pricing.
Widget buildProductVariant(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final product = node.m('product');
  final scope = PdpProductScope.maybeOf(context);
  final variants = scope?.variants ??
      (product != null ? parseProductVariants(product) : const <ProductVariantOption>[]);

  final showOutOfStock = node.b('showOutOfStockVariants', def: true);
  final visibleCount = [
    for (final v in variants)
      if (showOutOfStock || !v.isOutOfStock) v,
  ].length;
  if (visibleCount <= 1) return const SizedBox.shrink();

  final apiGroupLabel = scope?.variantGroupLabel ??
      (product != null ? productVariantGroupLabel(product) : 'Variant');
  final customTitle = () {
    final group = node.s('groupTitle').trim();
    if (group.isNotEmpty) return group;
    final legacy = node.s('title').trim();
    if (legacy.isEmpty) return '';
    final lower = legacy.toLowerCase();
    if (lower == 'product variant' || lower == 'product_variant') return '';
    return legacy;
  }();
  final groupLabel = customTitle.isNotEmpty ? customTitle : apiGroupLabel;
  final selectedIndex = scope?.selectedIndex ?? 0;
  final labelColor = parseHexColor(node.s('labelColor', def: '#111827')) ??
      const Color(0xFF111827);
  final innerTextColor =
      parseHexColor(node.s('innerTextColor', def: '#374151')) ??
          const Color(0xFF374151);
  final borderColor = parseHexColor(node.s('borderColor', def: '#D1D5DB')) ??
      const Color(0xFFD1D5DB);
  final backgroundColor =
      parseHexColor(node.s('backgroundColor', def: '#FFFFFF')) ??
          const Color(0xFFFFFFFF);
  final remainingStockColor =
      parseHexColor(node.s('remainingStockColor', def: '#DC2626')) ??
          const Color(0xFFDC2626);
  final themePrimary = resolveAppDropPrimaryColor(context);
  final selectedBackgroundColor =
      parseHexColor(node.s('selectedBackgroundColor', def: '')) ?? themePrimary;
  final selectedForegroundColor =
      parseHexColor(node.s('selectedForegroundColor', def: '')) ??
          resolveAppDropOnPrimaryColor(selectedBackgroundColor);
  final cornerRadiusDp = node.d('cornerRadius', def: 24).clamp(0, 24).toDouble();
  final showRemainingStock = node.b('showRemainingStock', def: true);
  final remainingThreshold =
      node.i('remainingStockThreshold', def: 5).clamp(1, 10).toInt();
  final remainingLabels = [
    for (final v in variants)
      remainingStockCaption(
        v.inventoryQuantity,
        show: showRemainingStock,
        threshold: remainingThreshold,
      ),
  ];
  // Horizontal inset comes from [AppDropRenderer.contentHorizontalPadding] on PDP.
  return VariantChoiceChipWrap(
    groupLabel: groupLabel,
    variantLabels: [for (final v in variants) v.label],
    selectedIndex: selectedIndex,
    labelColor: labelColor,
    primaryColor: selectedBackgroundColor,
    surfaceColor: backgroundColor,
    borderColor: borderColor,
    r: env.r,
    cornerRadiusDp: cornerRadiusDp,
    innerTextColor: innerTextColor,
    remainingLabels: remainingLabels,
    remainingStockColor: remainingStockColor,
    selectedBackgroundColor: selectedBackgroundColor,
    selectedForegroundColor: selectedForegroundColor,
    outOfStockFlags: [for (final v in variants) v.isOutOfStock],
    showOutOfStock: showOutOfStock,
    onSelect: (index) {
      if (index < 0 || index >= variants.length) return;
      if (variants[index].isOutOfStock) return;
      scope?.selectVariant(index);
      final selected = variants[index];
      env.dispatchAction(context, {
        'type': 'select_variant',
        'productId': product?['productId'] ?? product?['id'],
        'variantId': selected.id,
        'value': selected.label,
        'index': index,
      });
    },
  );
}
