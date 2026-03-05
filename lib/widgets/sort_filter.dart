import 'package:flutter/material.dart';
import '../theme_library.dart';
import '../utils/color.dart';

/// Sort & Filter bar for PLP.
/// Props: enabled, sortLabel, sortOptions, defaultSortIndex, filterLabel, showFilterButton,
/// labelColor, optionTextColor, borderColor, backgroundColor, filterButtonColor, filterButtonFontColor, borderRadius.
/// Dispatches { "type": "sort", "value": "...", "index": n } on sort change;
/// { "type": "open_filter" } on filter tap.
Widget buildSortFilter(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final r = env.r;
  final sortLabel = node.s('sortLabel', def: 'Sort by');
  final optionsRaw = node.l('sortOptions');
  final sortOptions = optionsRaw != null
      ? optionsRaw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
      : _defaultSortOptions;
  final defaultSortIndex = node.i('defaultSortIndex', def: 0).clamp(0, sortOptions.length > 0 ? sortOptions.length - 1 : 0);
  final filterLabel = node.s('filterLabel', def: 'Filter');
  final showFilterButton = node.b('showFilterButton', def: true);

  final labelColor = parseHexColor(node.s('labelColor', def: '#111827')) ?? const Color(0xFF111827);
  final optionTextColor = parseHexColor(node.s('optionTextColor', def: '#374151')) ?? const Color(0xFF374151);
  final borderColor = parseHexColor(node.s('borderColor', def: '#E5E7EB')) ?? const Color(0xFFE5E7EB);
  final backgroundColor = parseHexColor(node.s('backgroundColor', def: '#FFFFFF')) ?? Colors.white;
  final filterButtonColor = parseHexColor(node.s('filterButtonColor', def: '#111827')) ?? const Color(0xFF111827);
  final filterButtonFontColor = parseHexColor(node.s('filterButtonFontColor', def: '#FFFFFF')) ?? Colors.white;
  final borderRadius = node.d('borderRadius', def: 8).clamp(0, 24).toDouble();

  return _SortFilterWidget(
    sortLabel: sortLabel,
    sortOptions: sortOptions,
    defaultSortIndex: defaultSortIndex,
    filterLabel: filterLabel,
    showFilterButton: showFilterButton,
    labelColor: labelColor,
    optionTextColor: optionTextColor,
    borderColor: borderColor,
    backgroundColor: backgroundColor,
    filterButtonColor: filterButtonColor,
    filterButtonFontColor: filterButtonFontColor,
    borderRadiusDp: borderRadius,
    r: r,
    onSortChanged: (index, value) {
      env.dispatchAction(context, {'type': 'sort', 'value': value, 'index': index});
    },
    onFilterTap: () {
      env.dispatchAction(context, {'type': 'open_filter'});
    },
  );
}

const List<String> _defaultSortOptions = [
  'Price: Low to High',
  'Price: High to Low',
  'Newest',
  'Best Selling',
  'A-Z',
  'Z-A',
];

class _SortFilterWidget extends StatefulWidget {
  const _SortFilterWidget({
    required this.sortLabel,
    required this.sortOptions,
    required this.defaultSortIndex,
    required this.filterLabel,
    required this.showFilterButton,
    required this.labelColor,
    required this.optionTextColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.filterButtonColor,
    required this.filterButtonFontColor,
    required this.borderRadiusDp,
    required this.r,
    required this.onSortChanged,
    required this.onFilterTap,
  });

  final String sortLabel;
  final List<String> sortOptions;
  final int defaultSortIndex;
  final String filterLabel;
  final bool showFilterButton;
  final Color labelColor;
  final Color optionTextColor;
  final Color borderColor;
  final Color backgroundColor;
  final Color filterButtonColor;
  final Color filterButtonFontColor;
  final double borderRadiusDp;
  final R r;
  final void Function(int index, String value) onSortChanged;
  final VoidCallback onFilterTap;

  @override
  State<_SortFilterWidget> createState() => _SortFilterWidgetState();
}

class _SortFilterWidgetState extends State<_SortFilterWidget> {
  late int _selectedSortIndex;

  @override
  void initState() {
    super.initState();
    _selectedSortIndex = widget.defaultSortIndex.clamp(0, widget.sortOptions.length - 1);
  }

  @override
  void didUpdateWidget(covariant _SortFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedSortIndex = widget.defaultSortIndex.clamp(0, widget.sortOptions.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sortOptions.isEmpty) return const SizedBox.shrink();

    final radius = widget.r.dp(widget.borderRadiusDp);
    final padH = widget.r.dp(16);
    final padV = widget.r.dp(12);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          // Sort dropdown
          Expanded(
            child: Row(
              children: [
                Text(
                  widget.sortLabel.isEmpty ? 'Sort by' : widget.sortLabel,
                  style: TextStyle(
                    color: widget.labelColor,
                    fontSize: widget.r.sp(14, min: 12, max: 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: widget.r.dp(8)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: widget.r.dp(10), vertical: widget.r.dp(4)),
                    constraints: BoxConstraints(minHeight: widget.r.dp(32), maxHeight: widget.r.dp(40)),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(widget.r.dp(6)),
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedSortIndex.clamp(0, widget.sortOptions.length - 1),
                        isExpanded: true,
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: widget.optionTextColor, size: widget.r.dp(18)),
                        style: TextStyle(color: widget.optionTextColor, fontSize: widget.r.sp(14, min: 12, max: 16)),
                        items: List.generate(
                          widget.sortOptions.length,
                          (i) => DropdownMenuItem(value: i, child: Text(widget.sortOptions[i], overflow: TextOverflow.ellipsis)),
                        ),
                        onChanged: (i) {
                          if (i == null) return;
                          setState(() => _selectedSortIndex = i);
                          widget.onSortChanged(i, widget.sortOptions[i]);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showFilterButton) ...[
            SizedBox(width: widget.r.dp(10)),
            Material(
              color: widget.filterButtonColor,
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                onTap: widget.onFilterTap,
                borderRadius: BorderRadius.circular(radius),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: widget.r.dp(16), vertical: widget.r.dp(10)),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: widget.r.dp(18), color: widget.filterButtonFontColor),
                      SizedBox(width: widget.r.dp(6)),
                      Text(
                        widget.filterLabel.isEmpty ? 'Filter' : widget.filterLabel,
                        style: TextStyle(
                          color: widget.filterButtonFontColor,
                          fontSize: widget.r.sp(14, min: 12, max: 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
