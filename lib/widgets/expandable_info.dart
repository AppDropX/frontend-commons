import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
  final dividerColor =
      parseHexColor(node.s('dividerColor', def: '#E6DDD0')) ??
          const Color(0xFFE6DDD0);
  final aspectRatio = node.d('aspectRatio', def: 16 / 9);
  final radiusDp = node.d('radiusDp', def: 0).clamp(0, 32).toDouble();
  final fitWithImage = node.b('fitWithImage', def: false);
  final tapAction = effectiveMediaTapAction(node);

  final body = ExpandableInfoBlock(
    sections: sections,
    backgroundColor: backgroundColor,
    titleColor: titleColor,
    bodyColor: bodyColor,
    iconColor: iconColor,
    dividerColor: dividerColor,
    aspectRatio: aspectRatio <= 0 ? (16 / 9) : aspectRatio,
    radiusDp: radiusDp,
    fitWithImage: fitWithImage,
    onImageTap: tapAction == null
        ? null
        : () => env.dispatchAction(context, tapAction),
    r: env.r,
  );
  return wrapPdpStagger(context, PdpStaggerSlot.description, body);
}

class ExpandableInfoSection {
  const ExpandableInfoSection({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.defaultExpanded = false,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final bool defaultExpanded;
}

List<ExpandableInfoSection> parseExpandableInfoSections(List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final out = <ExpandableInfoSection>[];
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final title = (map['title'] ?? '').toString().trim();
    final body = (map['body'] ?? '').toString().trim();
    final imageUrl = sanitizedNetworkImageUrl((map['imageUrl'] ?? '').toString());
    if (title.isEmpty && body.isEmpty && imageUrl == null) continue;
    final id = (map['id'] ?? '').toString().trim();
    out.add(
      ExpandableInfoSection(
        id: id.isEmpty ? 'section_$i' : id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        defaultExpanded: map['defaultExpanded'] == true,
      ),
    );
  }
  return out;
}

class ExpandableInfoBlock extends StatelessWidget {
  const ExpandableInfoBlock({
    super.key,
    required this.sections,
    required this.backgroundColor,
    required this.titleColor,
    required this.bodyColor,
    required this.iconColor,
    required this.dividerColor,
    required this.aspectRatio,
    required this.radiusDp,
    required this.fitWithImage,
    this.onImageTap,
    required this.r,
  });

  final List<ExpandableInfoSection> sections;
  final Color backgroundColor;
  final Color titleColor;
  final Color bodyColor;
  final Color iconColor;
  final Color dividerColor;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final VoidCallback? onImageTap;
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
                  titleColor: titleColor,
                  bodyColor: bodyColor,
                  iconColor: iconColor,
                  aspectRatio: aspectRatio,
                  radiusDp: radiusDp,
                  fitWithImage: fitWithImage,
                  onImageTap: onImageTap,
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
    required this.titleColor,
    required this.bodyColor,
    required this.iconColor,
    required this.aspectRatio,
    required this.radiusDp,
    required this.fitWithImage,
    this.onImageTap,
    required this.r,
  });

  final ExpandableInfoSection section;
  final Color titleColor;
  final Color bodyColor;
  final Color iconColor;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final VoidCallback? onImageTap;
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
    final title = widget.section.title.isEmpty
        ? 'Details'
        : widget.section.title;
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
                        child: Icon(
                          _isOpen
                              ? FluentIcons.dismiss_20_regular
                              : FluentIcons.add_20_regular,
                          key: ValueKey(_isOpen),
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
                  onImageTap: widget.onImageTap,
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
    this.onImageTap,
    required this.r,
  });

  final ExpandableInfoSection section;
  final Color bodyColor;
  final double aspectRatio;
  final double radiusDp;
  final bool fitWithImage;
  final VoidCallback? onImageTap;
  final R r;

  @override
  Widget build(BuildContext context) {
    final hasBody = section.body.isNotEmpty;
    final imageUrl = section.imageUrl;
    if (!hasBody && imageUrl == null) {
      return SizedBox(height: r.dp(8));
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(r.dp(4), 0, r.dp(4), r.dp(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasBody)
            Text(
              section.body,
              style: TextStyle(
                color: bodyColor,
                fontSize: r.sp(13, min: 12, max: 15),
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (hasBody && imageUrl != null) SizedBox(height: r.dp(12)),
          if (imageUrl != null)
            _ExpandableInfoImage(
              url: imageUrl,
              aspectRatio: aspectRatio,
              radiusDp: radiusDp,
              fitWithImage: fitWithImage,
              onTap: onImageTap,
              r: r,
            ),
        ],
      ),
    );
  }
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
          ? _FitWithImageFill(url: url, fallbackAspect: aspectRatio)
          : AspectRatio(
              aspectRatio: aspectRatio,
              child: AppDropNetworkImage(
                url: url,
                fit: BoxFit.cover,
                width: double.infinity,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFE8E0D4),
                  child: SizedBox.expand(),
                ),
              ),
            ),
    );

    if (onTap == null) return image;
    return GestureDetector(
      onTap: onTap,
      child: image,
    );
  }
}

class _FitWithImageFill extends StatefulWidget {
  const _FitWithImageFill({
    required this.url,
    required this.fallbackAspect,
  });

  final String url;
  final double fallbackAspect;

  @override
  State<_FitWithImageFill> createState() => _FitWithImageFillState();
}

class _FitWithImageFillState extends State<_FitWithImageFill> {
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _FitWithImageFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _aspect = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final aspect = await resolveNetworkImageAspectRatio(widget.url);
    if (!mounted || aspect == null || aspect <= 0) return;
    setState(() => _aspect = aspect);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspect ?? widget.fallbackAspect,
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
