import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// Product description accordion block.
/// Props: enabled, defaultAccordionState (expanded|collapsed), title, description,
/// titleColor, descriptionColor.
Widget buildProductDescription(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final defaultExpanded = node.s('defaultAccordionState', def: 'expanded').toLowerCase() == 'expanded';
  final title = node.s('title', def: 'Product Description');
  final description = node.s('description', def: '');
  final titleColor = parseHexColor(node.s('titleColor', def: '#111827')) ?? const Color(0xFF111827);
  final descriptionColor = parseHexColor(node.s('descriptionColor', def: '#6B7280')) ?? const Color(0xFF6B7280);

  return _ProductDescriptionWidget(
    initiallyExpanded: defaultExpanded,
    title: title,
    description: description,
    titleColor: titleColor,
    descriptionColor: descriptionColor,
    r: r,
  );
}

class _ProductDescriptionWidget extends StatefulWidget {
  const _ProductDescriptionWidget({
    required this.initiallyExpanded,
    required this.title,
    required this.description,
    required this.titleColor,
    required this.descriptionColor,
    required this.r,
  });

  final bool initiallyExpanded;
  final String title;
  final String description;
  final Color titleColor;
  final Color descriptionColor;
  final R r;

  @override
  State<_ProductDescriptionWidget> createState() => _ProductDescriptionWidgetState();
}

class _ProductDescriptionWidgetState extends State<_ProductDescriptionWidget> {
  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: widget.titleColor,
      fontSize: widget.r.sp(16, min: 14, max: 20),
      fontWeight: FontWeight.w600,
    );
    final descriptionStyle = TextStyle(
      color: widget.descriptionColor,
      fontSize: widget.r.sp(14, min: 12, max: 18),
      height: 1.45,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          tilePadding: EdgeInsets.symmetric(
            horizontal: widget.r.dp(16),
            vertical: widget.r.dp(12),
          ),
          childrenPadding: EdgeInsets.only(
            left: widget.r.dp(16),
            right: widget.r.dp(16),
            bottom: widget.r.dp(16),
          ),
          title: Text(
            widget.title.isEmpty ? 'Product Description' : widget.title,
            style: titleStyle,
          ),
          controlAffinity: ListTileControlAffinity.trailing,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.description.isEmpty
                    ? 'Add product details here.'
                    : widget.description,
                style: descriptionStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
