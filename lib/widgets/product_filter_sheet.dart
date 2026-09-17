import 'package:flutter/material.dart';

import '../product/product_catalog_query.dart';
import '../src/responsive.dart';
import '../theme/appdrop_theme_scope.dart';
import 'product_price_row.dart';
import 'variant_choice_chips.dart';

/// Opens the PLP filter sheet and returns the applied selection, or null if dismissed.
Future<ProductFilterSelection?> showProductFilterSheet({
  required BuildContext context,
  required Future<ProductFilterFacets> Function() loadFacets,
  ProductFilterSelection initial = const ProductFilterSelection(),
}) {
  final themeConfig = AppDropThemeScope.maybeOf(context);
  return showModalBottomSheet<ProductFilterSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      Widget sheet = _ProductFilterSheet(
        loadFacets: loadFacets,
        initial: initial,
      );
      if (themeConfig != null) {
        sheet = AppDropThemeScope(config: themeConfig, child: sheet);
      }
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: sheet,
      );
    },
  );
}

class _ProductFilterSheet extends StatefulWidget {
  const _ProductFilterSheet({
    required this.loadFacets,
    required this.initial,
  });

  final Future<ProductFilterFacets> Function() loadFacets;
  final ProductFilterSelection initial;

  @override
  State<_ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<_ProductFilterSheet> {
  ProductFilterFacets? _facets;
  Object? _error;
  bool _loading = true;

  RangeValues? _price;
  final Map<String, Set<String>> _selected = {};

  @override
  void initState() {
    super.initState();
    for (final entry in widget.initial.options.entries) {
      _selected[entry.key] = entry.value.toSet();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final facets = await widget.loadFacets();
      if (!mounted) return;
      _facets = facets;
      _price = _initialPrice(facets);
      _loading = false;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  RangeValues? _initialPrice(ProductFilterFacets facets) {
    if (!facets.hasPriceRange) return null;
    final min = facets.minPrice!;
    final max = facets.maxPrice!;
    final start = (widget.initial.minPrice ?? min).clamp(min, max);
    final end = (widget.initial.maxPrice ?? max).clamp(min, max);
    return RangeValues(start <= end ? start : min, end >= start ? end : max);
  }

  ProductFilterSelection _selectionFromState() {
    final facets = _facets;
    double? minPrice;
    double? maxPrice;
    final price = _price;
    if (facets != null && facets.hasPriceRange && price != null) {
      final moved = (price.start - facets.minPrice!).abs() > 0.009 ||
          (price.end - facets.maxPrice!).abs() > 0.009;
      if (moved) {
        minPrice = _roundPrice(price.start);
        maxPrice = _roundPrice(price.end);
      }
    }
    final options = <String, List<String>>{
      for (final entry in _selected.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value.toList(),
    };
    return ProductFilterSelection(
      minPrice: minPrice,
      maxPrice: maxPrice,
      options: options,
    );
  }

  void _clear() {
    final facets = _facets;
    setState(() {
      _selected.clear();
      _price = facets != null ? _fullPrice(facets) : null;
    });
  }

  RangeValues? _fullPrice(ProductFilterFacets facets) {
    if (!facets.hasPriceRange) return null;
    return RangeValues(facets.minPrice!, facets.maxPrice!);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = AppDropThemeScope.maybeOf(context);
    final bg = cfg?.appStyling.bgColor ?? Colors.white;
    final text = cfg?.appStyling.fontIconColor ?? const Color(0xFF2C2C2C);
    final primary = resolveAppDropPrimaryColor(context);
    final size = MediaQuery.sizeOf(context);
    final r = R.fromConstraints(context, BoxConstraints.tight(size));
    final priceCfg = ProductPriceDisplayConfig.fromContext(context, r: r);

    return Material(
      color: bg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: text.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'FILTER',
                        style: TextStyle(
                          color: text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _facets == null ? null : _clear,
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        disabledForegroundColor: text.withValues(alpha: 0.32),
                      ),
                      child: const Text('Clear'),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      color: text,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: _body(
                  context,
                  text: text,
                  primary: primary,
                  priceCfg: priceCfg,
                  surface: bg,
                  r: r,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _facets == null
                        ? null
                        : () => Navigator.of(context).pop(_selectionFromState()),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: resolveAppDropOnPrimaryColor(primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required Color text,
    required Color primary,
    required ProductPriceDisplayConfig priceCfg,
    required Color surface,
    required R r,
  }) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load filters.',
              style: TextStyle(color: text, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final facets = _facets;
    if (facets == null || facets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No filters available for this collection.',
          style: TextStyle(color: text.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      children: [
        if (facets.hasPriceRange && _price != null) ...[
          Text(
            'PRICE',
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatPrice(_price!.start, priceCfg)}  –  ${_formatPrice(_price!.end, priceCfg)}',
            style: TextStyle(color: text, fontSize: 14),
          ),
          RangeSlider(
            values: _price!,
            min: facets.minPrice!,
            max: facets.maxPrice!,
            activeColor: primary,
            onChanged: (value) => setState(() => _price = value),
          ),
          const SizedBox(height: 16),
        ],
        for (final option in facets.options) ...[
          Text(
            option.name.toUpperCase(),
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in option.values)
                VariantChoiceChip(
                  label: value,
                  isSelected: _selected[option.name]?.contains(value) == true,
                  primaryColor: primary,
                  surfaceColor: surface,
                  borderColor: text.withValues(alpha: 0.18),
                  r: r,
                  innerTextColor: text,
                  onSelected: () {
                    setState(() {
                      final set = _selected.putIfAbsent(
                        option.name,
                        () => <String>{},
                      );
                      if (set.contains(value)) {
                        set.remove(value);
                      } else {
                        set.add(value);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

double _roundPrice(double value) {
  return (value * 100).round() / 100;
}

String _formatPrice(double value, ProductPriceDisplayConfig cfg) {
  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '${cfg.prefix}$rounded';
}
