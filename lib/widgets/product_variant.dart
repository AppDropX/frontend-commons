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

  if (variants.length <= 1) return const SizedBox.shrink();

  final groupLabel = scope?.variantGroupLabel ??
      (product != null ? productVariantGroupLabel(product) : 'Variant');
  final selectedIndex = scope?.selectedIndex ?? 0;
  final labelColor = parseHexColor(node.s('labelColor', def: '#111827')) ??
      const Color(0xFF111827);
  final primaryColor = resolveAppDropPrimaryColor(context);
  final surfaceColor = Theme.of(context).colorScheme.surface;
  final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.35);

  // Horizontal inset comes from [AppDropRenderer.contentHorizontalPadding] on PDP.
  return VariantChoiceChipWrap(
      groupLabel: groupLabel,
      variantLabels: [for (final v in variants) v.label],
      selectedIndex: selectedIndex,
      labelColor: labelColor,
      primaryColor: primaryColor,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      r: env.r,
      onSelect: (index) {
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
