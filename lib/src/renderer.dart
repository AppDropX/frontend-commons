import 'package:flutter/widgets.dart';
import 'responsive.dart';
import 'widget_node.dart';
import 'registry.dart';

class AppDropRenderer extends StatelessWidget {
  final List<WidgetNode> nodes;
  final WidgetRegistry? registry;
  final double baseWidth;
  final AppDropActionHandler? onAction;

  const AppDropRenderer({
    super.key,
    required this.nodes,
    this.registry,
    this.baseWidth = 390,
    this.onAction,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final n in nodes) renderNode(context, n)],
        );
      },
    );
  }
}
