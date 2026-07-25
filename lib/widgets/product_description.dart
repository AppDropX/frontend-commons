import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/color.dart';

/// Compact expandable product description for PDP.
/// Props: enabled, defaultAccordionState (expanded|collapsed), title, description,
/// titleColor, descriptionColor.
Widget buildProductDescription(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final defaultExpanded =
      node.s('defaultAccordionState', def: 'collapsed').toLowerCase() == 'expanded';
  final title = node.s('title', def: 'Product Description');
  final description = node.s('description', def: '');
  final scope = AppDropThemeScope.maybeOf(context);
  final titleColor = parseHexColor(node.s('titleColor', def: '#111827')) ??
      scope?.appStyling.fontIconColor ??
      const Color(0xFF111827);
  final descriptionColor =
      parseHexColor(node.s('descriptionColor', def: '#6B7280')) ??
          const Color(0xFF6B7280);

  final body = _ProductDescriptionWidget(
    initiallyExpanded: defaultExpanded,
    title: title,
    description: description,
    titleColor: titleColor,
    descriptionColor: descriptionColor,
    r: env.r,
  );
  return wrapPdpStagger(context, PdpStaggerSlot.description, body);
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
  State<_ProductDescriptionWidget> createState() =>
      _ProductDescriptionWidgetState();
}

class _ProductDescriptionWidgetState extends State<_ProductDescriptionWidget>
    with SingleTickerProviderStateMixin {
  static const _previewLines = 3;
  static const _animDuration = Duration(milliseconds: 250);

  /// Section body visible (header expand/collapse).
  late bool _isOpen;
  /// Full text vs 3-line preview (read more / show less).
  late bool _isFullText;
  late final AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initiallyExpanded;
    _isFullText = widget.initiallyExpanded;
    _arrowController = AnimationController(
      vsync: this,
      duration: _animDuration,
      value: _isOpen ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  String get _displayText {
    final text = widget.description.trim();
    return text.isEmpty ? 'Add product details here.' : text;
  }

  bool _textOverflows(double maxWidth, TextStyle style) {
    if (maxWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: _displayText, style: style),
      maxLines: _previewLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  void _toggleSection() {
    setState(() {
      _isOpen = !_isOpen;
      if (!_isOpen) _isFullText = false;
    });
    if (_isOpen) {
      _arrowController.forward();
    } else {
      _arrowController.reverse();
    }
  }

  void _expandText() {
    setState(() => _isFullText = true);
  }

  void _collapseText() {
    setState(() => _isFullText = false);
  }

  TextStyle _titleStyle() {
    return TextStyle(
      color: widget.titleColor,
      fontSize: widget.r.sp(14, min: 13, max: 16),
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }

  TextStyle _descriptionStyle() {
    return TextStyle(
      color: widget.descriptionColor,
      fontSize: widget.r.sp(14, min: 13, max: 16),
      height: 1.45,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaceColor = scheme.surfaceContainerLowest.withValues(alpha: 0.65);
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.45);
    final radius = BorderRadius.circular(widget.r.dp(10));
    final headerHeight = widget.r.dp(52).clamp(48.0, 56.0);
    final titleText =
        widget.title.isEmpty ? 'Product Description' : widget.title;
    final descriptionStyle = _descriptionStyle();

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth - widget.r.dp(24))
            .clamp(0.0, double.infinity);
        final canExpandText = _textOverflows(contentWidth, descriptionStyle);
        final showPreview = _isOpen && canExpandText && !_isFullText;
        final fadeColor = surfaceColor;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: headerHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleSection,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.r.dp(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _titleStyle(),
                          ),
                        ),
                        RotationTransition(
                          turns: Tween<double>(begin: 0, end: 0.5).animate(
                            CurvedAnimation(
                              parent: _arrowController,
                              curve: Curves.easeInOutCubic,
                            ),
                          ),
                          child: Icon(
                            FluentIcons.chevron_down_20_regular,
                            size: widget.r.dp(22),
                            color: widget.titleColor.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: _animDuration,
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: _isOpen
                    ? (_isFullText || !canExpandText
                        ? _ExpandedContent(
                            text: _displayText,
                            style: descriptionStyle,
                            r: widget.r,
                            canCollapseText: canExpandText,
                            onShowLess: _collapseText,
                          )
                        : _CollapsedContent(
                            text: _displayText,
                            style: descriptionStyle,
                            fadeColor: fadeColor,
                            r: widget.r,
                            showPreview: showPreview,
                            onReadMore: _expandText,
                          ))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CollapsedContent extends StatelessWidget {
  const _CollapsedContent({
    required this.text,
    required this.style,
    required this.fadeColor,
    required this.r,
    required this.showPreview,
    required this.onReadMore,
  });

  final String text;
  final TextStyle style;
  final Color fadeColor;
  final R r;
  final bool showPreview;
  final VoidCallback onReadMore;

  @override
  Widget build(BuildContext context) {
    if (!showPreview) {
      return Padding(
        padding: EdgeInsets.fromLTRB(r.dp(12), 0, r.dp(12), r.dp(10)),
        child: Text(text, style: style),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(r.dp(12), 0, r.dp(12), r.dp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.clip,
                style: style,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: r.dp(28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        fadeColor.withValues(alpha: 0),
                        fadeColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onReadMore,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: r.dp(4),
                  vertical: r.dp(2),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'Read More',
                style: style.copyWith(
                  fontWeight: FontWeight.w600,
                  color: style.color?.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.text,
    required this.style,
    required this.r,
    required this.canCollapseText,
    required this.onShowLess,
  });

  final String text;
  final TextStyle style;
  final R r;
  final bool canCollapseText;
  final VoidCallback onShowLess;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.dp(12), 0, r.dp(12), r.dp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: style),
          if (canCollapseText)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onShowLess,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.dp(4),
                    vertical: r.dp(2),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Show Less',
                  style: style.copyWith(
                    fontWeight: FontWeight.w600,
                    color: style.color?.withValues(alpha: 0.92),
                  ),
                ),
              ),
            )
          else
            SizedBox(height: r.dp(8)),
        ],
      ),
    );
  }
}
