import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../theme/appdrop_theme_scope.dart';

Widget buildProductGrid(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final itemsRaw = node.l('items') ?? const [];
  if (itemsRaw.isEmpty) return const SizedBox.shrink();

  final spacingDp = node.d('spacingDp', def: 12);
  final maxTileDp = node.d('maxTileWidthDp', def: 190);

  return LayoutBuilder(
    builder: (ctx, constraints) {
      final spacing = env.r.dp(spacingDp);
      final maxTileW = env.r.dp(maxTileDp);

      final width = constraints.maxWidth;
      final cols = (width / maxTileW).floor().clamp(2, 3);

      final tileW = (width - spacing * (cols - 1)) / cols;

      // read current product_block defaults from scope
      final scope = AppDropThemeScope.maybeOf(ctx);
      final pb = scope?.productBlock ?? const <String, dynamic>{};

      final padDp = _d(pb, 'card_padding', 12);
      final maxLines = _i(pb, 'max_lines', 2);

      final showVendor = _b(pb, 'show_vendor', true);
      final showRating = _b(pb, 'show_rating', true);
      final showSwatches = _b(pb, 'show_swatches', true);

      final aspectIdx = _i(pb, 'image_aspect_ratio_index', 0);
      final aspect = _aspectFromIndex(aspectIdx);

      final imageH = tileW / aspect; // ✅ image height derived from aspect
      final metaH = _estimateMetaHeight(env, padDp, maxLines, showVendor, showRating, showSwatches);

      final tileH = imageH + metaH + env.r.dp(2); // ✅ small buffer

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemsRaw.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: tileH, // ✅ IMPORTANT
        ),
        itemBuilder: (c, i) {
          final item = Map<String, dynamic>.from(itemsRaw[i] as Map);

          final block = WidgetNode(
            type: 'product_block',
            props: {
              'product': item,
              if (item['action'] != null) 'action': item['action'],
            },
          );

          return env.renderNode(c, block) as Widget;
        },
      );
    },
  );
}

double _estimateMetaHeight(AppDropBuildEnv env, double padDp, int maxLines, bool showVendor, bool showRating, bool showSwatches) {
  double h = env.r.dp(padDp * 2); // vertical padding

  if (showVendor) {
    h += env.r.dp(6);
    h += env.r.dp(14);
  }

  final lines = maxLines <= 0 ? 2 : maxLines;
  h += env.r.dp(18) * lines;

  h += env.r.dp(10);

  if (showRating) h += env.r.dp(26);

  h += env.r.dp(20); // price row

  if (showSwatches) {
    h += env.r.dp(12);
    h += env.r.dp(18);
  }

  h += env.r.dp(6); // buffer
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

// ✅ 4 buttons mapping
double _aspectFromIndex(int idx) {
  switch (idx) {
    case 0: return 1.0; // Smart
    case 1: return 1.0; // Square
    case 2: return 4 / 5; // Portrait
    case 3: return 16 / 9; // Landscape
    default: return 1.0;
  }
}
