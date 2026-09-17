import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/page_toolbar_config.dart';
import '../theme/appdrop_theme_config.dart';
import '../theme/appdrop_theme_data.dart';
import '../utils/network_image_url.dart';
import '../utils/toolbar_icons.dart';
import 'appdrop_network_image.dart';
import 'appdrop_tinted_graphic.dart';

/// Default storefront toolbar row height (excludes status bar inset).
///
/// Sized to match a slim, logo-forward header (~2× title cap height).
const double kAppDropToolbarHeight = 48.0;

const List<BoxShadow> kAppDropToolbarBottomShadow = [
  BoxShadow(
    color: Color(0x12000000),
    blurRadius: 4,
    offset: Offset(0, 2),
    spreadRadius: 0,
  ),
];

class AppDropAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppStylingConfig styling;
  final String title;
  final double toolbarHeight;
  final bool showMenu;
  final bool showCart;
  final VoidCallback? onCartTap;

  /// Total units in cart; shown as a badge on the cart icon when > 0.
  final int? cartBadgeCount;

  /// When set, drives leading, title, and actions (PLP / Home / custom toolbars).
  final PageToolbarConfig? pageToolbar;

  /// Whether a drawer is available (required for side-navigation leading control).
  final bool hasDrawer;
  final VoidCallback? onBack;
  final VoidCallback? onWishlistTap;
  final bool wishlistSelected;
  final VoidCallback? onSearchTap;

  /// Extra top inset when [MediaQuery] has no top padding (builder iPhone
  /// frame). On a real device, [build] uses [MediaQuery] padding instead so
  /// the toolbar row sits below the system status bar. Do **not** pass the
  /// live status-bar height here — [Scaffold] already adds it to
  /// [preferredSize], and putting it in this field would double-count.
  final double statusBarInset;

  const AppDropAppBar({
    super.key,
    required this.toolbarHeight,
    required this.styling,
    required this.title,
    required this.showMenu,
    required this.showCart,
    this.onCartTap,
    this.cartBadgeCount,
    this.pageToolbar,
    this.hasDrawer = false,
    this.onBack,
    this.onWishlistTap,
    this.wishlistSelected = false,
    this.onSearchTap,
    this.statusBarInset = 0,
  });

  double get _toolbarContentHeight => toolbarHeight;

  /// Logo / wordmark height — ~42% of toolbar (prominent but slim bar).
  double get _logoHeight => (_toolbarContentHeight * 0.417).clamp(18.0, 24.0);

  /// Title cap height — slightly smaller than logo image height.
  double get _titleFontSize =>
      (_toolbarContentHeight * 0.3125).clamp(14.0, 17.0);

  /// Trailing icons — ~46% of toolbar, visually balanced with title.
  double get _iconSize => (_toolbarContentHeight * 0.458).clamp(20.0, 24.0);

  /// Uploaded SVG toolbar icons render smaller — many assets use a large viewBox.
  double get _svgIconSize => (_toolbarContentHeight * 0.354).clamp(16.0, 18.0);

  /// Minimum tap target height; width is tighter so right-side icons sit closer.
  double get _actionTapExtent =>
      (_toolbarContentHeight * 0.917).clamp(40.0, 48.0);

  double get _actionButtonWidth =>
      (_toolbarContentHeight * 0.833).clamp(36.0, 40.0);

  double get _h => _toolbarContentHeight + statusBarInset;
  @override
  Size get preferredSize => Size.fromHeight(_h);

  static const double _kHorizontalEdgePadding = 16;
  static const double _kTrailingEdgePadding = 8;
  static const double _kActionSpacing = 4;
  static const double _kLogoMaxWidth = 168;
  static const double _kTitleMaxWidth = 200;
  static const double _kLeadingTitleGap = 4;

  ButtonStyle get _actionButtonStyle => IconButton.styleFrom(
        foregroundColor: styling.toolbarFont,
        padding: EdgeInsets.zero,
        minimumSize: Size(_actionButtonWidth, _actionTapExtent),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );

  double _graphicSize({String svgUrl = ''}) {
    final url = sanitizedNetworkImageUrl(svgUrl);
    if (url != null && isSvgNetworkUrl(url)) return _svgIconSize;
    return _iconSize;
  }

  Widget _tintedGraphic({
    required String glyph,
    String svgUrl = '',
    bool filled = false,
    double? size,
  }) {
    return AppDropTintedGraphic(
      glyph: glyph,
      svgUrl: svgUrl,
      color: styling.toolbarFont,
      size: size ?? _graphicSize(svgUrl: svgUrl),
      filled: filled,
    );
  }

  Widget _drawerButton({
    bool compact = true,
    String glyph = ToolbarGlyph.menu,
    String svgUrl = '',
  }) {
    final graphicSize = _graphicSize(svgUrl: svgUrl);
    return Builder(
      builder: (ctx) => IconButton(
        tooltip: 'Open menu',
        iconSize: graphicSize,
        style: compact ? _actionButtonStyle : null,
        icon: _tintedGraphic(
          glyph: glyph,
          svgUrl: svgUrl,
          size: compact ? graphicSize : 24,
        ),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      ),
    );
  }

  Widget _actionIconButton({
    required Widget icon,
    required String tooltip,
    VoidCallback? onPressed,
    double? iconSize,
  }) {
    return IconButton(
      tooltip: tooltip,
      iconSize: iconSize ?? _iconSize,
      style: _actionButtonStyle,
      icon: icon,
      onPressed: onPressed,
    );
  }

  Widget? _leading(BuildContext context) {
    final pt = pageToolbar;
    if (pt != null) {
      switch (pt.left) {
        case ToolbarLeft.sideNavigation:
          if (!hasDrawer) return null;
          return _drawerButton(
            glyph: pt.resolvedLeftGlyph(),
            svgUrl: pt.resolvedLeftIconUrl(),
          );
        case ToolbarLeft.back:
          final leftSvg = pt.resolvedLeftIconUrl();
          final leftGraphicSize = _graphicSize(svgUrl: leftSvg);
          return _actionIconButton(
            tooltip: 'Back',
            onPressed: onBack ?? () => Navigator.maybePop(context),
            iconSize: leftGraphicSize,
            icon: _tintedGraphic(
              glyph: pt.resolvedLeftGlyph(),
              svgUrl: leftSvg,
              size: leftGraphicSize,
            ),
          );
        case ToolbarLeft.none:
        default:
          return null;
      }
    }
    if (showMenu) return _drawerButton();
    return null;
  }

  TextStyle _titleTextStyle() {
    return AppDropThemeData.textStyle(
      fontFamily: styling.fontFamily,
      fontSize: _titleFontSize,
      fontWeight: FontWeight.w500,
      color: styling.toolbarFont,
    ).copyWith(
      height: 1.15,
      letterSpacing: 0.8,
    );
  }

  Widget _titleWidget({required bool alignLeft}) {
    final pt = pageToolbar;
    final textAlign = alignLeft ? TextAlign.left : TextAlign.center;
    final textStyle = _titleTextStyle();
    Widget textBox(Widget child) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kTitleMaxWidth),
        child: child,
      );
    }

    Widget logoBox(Widget child) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: _logoHeight,
          maxWidth: _kLogoMaxWidth,
        ),
        child: child,
      );
    }

    if (pt != null) {
      if (pt.center == ToolbarCenter.none) {
        return const SizedBox.shrink();
      }
      if (pt.center == ToolbarCenter.text) {
        return textBox(
          Text(
            pt.centerText.isEmpty ? title : pt.centerText,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        );
      }
      if (pt.center == ToolbarCenter.logo) {
        final url = sanitizedNetworkImageUrl(pt.centerLogoUrl);
        if (url == null) {
          return const SizedBox.shrink();
        }
        final align = alignLeft ? Alignment.centerLeft : Alignment.center;
        final tint = ColorFilter.mode(styling.toolbarFont, BlendMode.srcIn);
        if (isSvgNetworkUrl(url)) {
          return logoBox(
            SvgPicture.network(
              url,
              height: _logoHeight,
              fit: BoxFit.contain,
              alignment: align,
              colorFilter: tint,
              placeholderBuilder: (_) => SizedBox(height: _logoHeight),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          );
        }
        return logoBox(
          AppDropNetworkImage(
            url: url,
            height: _logoHeight,
            fit: BoxFit.contain,
            alignment: align,
            color: styling.toolbarFont,
            colorBlendMode: BlendMode.srcIn,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }
      if (pt.center == ToolbarCenter.collectionSearch) {
        return textBox(
          Text(
            'Collection',
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        );
      }
    }
    return textBox(
      Text(
        title,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }

  Widget? _slotAction(String slot, {int index = 0}) {
    final pt = pageToolbar;
    final glyph = (pt != null && index > 0)
        ? pt.resolvedRightGlyph(index)
        : ToolbarGlyph.defaultForAction(slot);
    final svgUrl =
        (pt != null && index > 0) ? pt.resolvedRightIconUrl(index) : '';
    final graphicSize = _graphicSize(svgUrl: svgUrl);

    switch (slot) {
      case ToolbarRight.none:
        return null;
      case ToolbarRight.sideNavigation:
        if (!hasDrawer) return null;
        return _drawerButton(compact: true, glyph: glyph, svgUrl: svgUrl);
      case ToolbarRight.cart:
        return _actionIconButton(
          tooltip: 'Cart',
          onPressed: onCartTap,
          iconSize: graphicSize,
          icon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _tintedGraphic(
                glyph: glyph,
                svgUrl: svgUrl,
                size: graphicSize,
              ),
              if (cartBadgeCount != null && cartBadgeCount! > 0)
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    alignment: Alignment.center,
                    child: Text(
                      cartBadgeCount! > 99 ? '99+' : '${cartBadgeCount!}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      case ToolbarRight.wishlist:
        return _actionIconButton(
          tooltip: 'Wishlist',
          onPressed: onWishlistTap,
          iconSize: graphicSize,
          icon: _tintedGraphic(
            glyph: glyph,
            svgUrl: svgUrl,
            size: graphicSize,
            filled: wishlistSelected,
          ),
        );
      case ToolbarRight.search:
        return _actionIconButton(
          tooltip: 'Search',
          onPressed: onSearchTap,
          iconSize: graphicSize,
          icon: _tintedGraphic(
            glyph: glyph,
            svgUrl: svgUrl,
            size: graphicSize,
          ),
        );
      default:
        return null;
    }
  }

  List<Widget> _actions() {
    final pt = pageToolbar;
    if (pt != null) {
      final out = <Widget>[];
      void addSlot(int index, String s) {
        final w = _slotAction(s, index: index);
        if (w != null) out.add(w);
      }

      addSlot(1, pt.rightSlot1);
      addSlot(2, pt.rightSlot2);
      addSlot(3, pt.rightSlot3);
      return out;
    }
    if (showCart) {
      return [
        _slotAction(ToolbarRight.cart)!,
      ];
    }
    return const [];
  }

  Widget _actionRow(List<Widget> actions) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: _kActionSpacing),
          actions[i],
        ],
      ],
    );
  }

  Widget _buildToolbarRow({
    required BuildContext context,
    required Widget? leading,
    required bool hasLeading,
    required bool titleLeft,
    required List<Widget> actions,
  }) {
    if (titleLeft) {
      return Padding(
        padding: const EdgeInsets.only(
          left: _kHorizontalEdgePadding,
          right: _kTrailingEdgePadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasLeading) ...[
              leading!,
              const SizedBox(width: _kLeadingTitleGap),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _titleWidget(alignLeft: true),
              ),
            ),
            _actionRow(actions),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: hasLeading ? 4 : _kHorizontalEdgePadding,
        right: _kTrailingEdgePadding,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: _titleWidget(alignLeft: false),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasLeading) leading! else const SizedBox(width: 0),
              const Spacer(),
              _actionRow(actions),
            ],
          ),
        ],
      ),
    );
  }

  /// Status-bar height that should sit *above* the toolbar row.
  ///
  /// Real devices report this via [MediaQuery]; the builder preview zeros
  /// that padding (the fake status bar is painted separately) and passes
  /// [statusBarInset] instead.
  double _resolvedTopInset(BuildContext context) {
    final mediaTop = MediaQuery.paddingOf(context).top;
    if (mediaTop > 0) return mediaTop;
    final viewTop = MediaQuery.viewPaddingOf(context).top;
    if (viewTop > 0) return viewTop;
    return statusBarInset;
  }

  SystemUiOverlayStyle _overlayStyleForToolbar() {
    final isDarkBg = ThemeData.estimateBrightnessForColor(styling.toolbarBg) ==
        Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkBg ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkBg ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    final leading = _leading(context);
    final actions = _actions();
    final hasLeading = leading != null;
    final titleLeft = pageToolbar?.isTitleLeftAligned ?? false;
    final topInset = _resolvedTopInset(context);

    final toolbar = DecoratedBox(
      decoration: BoxDecoration(
        color: styling.toolbarBg,
        boxShadow: kAppDropToolbarBottomShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SizedBox(
            height: _toolbarContentHeight,
            child: _buildToolbarRow(
              context: context,
              leading: leading,
              hasLeading: hasLeading,
              titleLeft: titleLeft,
              actions: actions,
            ),
          ),
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyleForToolbar(),
      child: IconTheme(
        data: IconThemeData(size: _iconSize, color: styling.toolbarFont),
        child: toolbar,
      ),
    );
  }
}
