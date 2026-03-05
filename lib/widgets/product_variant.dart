import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// Product variant selector for PDP (e.g. Size, Color).
/// Props: enabled, variantLabel, variantType (text|color), options (list of strings;
/// for color, hex values), selectedIndex, labelColor, optionTextColor, selectedBorderColor,
/// optionBackgroundColor.
/// Dispatches { "type": "select_variant", "variantLabel": "...", "value": "...", "index": n } on tap.
Widget buildProductVariant(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final variantLabel = node.s('variantLabel', def: 'Size');
  final variantType = node.s('variantType', def: 'text').toLowerCase();
  final isColor = variantType == 'color';
  final optionsRaw = node.l('options');
  final options = optionsRaw != null
      ? optionsRaw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
      : (isColor ? ['#111827', '#9CA3AF', '#F97316'] : ['S', 'M', 'L']);
  final selectedIndex = node.i('selectedIndex', def: 0).clamp(0, options.length > 0 ? options.length - 1 : 0);
  final labelColor = parseHexColor(node.s('labelColor', def: '#111827')) ?? const Color(0xFF111827);
  final optionTextColor = parseHexColor(node.s('optionTextColor', def: '#374151')) ?? const Color(0xFF374151);
  final selectedBorderColor = parseHexColor(node.s('selectedBorderColor', def: '#111827')) ?? const Color(0xFF111827);
  final optionBackgroundColor = parseHexColor(node.s('optionBackgroundColor', def: '#F3F4F6')) ?? const Color(0xFFF3F4F6);

  if (options.isEmpty) return const SizedBox.shrink();

  return _ProductVariantWidget(
    variantLabel: variantLabel,
    isColorType: isColor,
    options: options,
    selectedIndex: selectedIndex,
    labelColor: labelColor,
    optionTextColor: optionTextColor,
    selectedBorderColor: selectedBorderColor,
    optionBackgroundColor: optionBackgroundColor,
    r: r,
    onSelect: (index, value) {
      env.dispatchAction(context, {
        'type': 'select_variant',
        'variantLabel': variantLabel,
        'value': value,
        'index': index,
      });
    },
  );
}

class _ProductVariantWidget extends StatefulWidget {
  const _ProductVariantWidget({
    required this.variantLabel,
    required this.isColorType,
    required this.options,
    required this.selectedIndex,
    required this.labelColor,
    required this.optionTextColor,
    required this.selectedBorderColor,
    required this.optionBackgroundColor,
    required this.r,
    required this.onSelect,
  });

  final String variantLabel;
  final bool isColorType;
  final List<String> options;
  final int selectedIndex;
  final Color labelColor;
  final Color optionTextColor;
  final Color selectedBorderColor;
  final Color optionBackgroundColor;
  final R r;
  final void Function(int index, String value) onSelect;

  @override
  State<_ProductVariantWidget> createState() => _ProductVariantWidgetState();
}

class _ProductVariantWidgetState extends State<_ProductVariantWidget> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex.clamp(0, widget.options.length - 1);
  }

  @override
  void didUpdateWidget(covariant _ProductVariantWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedIndex = widget.selectedIndex.clamp(0, widget.options.length - 1);
  }

  void _select(int index) {
    if (index < 0 || index >= widget.options.length) return;
    setState(() => _selectedIndex = index);
    widget.onSelect(index, widget.options[index]);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: widget.labelColor,
      fontSize: widget.r.sp(14, min: 12, max: 16),
      fontWeight: FontWeight.w600,
    );
    final optionTextStyle = TextStyle(
      color: widget.optionTextColor,
      fontSize: widget.r.sp(14, min: 12, max: 16),
      fontWeight: FontWeight.w500,
    );
    final pad = widget.r.dp(16);
    final spacing = widget.r.dp(10);
    final chipPadding = EdgeInsets.symmetric(horizontal: widget.r.dp(14), vertical: widget.r.dp(10));
    final borderWidth = 2.0;
    final swatchSize = widget.r.dp(36);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: widget.r.dp(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: widget.r.dp(8)),
            child: Text(widget.variantLabel.isEmpty ? 'Variant' : widget.variantLabel, style: labelStyle),
          ),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(widget.options.length, (i) {
              final value = widget.options[i];
              final isSelected = i == _selectedIndex;
              if (widget.isColorType) {
                final color = parseHexColor(value) ?? const Color(0xFF9CA3AF);
                return GestureDetector(
                  onTap: () => _select(i),
                  child: Container(
                    width: swatchSize,
                    height: swatchSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? widget.selectedBorderColor : Colors.grey.shade400,
                        width: isSelected ? borderWidth : 1,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: widget.selectedBorderColor.withValues(alpha: 0.3), blurRadius: 4)] : null,
                    ),
                  ),
                );
              }
              return GestureDetector(
                onTap: () => _select(i),
                child: Container(
                  padding: chipPadding,
                  decoration: BoxDecoration(
                    color: widget.optionBackgroundColor,
                    borderRadius: BorderRadius.circular(widget.r.dp(8)),
                    border: Border.all(
                      color: isSelected ? widget.selectedBorderColor : Colors.grey.shade300,
                      width: isSelected ? borderWidth : 1,
                    ),
                  ),
                  child: Text(value, style: optionTextStyle),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
