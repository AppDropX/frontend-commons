import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/color.dart';

/// Search-page collection chips: "POPULAR CHOICES" heading + wrapping pills.
///
/// Tapping a chip dispatches `{type: open_collection, collection: <id>}`.
Widget buildPopularChoices(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final cfg = AppDropThemeScope.maybeOf(context);
  final content = cfg?.appStyling.fontIconColor ?? const Color(0xFF4A5A3C);

  final heading = node.s('heading', def: 'POPULAR CHOICES').trim();
  final headingColor =
      parseHexColor(node.s('headingColor', def: '')) ?? content;
  final chipColor = parseHexColor(node.s('chipColor', def: '')) ?? content;

  final chipSize = node.d('chipSize', def: 9).clamp(8, 14).toDouble();
  final items = _itemsFromNode(node);
  if (items.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: EdgeInsets.fromLTRB(r.dp(8), r.dp(8), r.dp(8), r.dp(4)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              FluentIcons.arrow_trending_20_regular,
              size: r.dp(14),
              color: headingColor,
            ),
            SizedBox(width: r.dp(6)),
            Expanded(
              child: Text(
                heading.isEmpty ? 'POPULAR CHOICES' : heading.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: headingColor,
                  fontSize: r.sp(11, min: 10, max: 12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: r.dp(8)),
        Wrap(
          spacing: r.dp(6),
          runSpacing: r.dp(6),
          children: [
            for (final item in items)
              _PopularChoiceChip(
                title: item.title,
                color: chipColor,
                size: chipSize,
                r: r,
                onTap: item.id.isEmpty
                    ? null
                    : () => env.dispatchAction(context, {
                          'type': 'open_collection',
                          'collection': item.id,
                        }),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ChoiceItem {
  const _ChoiceItem({required this.id, required this.title});
  final String id;
  final String title;
}

List<_ChoiceItem> _itemsFromNode(WidgetNode node) {
  final raw = node.l('items');
  if (raw == null || raw.isEmpty) return const [];
  final out = <_ChoiceItem>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final map = Map<String, dynamic>.from(e);
    final title = (map['title'] ?? map['name'] ?? '').toString().trim();
    if (title.isEmpty) continue;
    final id = (map['id'] ?? map['collection'] ?? title).toString().trim();
    out.add(_ChoiceItem(id: id, title: title));
  }
  return out;
}

class _PopularChoiceChip extends StatelessWidget {
  const _PopularChoiceChip({
    required this.title,
    required this.color,
    required this.size,
    required this.r,
    this.onTap,
  });

  final String title;
  final Color color;
  final double size;
  final R r;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = r.sp(size, min: 8, max: 13);
    final iconSize = r.dp((size - 1).clamp(8, 12));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.dp(8 + (size - 8) * 0.4),
            vertical: r.dp(4 + (size - 8) * 0.2),
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                  height: 1.1,
                ),
              ),
              SizedBox(width: r.dp(4)),
              Icon(
                FluentIcons.arrow_up_right_16_regular,
                size: iconSize,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
