import 'dart:async';
import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../search/product_search_entry.dart';
import '../search/search_bar_style.dart';
import '../theme/appdrop_theme_scope.dart';
import 'product_hero_image.dart';
import 'product_image_placeholder.dart';
import 'product_price_row.dart';

/// Shared search field used by pilot, preview, and builder mobile preview.
class AppDropSearchField extends StatefulWidget {
  const AppDropSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onBack,
    this.autofocus = true,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.style = AppDropSearchBarStyle.defaults,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onClear;

  /// When set, a back control is shown to the left of the field (toolbar off).
  final VoidCallback? onBack;
  final bool autofocus;
  final EdgeInsets padding;
  final AppDropSearchBarStyle style;

  static const Color _inputText = Color(0xFF111827);

  @override
  State<AppDropSearchField> createState() => _AppDropSearchFieldState();
}

enum _HintPhase { typing, holding, deleting, gap }

class _AppDropSearchFieldState extends State<AppDropSearchField> {
  static const _typeMs = Duration(milliseconds: 55);
  static const _deleteMs = Duration(milliseconds: 28);
  static const _holdMs = Duration(milliseconds: 1400);
  static const _gapMs = Duration(milliseconds: 400);

  Timer? _typewriter;
  int _hintIndex = 0;
  int _charCount = 0;
  _HintPhase _phase = _HintPhase.typing;

  List<String> get _hints => widget.style.rotatingHints;

  bool get _animate => _hints.length > 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onQueryTick);
    _startTypewriter();
  }

  @override
  void didUpdateWidget(covariant AppDropSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onQueryTick);
      widget.controller.addListener(_onQueryTick);
    }
    if (!_sameHints(oldWidget.style.rotatingHints, _hints)) {
      _hintIndex = 0;
      _charCount = 0;
      _phase = _HintPhase.typing;
      _startTypewriter(force: true);
    } else if (oldWidget.style.usesTypewriter != widget.style.usesTypewriter) {
      _startTypewriter(force: true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQueryTick);
    _typewriter?.cancel();
    super.dispose();
  }

  void _onQueryTick() {
    if (!_animate) return;
    if (widget.controller.text.isEmpty) {
      _startTypewriter();
    } else {
      _typewriter?.cancel();
      _typewriter = null;
    }
  }

  void _startTypewriter({bool force = false}) {
    if (!_animate || widget.controller.text.isNotEmpty) {
      _typewriter?.cancel();
      _typewriter = null;
      return;
    }
    if (!force && _typewriter != null) return;
    _scheduleNext(_typeMs);
  }

  void _scheduleNext(Duration delay) {
    _typewriter?.cancel();
    _typewriter = Timer(delay, _tickTypewriter);
  }

  void _tickTypewriter() {
    if (!mounted || !_animate || widget.controller.text.isNotEmpty) return;
    final hints = _hints;
    if (hints.isEmpty) return;
    final current = hints[_hintIndex % hints.length];
    var delay = _typeMs;
    setState(() {
      if (_phase == _HintPhase.typing) {
        if (_charCount < current.length) {
          _charCount += 1;
          delay = _typeMs;
        } else {
          _phase = _HintPhase.holding;
          delay = _holdMs;
        }
      } else if (_phase == _HintPhase.holding) {
        _phase = _HintPhase.deleting;
        delay = _deleteMs;
      } else if (_phase == _HintPhase.deleting) {
        if (_charCount > 0) {
          _charCount -= 1;
          delay = _deleteMs;
        } else {
          _phase = _HintPhase.gap;
          delay = _gapMs;
        }
      } else {
        _hintIndex = (_hintIndex + 1) % hints.length;
        _phase = _HintPhase.typing;
        delay = _typeMs;
      }
    });

    if (!mounted || widget.controller.text.isNotEmpty) return;
    _scheduleNext(delay);
  }

  String _hintText() {
    final hints = _hints;
    if (hints.isEmpty) return kSearchBarDefaultHint;
    if (!_animate) return hints.first;
    final current = hints[_hintIndex % hints.length];
    if (current.isEmpty) return '';
    final end = _charCount.clamp(0, current.length);
    return current.substring(0, end);
  }

  static bool _sameHints(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cfg = AppDropThemeScope.maybeOf(context);
    final accent = cfg?.appStyling.defaultColor ??
        Theme.of(context).colorScheme.primary;
    final style = widget.style;
    final radius = BorderRadius.circular(style.cornerRadius);
    final restingBorder = BorderSide(color: style.borderColor);
    final hintColor = style.hintTextColor;

    return Padding(
      padding: widget.onBack == null
          ? widget.padding
          : widget.padding.copyWith(left: 4),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) {
          final field = TextField(
            controller: widget.controller,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            keyboardAppearance: Brightness.light,
            cursorColor: accent,
            onSubmitted:
                widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
            style: const TextStyle(
              color: AppDropSearchField._inputText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
            decoration: InputDecoration(
              hintText: _hintText(),
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: style.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: restingBorder,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: restingBorder,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
              suffixIcon: SizedBox(
                width: 48,
                height: 48,
                child: value.text.isEmpty
                    ? Icon(
                        FluentIcons.search_20_regular,
                        size: 20,
                        color: hintColor,
                      )
                    : IconButton(
                        icon: Icon(
                          FluentIcons.dismiss_circle_20_regular,
                          size: 20,
                          color: hintColor,
                        ),
                        tooltip: 'Clear search',
                        onPressed: widget.onClear,
                      ),
              ),
            ),
          );
          if (widget.onBack == null) return field;
          final iconColor =
              cfg?.appStyling.fontIconColor ?? const Color(0xFF111827);
          return Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  onPressed: widget.onBack,
                  icon: Icon(
                    FluentIcons.arrow_left_20_regular,
                    size: 22,
                    color: iconColor,
                  ),
                ),
              ),
              Expanded(child: field),
            ],
          );
        },
      ),
    );
  }
}

/// Idle, loading, empty, and error states for search.
class AppDropSearchMessage extends StatelessWidget {
  const AppDropSearchMessage({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

/// One search result row — image, title, price.
class AppDropSearchResultTile extends StatelessWidget {
  const AppDropSearchResultTile({
    super.key,
    required this.entry,
    this.heroTag,
    required this.onTap,
  });

  final ProductSearchEntry entry;

  /// Omit or pass empty to skip hero animation — search taps feel snappier.
  final String? heroTag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? '';
    final useHero = tag.isNotEmpty && entry.id.isNotEmpty;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: entry.id.isEmpty || entry.thumbnailUrl.isEmpty
                        ? const ProductImagePlaceholder(
                            backgroundColor: Color(0xFFE5E7EB),
                          )
                        : buildProductHeroImage(
                            productId: entry.id,
                            imageUrl: entry.thumbnailUrl,
                            aspectRatio: 1,
                            boxFit: BoxFit.cover,
                            imageBg: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(10),
                            heroTag: useHero ? tag : null,
                            enableHero: useHero,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title.isEmpty ? 'Product' : entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ProductPriceRow(
                        sellingPrice: entry.price,
                        retailPrice: entry.retailPrice,
                        discountPercent: entry.discountPercent,
                        layout: ProductPriceRowLayout.wrap,
                      ),
                    ],
                  ),
                ),
                Icon(
                  FluentIcons.chevron_right_20_regular,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-of-list loading strip for paginated search.
class AppDropSearchListFooter extends StatelessWidget {
  const AppDropSearchListFooter({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.showEndMarker = false,
  });

  final bool isLoading;
  final Object? error;
  final VoidCallback? onRetry;
  final bool showEndMarker;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Could not load more results.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (showEndMarker) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'End of results',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

/// Scroll trigger distance before requesting the next search page.
bool appDropSearchShouldLoadMore(ScrollPosition position) {
  const minExtent = 480.0;
  final remaining = position.maxScrollExtent - position.pixels;
  final trigger = math.max(minExtent, position.viewportDimension * 1.25);
  return remaining <= trigger;
}
