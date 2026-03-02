import 'package:flutter/widgets.dart';
import 'responsive.dart';
import 'widget_node.dart';
import 'registry.dart';

/// Default vertical space between blocks when rendered in a column.
const double kDefaultBlockSpacing = 12.0;

class AppDropRenderer extends StatelessWidget {
  final List<WidgetNode> nodes;
  final WidgetRegistry? registry;
  final double baseWidth;
  final AppDropActionHandler? onAction;
  /// Vertical space between each block. Default is [kDefaultBlockSpacing].
  final double blockSpacing;

  const AppDropRenderer({
    super.key,
    required this.nodes,
    this.registry,
    this.baseWidth = 320,
    this.onAction,
    this.blockSpacing = kDefaultBlockSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final reg = registry ?? WidgetRegistry.defaults();

    return LayoutBuilder(
      builder: (context, c) {
        final rr = R.fromConstraints(context, c, baseWidth: baseWidth);

        Widget renderNode(BuildContext ctx, WidgetNode node) {
          final builder = reg.builderFor(node.type);
          final env = AppDropBuildEnv(
            r: rr,
            renderNode: (ctx2, n2) => renderNode(ctx2 as BuildContext, n2),
            onAction: onAction,
          );
          if (builder == null) return const SizedBox.shrink();
          return builder(ctx, node, env);
        }

        final children = <Widget>[];
        for (var i = 0; i < nodes.length; i++) {
          if (i > 0 && blockSpacing > 0) {
            children.add(SizedBox(height: blockSpacing));
          }
          children.add(renderNode(context, nodes[i]));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}
