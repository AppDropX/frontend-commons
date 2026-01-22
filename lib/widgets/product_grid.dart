import 'package:flutter/widgets.dart';
import '../theme_library.dart';

Widget buildProductGrid(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final itemsRaw = node.l('items') ?? const [];
  if (itemsRaw.isEmpty) return const SizedBox.shrink();

  final spacing = node.d('spacingDp', def: 12);
  final maxTile = node.d('maxTileWidthDp', def: 190);

  final cols = (env.r.w / env.r.dp(maxTile)).floor().clamp(2, 3);

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemsRaw.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: env.r.dp(spacing),
      mainAxisSpacing: env.r.dp(spacing),
      childAspectRatio: 0.70,
    ),
    itemBuilder: (ctx, i) {
      final item = Map<String, dynamic>.from(itemsRaw[i] as Map);

      // Build a product_block node for each item (global defaults apply inside)
      final block = WidgetNode(
        type: 'product_block',
        props: {
          'product': item,
          if (item['action'] != null) 'action': item['action'],
        },
      );

      return env.renderNode(ctx, block) as Widget;
    },
  );
}
