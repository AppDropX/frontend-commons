import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme_library.dart';
import '../utils/color.dart';
import '../utils/network_image_aspect.dart';
import '../utils/network_image_url.dart';

/// Multi-section PDP accordion: title + plus/close icon, expandable text and image.
Widget buildExpandableInfo(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final enabled = node.b('enabled', def: true);
  if (!enabled) return const SizedBox.shrink();

  final sections = parseExpandableInfoSections(node.l('sections'));
  if (sections.isEmpty) return const SizedBox.shrink();

  final backgroundColor =
      parseHexColor(node.s('backgroundColor', def: '#FDFCF8')) ??
          const Color(0xFFFDFCF8);
  final titleColor = parseHexColor(node.s('titleColor', def: '#3D3229')) ??
      const Color(0xFF3D3229);
  final bodyColor = parseHexColor(node.s('bodyColor', def: '#5C534A')) ??
      const Color(0xFF5C534A);
  final iconColor = parseHexColor(node.s('iconColor', def: '#C4A574')) ??
      const Color(0xFFC4A574);
  final dividerColor = parseHexColor(node.s('dividerColor', def: '#E6DDD0')) ??
      const Color(0xFFE6DDD0);
  final aspectRatio = node.d('aspectRatio', def: 16 / 9);
  final radiusDp = node.d('radiusDp', def: 0).clamp(0, 32).toDouble();
  final fitWithImage = node.b('fitWithImage', def: false);
  final tapAction = effectiveMediaTapAction(node);
  final rowIcons = _rowIcons(node);

  final imageUrls = [
    for (final section in sections)
      if (section.imageUrl != null) section.imageUrl!,
  ];
  final body = _WarmExpandableImages(
    urls: imageUrls,
    child: ExpandableInfoBlock(
      sections: sections,
      collapsedIcon: rowIcons.collapsedIcon,
      collapsedIconUrl: rowIcons.collapsedIconUrl,
      expandedIcon: rowIcons.expandedIcon,
      expandedIconUrl: rowIcons.expandedIconUrl,
      backgroundColor: backgroundColor,
      titleColor: titleColor,
      bodyColor: bodyColor,
      iconColor: iconColor,
      dividerColor: dividerColor,
      aspectRatio: aspectRatio <= 0 ? (16 / 9) : aspectRatio,
      radiusDp: radiusDp,
      fitWithImage: fitWithImage,
      blockTapAction: tapAction,
      onOpenAction: (ctx, action) => env.dispatchAction(ctx, action),
      r: env.r,
    ),
  );
  return wrapPdpStagger(context, PdpStaggerSlot.description, body);
}

/// Starts image downloads when the PDP opens, before a section is expanded.
class _WarmExpandableImages extends StatefulWidget {
  const _WarmExpandableImages({required this.urls, required this.child});

  final List<String> urls;
  final Widget child;

  @override
  State<_WarmExpandableImages> createState() => _WarmExpandableImagesState();
}

class _WarmExpandableImagesState extends State<_WarmExpandableImages> {
  final Set<String> _warmed = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final raw in widget.urls) {
      final url = sanitizedNetworkImageUrl(raw);
      if (url == null || !_warmed.add(url)) continue;
      unawaited(precacheImage(NetworkImage(url), context).catchError((_) {}));
      unawaited(resolveNetworkImageAspectRatio(url));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _RowIcons {
  const _RowIcons({
    required this.collapsedIcon,
    required this.collapsedIconUrl,
    required this.expandedIcon,
    required this.expandedIconUrl,
  });

  final String collapsedIcon;
  final String collapsedIconUrl;
  final String expandedIcon;
  final String expandedIconUrl;
}

_RowIcons _rowIcons(WidgetNode node) {
  var collapsedIcon = node.s('collapsedIcon', def: '').trim();
  var collapsedIconUrl = node.s('collapsedIconUrl', def: '').trim();
  if (collapsedIcon.isEmpty && collapsedIconUrl.isEmpty) {
    final raw = node.l('sections');
    if (raw != null) {
      for (final item in raw) {
        if (item is! Map) continue;
        final glyph = (item['trailingIcon'] ?? '').toString().trim();
        final url = (item['trailingIconUrl'] ?? '').toString().trim();
        if (glyph.isNotEmpty || url.isNotEmpty) {
          collapsedIcon = glyph;
          collapsedIconUrl = url;
          break;
        }
      }
    }
  }
  if (collapsedIcon.isEmpty) collapsedIcon = 'add';

  var expandedIcon = node.s('expandedIcon', def: '').trim();
  final expandedIconUrl = node.s('expandedIconUrl', def: '').trim();
  if (expandedIcon.isEmpty) expandedIcon = 'dismiss';

  return _RowIcons(
    collapsedIcon: collapsedIcon,
    collapsedIconUrl: collapsedIconUrl,
    expandedIcon: expandedIcon,
    expandedIconUrl: expandedIconUrl,
  );
}

class ExpandableInfoSection {
  const ExpandableInfoSection({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.defaultExpanded = false,
    this.titleIcon = '',
    this.titleIconUrl = '',
    this.redirect,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final bool defaultExpanded;
  final String titleIcon;
  final String titleIconUrl;
  final Map<String, dynamic>? redirect;

  bool get hasTitleIcon =>
      titleIcon.trim().isNotEmpty || titleIconUrl.trim().isNotEmpty;
}

Map<String, dynamic>? _redirectMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (!trimmed.startsWith('{')) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

List<ExpandableInfoSection> parseExpandableInfoSections(List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final out = <ExpandableInfoSection>[];
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final title = (map['title'] ?? '').toString().trim();
    final body = (map['body'] ?? map['content'] ?? map['description'] ?? '')
        .toString()
        .trim();
    final imageUrl = sanitizedNetworkImageUrl(
      (map['imageUrl'] ?? map['image_url'] ?? '').toString(),
    );
    if (title.isEmpty && body.isEmpty && imageUrl == null) continue;
    final id = (map['id'] ?? '').toString().trim();
    out.add(
      ExpandableInfoSection(
        id: id.isEmpty ? 'section_$i' : id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        defaultExpanded:
            map['defaultExpanded'] == true || map['default_expanded'] == true,
        titleIcon:
            (map['titleIcon'] ?? map['title_icon'] ?? '').toString().trim(),
        titleIconUrl: (map['titleIconUrl'] ?? map['title_icon_url'] ?? '')
            .toString()
            .trim(),
        redirect: _redirectMap(map['redirect']),
      ),
    );
  }
  return out;
}

class ExpandableInfoBlock extends StatelessWidget {
  const ExpandableInfoBlock({
    super.key,
    required this.sections,
    required this.collapsedIcon,
    required this.collapsedIconUrl,
    required this.expandedIcon,
    required this.expandedIconUrl,
    required this.backgroundColor,
    required this.titleColor,
    required this.bodyColor,
    required this.iconColor,
    required this.dividerColor,
    required this.aspectRatio,
    required this.radiusDp,
    required this.fitWithImage,
    this.blockTapAction,
    this.onOpenAction,
    required this.r,
  });

  final List<ExpandableInfoSection> sections;
  final String collapsedIcon;
  final String collapsedIconUrl;
  final String expandedIcon;
  final String expandedIconUrl;
  final Color backgroundColor;
  final Color titleColor;
  final Color bodyColor;
  final Color iconColor;
  final Color dividerColor;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final Map<String, dynamic>? blockTapAction;
  final void Function(BuildContext context, Map<String, dynamic> action)?
      onOpenAction;
  final R r;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: dividerColor,
                  ),
                _ExpandableInfoRow(
                  section: sections[i],
                  collapsedIcon: collapsedIcon,
                  collapsedIconUrl: collapsedIconUrl,
                  expandedIcon: expandedIcon,
                  expandedIconUrl: expandedIconUrl,
                  titleColor: titleColor,
                  bodyColor: bodyColor,
                  iconColor: iconColor,
                  aspectRatio: aspectRatio,
                  radiusDp: radiusDp,
                  fitWithImage: fitWithImage,
                  blockTapAction: blockTapAction,
                  onOpenAction: onOpenAction,
                  r: r,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ExpandableInfoRow extends StatefulWidget {
  const _ExpandableInfoRow({
    required this.section,
    required this.collapsedIcon,
    required this.collapsedIconUrl,
    required this.expandedIcon,
    required this.expandedIconUrl,
    required this.titleColor,
    required this.bodyColor,
    required this.iconColor,
    required this.aspectRatio,
    required this.radiusDp,
    required this.fitWithImage,
    this.blockTapAction,
    this.onOpenAction,
    required this.r,
  });

  final ExpandableInfoSection section;
  final String collapsedIcon;
  final String collapsedIconUrl;
  final String expandedIcon;
  final String expandedIconUrl;
  final Color titleColor;
  final Color bodyColor;
  final Color iconColor;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final Map<String, dynamic>? blockTapAction;
  final void Function(BuildContext context, Map<String, dynamic> action)?
      onOpenAction;
  final R r;

  @override
  State<_ExpandableInfoRow> createState() => _ExpandableInfoRowState();
}

class _ExpandableInfoRowState extends State<_ExpandableInfoRow> {
  static const _animDuration = Duration(milliseconds: 220);

  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.section.defaultExpanded;
  }

  @override
  void didUpdateWidget(covariant _ExpandableInfoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) {
      _isOpen = widget.section.defaultExpanded;
    }
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final title =
        widget.section.title.isEmpty ? 'Details' : widget.section.title;
    final headerHeight = r.dp(52).clamp(48.0, 58.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _isOpen,
          label: title,
          hint: _isOpen ? 'Collapse' : 'Expand',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: headerHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.dp(4),
                    vertical: r.dp(12),
                  ),
                  child: Row(
                    children: [
                      if (widget.section.hasTitleIcon) ...[
                        ExcludeSemantics(
                          child: AppDropTintedGraphic(
                            glyph: widget.section.titleIcon.isEmpty
                                ? 'tag'
                                : widget.section.titleIcon,
                            svgUrl: widget.section.titleIconUrl,
                            size: r.dp(18),
                            color: widget.iconColor,
                          ),
                        ),
                        SizedBox(width: r.dp(8)),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.titleColor,
                            fontSize: r.sp(13, min: 12, max: 15),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            height: 1.25,
                          ),
                        ),
                      ),
                      SizedBox(width: r.dp(12)),
                      AnimatedSwitcher(
                        duration: _animDuration,
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: AppDropTintedGraphic(
                          key: ValueKey(
                            _isOpen
                                ? 'open-${widget.expandedIcon}-${widget.expandedIconUrl}'
                                : 'closed-${widget.collapsedIcon}-${widget.collapsedIconUrl}',
                          ),
                          glyph: _isOpen
                              ? widget.expandedIcon
                              : widget.collapsedIcon,
                          svgUrl: _isOpen
                              ? widget.expandedIconUrl
                              : widget.collapsedIconUrl,
                          size: r.dp(20),
                          color: widget.iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _animDuration,
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _isOpen
              ? _ExpandableInfoBody(
                  section: widget.section,
                  bodyColor: widget.bodyColor,
                  aspectRatio: widget.aspectRatio,
                  radiusDp: widget.radiusDp,
                  fitWithImage: widget.fitWithImage,
                  blockTapAction: widget.blockTapAction,
                  onOpenAction: widget.onOpenAction,
                  r: r,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ExpandableInfoBody extends StatelessWidget {
  const _ExpandableInfoBody({
    required this.section,
    required this.bodyColor,
    required this.aspectRatio,
    required this.radiusDp,
    required this.fitWithImage,
    this.blockTapAction,
    this.onOpenAction,
    required this.r,
  });

  final ExpandableInfoSection section;
  final Color bodyColor;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final Map<String, dynamic>? blockTapAction;
  final void Function(BuildContext context, Map<String, dynamic> action)?
      onOpenAction;
  final R r;

  @override
  Widget build(BuildContext context) {
    final hasBody = section.body.isNotEmpty;
    final imageUrl = section.imageUrl;
    if (!hasBody && imageUrl == null) {
      return SizedBox(height: r.dp(8));
    }

    final sectionAction = actionFromMediaRedirect(section.redirect);
    final textAction = sectionAction ?? blockTapAction;
    final imageAction = blockTapAction ?? sectionAction;
    final open = onOpenAction;
    VoidCallback? imageTap;
    if (imageUrl != null &&
        imageAction != null &&
        open != null &&
        !_sameRedirectAction(imageAction, textAction)) {
      final imageTarget = imageAction;
      final dispatch = open;
      imageTap = () => dispatch(context, imageTarget);
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasBody) _descriptionText(),
        if (hasBody && imageUrl != null) SizedBox(height: r.dp(12)),
        if (imageUrl != null)
          _ExpandableInfoImage(
            url: imageUrl,
            aspectRatio: aspectRatio,
            radiusDp: radiusDp,
            fitWithImage: fitWithImage,
            onTap: imageTap,
            r: r,
          ),
      ],
    );

    final padded = Padding(
      padding: EdgeInsets.fromLTRB(r.dp(4), 0, r.dp(4), r.dp(16)),
      child: column,
    );
    if (textAction == null || open == null) return padded;
    final textTarget = textAction;
    final dispatch = open;
    return Semantics(
      button: true,
      label: section.title.isEmpty ? 'Section details' : section.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => dispatch(context, textTarget),
          child: padded,
        ),
      ),
    );
  }

  Widget _descriptionText() {
    return Text(
      section.body,
      style: TextStyle(
        color: bodyColor,
        fontSize: r.sp(13, min: 12, max: 15),
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

bool _sameRedirectAction(Map<String, dynamic> a, Map<String, dynamic>? b) {
  if (b == null) return false;
  return a['type'] == b['type'] &&
      a['collection'] == b['collection'] &&
      a['productId'] == b['productId'] &&
      a['pageId'] == b['pageId'] &&
      a['url'] == b['url'];
}

Widget _imageWaitSlot({required bool failed}) {
  return SizedBox(
    height: 96,
    child: Center(
      child: failed
          ? const ColoredBox(
              color: Color(0xFFE8E0D4),
              child: SizedBox(width: 96, height: 96),
            )
          : const CupertinoActivityIndicator(radius: 14),
    ),
  );
}

class _ExpandableInfoImage extends StatelessWidget {
  const _ExpandableInfoImage({
    required this.url,
    required this.aspectRatio,
    required this.radiusDp,
    required this.fitWithImage,
    this.onTap,
    required this.r,
  });

  final String url;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final VoidCallback? onTap;
  final R r;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(r.dp(radiusDp.clamp(0, 32)));
    Widget image = ClipRRect(
      borderRadius: radius,
      child: fitWithImage
          ? _FitWithImageFill(url: url)
          : _CropWhenReady(url: url, aspectRatio: aspectRatio),
    );

    if (onTap == null) return image;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: image,
    );
  }
}

class _CropWhenReady extends StatefulWidget {
  const _CropWhenReady({required this.url, required this.aspectRatio});

  final String url;
  final double aspectRatio;

  @override
  State<_CropWhenReady> createState() => _CropWhenReadyState();
}

class _CropWhenReadyState extends State<_CropWhenReady> {
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final cached = cachedNetworkImageAspectRatio(widget.url);
    if (cached != null && cached > 0) {
      _ready = true;
      return;
    }
    _wait();
  }

  @override
  void didUpdateWidget(covariant _CropWhenReady oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _ready = false;
      _failed = false;
      _wait();
    }
  }

  Future<void> _wait() async {
    final aspect = await resolveNetworkImageAspectRatio(widget.url);
    if (!mounted) return;
    setState(() {
      _ready = aspect != null && aspect > 0;
      _failed = !_ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return _imageWaitSlot(failed: _failed);
    return AspectRatio(
      aspectRatio: widget.aspectRatio <= 0 ? 1 : widget.aspectRatio,
      child: AppDropNetworkImage(
        url: widget.url,
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFFE8E0D4),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class _FitWithImageFill extends StatefulWidget {
  const _FitWithImageFill({required this.url});

  final String url;

  @override
  State<_FitWithImageFill> createState() => _FitWithImageFillState();
}

class _FitWithImageFillState extends State<_FitWithImageFill> {
  double? _aspect;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final cached = cachedNetworkImageAspectRatio(widget.url);
    if (cached != null && cached > 0) {
      _aspect = cached;
      return;
    }
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _FitWithImageFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _aspect = null;
      _failed = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final cached = cachedNetworkImageAspectRatio(widget.url);
    if (cached != null && cached > 0) {
      if (mounted) setState(() => _aspect = cached);
      return;
    }
    final aspect = await resolveNetworkImageAspectRatio(widget.url);
    if (!mounted || aspect == null || aspect <= 0) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    setState(() => _aspect = aspect);
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect;
    if (aspect == null) return _imageWaitSlot(failed: _failed);
    return AspectRatio(
      aspectRatio: aspect,
      child: AppDropNetworkImage(
        url: widget.url,
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFFE8E0D4),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}
