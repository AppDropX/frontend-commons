import 'package:flutter/widgets.dart';
import '../theme_library.dart';
import '../utils/color.dart';

const _kPeekAspectRatio = 4 / 5;
const _kPeekSideScale = 0.82;
const _kDefaultSlideTitleColor = Color(0xFF374151);

/// Odd-numbered buffer for infinite scroll; the center block is the live viewport.
const _kInfiniteBlocks = 21;
const _kInfiniteStartBlock = _kInfiniteBlocks ~/ 2;

List<String>? _carouselImageUrlsFromProps(WidgetNode node) {
  final raw = node.props['imageUrls'] ?? node.props['image_urls'];
  if (raw is! List) return null;
  return [
    for (final e in raw) e?.toString() ?? '',
  ];
}

List<String> _carouselImageTitlesFromProps(WidgetNode node) {
  final raw = node.props['imageTitles'] ?? node.props['image_titles'];
  if (raw is! List) return const [];
  return [
    for (final e in raw) e?.toString() ?? '',
  ];
}

String _slideTitleFromProps(Map<String, dynamic> props) {
  for (final key in [
    'overlayTitle',
    'overlay_title',
    'slideTitle',
    'slide_title',
    'caption',
    'label',
  ]) {
    final v = (props[key] ?? '').toString().trim();
    if (v.isNotEmpty) return v;
  }
  return '';
}

WidgetNode _childWithCarouselTitle(
  WidgetNode child,
  int bannerIndex,
  List<String> parentTitles,
) {
  if (_slideTitleFromProps(child.props).isNotEmpty) return child;
  if (bannerIndex < 0 || bannerIndex >= parentTitles.length) return child;
  final title = parentTitles[bannerIndex].trim();
  if (title.isEmpty) return child;
  final props = Map<String, dynamic>.from(child.props);
  props['overlayTitle'] = title;
  return WidgetNode(
    type: child.type,
    props: props,
    children: child.children,
  );
}

bool _centeredPeek(WidgetNode node) => node.b('centeredPeek', def: false);

bool _infiniteScroll(WidgetNode node) => node.b('infiniteScroll', def: true);

bool _showSlideTitles(WidgetNode node) => node.b('showSlideTitles', def: false);

double _carouselRadiusDp(WidgetNode node) => node.d('radiusDp', def: 16);

double _carouselItemWidthFactor(WidgetNode node) =>
    node.d('itemWidthFactor', def: 0.82).clamp(0.2, 1.0);

double _carouselSpacingDp(WidgetNode node) => node.d('spacingDp', def: 8);

double _carouselPeekViewportFraction(WidgetNode node, AppDropBuildEnv env) {
  final cardW = env.r.w * _carouselItemWidthFactor(node);
  final spacing = env.r.dp(_carouselSpacingDp(node));
  return ((cardW + spacing) / env.r.w).clamp(0.2, 1.0);
}

double _carouselImageHeight(WidgetNode node, AppDropBuildEnv env, {required bool peek}) {
  final heightDp = node.d('heightDp', def: 0);
  if (heightDp > 0) return env.r.dp(heightDp);
  final itemW = env.r.w * _carouselItemWidthFactor(node);
  if (peek) return itemW / _kPeekAspectRatio;
  return env.r.w * 0.55;
}

WidgetNode _styledSlideNode(
  WidgetNode child,
  WidgetNode carousel, {
  required bool peek,
}) {
  final props = Map<String, dynamic>.from(child.props);
  props['radiusDp'] = _carouselRadiusDp(carousel);
  props['showOverlayTitle'] = false;
  if (peek) {
    props['aspectRatio'] = _kPeekAspectRatio;
    props['fitWithImage'] = false;
  }
  return WidgetNode(
    type: child.type,
    props: props,
    children: child.children,
  );
}

Map<String, dynamic> _syntheticSlideJson(
  String url,
  int i,
  WidgetNode carousel,
  List<dynamic>? imageRedirects, {
  String overlayTitle = '',
  required bool peek,
}) {
  final json = <String, dynamic>{
    'type': 'image_banner',
    'url': url,
    'aspectRatio': peek ? _kPeekAspectRatio : 16 / 9,
    'radiusDp': _carouselRadiusDp(carousel),
    'bgColor': '#E5E7EB',
    'enabled': true,
    'overlayTitle': overlayTitle,
    'showOverlayTitle': false,
  };
  if (imageRedirects != null &&
      i < imageRedirects.length &&
      imageRedirects[i] is Map) {
    json['redirect'] = Map<String, dynamic>.from(imageRedirects[i] as Map);
  }
  return json;
}

List<WidgetNode> _resolvedSlides(WidgetNode node, {required bool peek}) {
  final parentTitles = _carouselImageTitlesFromProps(node);
  if (node.children.isNotEmpty) {
    var bannerIdx = 0;
    final slides = <WidgetNode>[];
    for (final c in node.children) {
      var slide = c;
      if (c.type == 'image_banner') {
        slide = _childWithCarouselTitle(c, bannerIdx, parentTitles);
        bannerIdx++;
      }
      slides.add(_styledSlideNode(slide, node, peek: peek));
    }
    return slides;
  }
  final urlList = _carouselImageUrlsFromProps(node);
  if (urlList == null || urlList.isEmpty) return const [];
  final titles = _carouselImageTitlesFromProps(node);
  final redirects = imageRedirectsListFromNode(node);
  return [
    for (var i = 0; i < urlList.length; i++)
      WidgetNode.fromJson(
        _syntheticSlideJson(
          urlList[i],
          i,
          node,
          redirects,
          overlayTitle: i < titles.length ? titles[i] : '',
          peek: peek,
        ),
      ),
  ];
}

double _slideTitleFontSize(WidgetNode node, AppDropBuildEnv env) {
  final explicitSizeDp = node.d('slideTitleFontSizeDp', def: 0);
  if (explicitSizeDp > 0) {
    return env.r.sp(explicitSizeDp, min: 8, max: 24);
  }

  final v = node.s('slideTitleFontVariation', def: 'medium').toLowerCase();
  switch (v) {
    case 'small':
      return env.r.sp(10, min: 8, max: 13);
    case 'large':
      return env.r.sp(14, min: 12, max: 18);
    case 'medium':
    default:
      return env.r.sp(12, min: 10, max: 16);
  }
}

Color _slideTitleColor(WidgetNode node) {
  final raw = node.s('slideTitleColor', def: '').trim();
  if (raw.isEmpty) return _kDefaultSlideTitleColor;
  return parseHexColor(raw) ?? _kDefaultSlideTitleColor;
}

double _titleBlockHeight(
  AppDropBuildEnv env,
  WidgetNode node,
  bool showTitles,
) {
  if (!showTitles) return 0;
  final fontSize = _slideTitleFontSize(node, env);
  return env.r.dp(8) + fontSize * 1.25 + env.r.dp(4);
}

Widget _slideTitleLabel({
  required String title,
  required AppDropBuildEnv env,
  required WidgetNode carousel,
  required bool peek,
}) {
  final fontSize = _slideTitleFontSize(carousel, env);
  final blockH = _titleBlockHeight(env, carousel, true);
  if (title.isEmpty) {
    return SizedBox(height: blockH);
  }
  return SizedBox(
    height: blockH,
    child: Padding(
      padding: EdgeInsets.only(top: env.r.dp(8)),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.25,
            fontWeight: FontWeight.w500,
            letterSpacing: peek ? 1.2 : 0.2,
            color: _slideTitleColor(carousel),
          ),
        ),
      ),
    ),
  );
}

Widget _slideColumn({
  required Widget slide,
  required String title,
  required double imageHeight,
  required bool showTitle,
  required AppDropBuildEnv env,
  required WidgetNode carousel,
  required bool peek,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: imageHeight, child: slide),
      if (showTitle)
        _slideTitleLabel(
          title: title,
          env: env,
          carousel: carousel,
          peek: peek,
        ),
    ],
  );
}

Widget buildCarousel(BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final props = Map<String, dynamic>.from(node.props);
  normalizeCarouselProps(props);
  final normalized = WidgetNode(
    type: node.type,
    props: props,
    children: node.children,
  );
  return _AppDropCarousel(node: normalized, env: env);
}

class _AppDropCarousel extends StatefulWidget {
  const _AppDropCarousel({required this.node, required this.env});

  final WidgetNode node;
  final AppDropBuildEnv env;

  @override
  State<_AppDropCarousel> createState() => _AppDropCarouselState();
}

class _AppDropCarouselState extends State<_AppDropCarousel> {
  PageController? _pageController;
  ScrollController? _listController;
  bool _recenteringPage = false;
  bool _recenteringList = false;

  int _slideCount = 0;
  double _listStride = 0;

  bool get _peek => _centeredPeek(widget.node);

  int _loopStartIndex(int count, bool infinite) =>
      (infinite && count > 1) ? count * _kInfiniteStartBlock : 0;

  int _loopItemCount(int count, bool infinite) =>
      (infinite && count > 1) ? count * _kInfiniteBlocks : count;

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  @override
  void didUpdateWidget(covariant _AppDropCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPeek = _centeredPeek(oldWidget.node);
    final peek = _peek;
    final oldInfinite = _infiniteScroll(oldWidget.node);
    final infinite = _infiniteScroll(widget.node);
    final oldCount = _resolvedSlides(oldWidget.node, peek: oldPeek).length;
    final count = _resolvedSlides(widget.node, peek: peek).length;
    final peekWidthChanged = peek &&
        (_carouselItemWidthFactor(oldWidget.node) !=
                _carouselItemWidthFactor(widget.node) ||
            _carouselSpacingDp(oldWidget.node) !=
                _carouselSpacingDp(widget.node));
    if (oldPeek != peek ||
        oldInfinite != infinite ||
        oldCount != count ||
        peekWidthChanged ||
        !_controllersMatchConfig(peek)) {
      _disposeControllers();
      _createControllers();
    }
  }

  bool _controllersMatchConfig(bool peek) {
    if (peek) return _pageController != null;
    return _listController != null;
  }

  void _createControllers() {
    final peek = _peek;
    final infinite = _infiniteScroll(widget.node);
    final slides = _resolvedSlides(widget.node, peek: peek);
    final count = slides.length;
    _slideCount = count;
    final start = _loopStartIndex(count, infinite);

    if (peek) {
      final viewport = _carouselPeekViewportFraction(widget.node, widget.env);
      _pageController = PageController(
        viewportFraction: viewport,
        initialPage: start,
      );
    } else {
      final itemW = widget.env.r.w * _carouselItemWidthFactor(widget.node);
      final spacing = widget.env.r.dp(_carouselSpacingDp(widget.node));
      _listStride = itemW + spacing;
      final offset = start * _listStride;
      _listController = ScrollController(initialScrollOffset: offset);
      _listController!.addListener(_onListScroll);
    }
  }

  void _onListScroll() {
    if (_recenteringList || _slideCount <= 1) return;
    if (!_infiniteScroll(widget.node)) return;
    final c = _listController;
    if (c == null || !c.hasClients || _listStride <= 0) return;

    final blockSize = _slideCount * _listStride;
    final pos = c.offset;
    if (pos < blockSize * 0.5) {
      _recenteringList = true;
      final inBlockOffset = pos % blockSize;
      c.jumpTo(blockSize * _kInfiniteStartBlock + inBlockOffset);
      _recenteringList = false;
    } else if (pos > blockSize * (_kInfiniteBlocks - 0.5)) {
      _recenteringList = true;
      final inBlockOffset = pos % blockSize;
      c.jumpTo(blockSize * _kInfiniteStartBlock + inBlockOffset);
      _recenteringList = false;
    }
  }

  void _onPeekPageChanged(int index, int count, bool infinite) {
    if (_recenteringPage || !infinite || count <= 1) return;
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;

    final block = index ~/ count;
    if (block <= 1) {
      _recenteringPage = true;
      controller.jumpToPage(count * _kInfiniteStartBlock + (index % count));
      _recenteringPage = false;
    } else if (block >= _kInfiniteBlocks - 2) {
      _recenteringPage = true;
      controller.jumpToPage(count * _kInfiniteStartBlock + (index % count));
      _recenteringPage = false;
    }
  }

  void _disposeControllers() {
    _listController?.removeListener(_onListScroll);
    _pageController?.dispose();
    _pageController = null;
    _listController?.dispose();
    _listController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final env = widget.env;
    final peek = _peek;
    final infinite = _infiniteScroll(node);
    final showTitles = _showSlideTitles(node);
    final slides = _resolvedSlides(node, peek: peek);
    final count = slides.length;
    if (count == 0) return const SizedBox.shrink();

    final loopCount = _loopItemCount(count, infinite);
    final itemWidthFactor = _carouselItemWidthFactor(node);
    final spacing = env.r.dp(_carouselSpacingDp(node));
    final imageH = _carouselImageHeight(node, env, peek: peek);
    final titleH = _titleBlockHeight(env, node, showTitles);

    Widget slideAt(BuildContext ctx, int realIndex) {
      return env.renderNode(ctx, slides[realIndex]) as Widget;
    }

    String titleAt(int realIndex) {
      if (!showTitles) return '';
      final parentTitles = _carouselImageTitlesFromProps(node);
      if (realIndex >= 0 && realIndex < parentTitles.length) {
        final fromParent = parentTitles[realIndex].trim();
        if (fromParent.isNotEmpty) return fromParent;
      }
      return _slideTitleFromProps(slides[realIndex].props);
    }

    if (peek) {
      final pageController = _pageController;
      if (pageController == null) return const SizedBox.shrink();
      final cardW = env.r.w * itemWidthFactor;

      return SizedBox(
        height: imageH + titleH,
        child: PageView.builder(
          controller: pageController,
          allowImplicitScrolling: true,
          clipBehavior: Clip.none,
          padEnds: true,
          itemCount: loopCount,
          onPageChanged: (i) => _onPeekPageChanged(i, count, infinite),
          itemBuilder: (ctx, i) {
            final real = i % count;
            return _PeekScaledPage(
              controller: pageController,
              index: i,
              cardWidth: cardW,
              spacing: spacing,
              child: _slideColumn(
                slide: slideAt(ctx, real),
                title: titleAt(real),
                imageHeight: imageH,
                showTitle: showTitles,
                env: env,
                carousel: node,
                peek: true,
              ),
            );
          },
        ),
      );
    }

    final itemW = env.r.w * itemWidthFactor;
    final listController = _listController;

    return SizedBox(
      height: imageH + titleH,
      child: ListView.separated(
        controller: listController,
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        cacheExtent: env.r.w,
        itemCount: loopCount,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (ctx, i) {
          final real = i % count;
          final slide = slideAt(ctx, real);
          if (!showTitles) {
            return SizedBox(width: itemW, child: slide);
          }
          return SizedBox(
            width: itemW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: slide),
                _slideTitleLabel(
                  title: titleAt(real),
                  env: env,
                  carousel: node,
                  peek: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeekScaledPage extends StatelessWidget {
  const _PeekScaledPage({
    required this.controller,
    required this.index,
    required this.cardWidth,
    required this.spacing,
    required this.child,
  });

  final PageController controller;
  final int index;
  final double cardWidth;
  final double spacing;
  final Widget child;

  double _scaleForPage(double page) {
    final delta = (page - index).abs();
    if (delta >= 1.0) return _kPeekSideScale;
    final t = (1.0 - delta).clamp(0.0, 1.0);
    return _kPeekSideScale +
        (1.0 - _kPeekSideScale) * Curves.easeOutCubic.transform(t);
  }

  /// Keeps the visible gap between card edges equal to [spacing] while scaling.
  double _horizontalShift(double page, double scale) {
    if (scale >= 0.999) return 0;
    final delta = page - index;
    if (delta.abs() < 0.001) return 0;
    final inset = (1.0 - scale) * cardWidth * 0.5;
    return delta.sign * inset;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final scale = _scaleForPage(page);
        final shift = _horizontalShift(page, scale);
        return Padding(
          padding: EdgeInsets.only(right: spacing),
          child: SizedBox(
            width: cardWidth,
            child: Transform.translate(
              offset: Offset(shift, 0),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
