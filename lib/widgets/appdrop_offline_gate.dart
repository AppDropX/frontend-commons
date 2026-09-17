import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../connectivity/appdrop_connectivity.dart';
import '../theme/appdrop_theme_config.dart';
import '../theme/appdrop_theme_data.dart';

/// Visual density for the offline notice.
enum AppDropOfflineLayout {
  /// Centered card on a spacious canvas — builder / admin web shells.
  canvas,

  /// Full-screen stacked empty state — storefronts.
  stacked,
}

/// Colors, type, and layout for [AppDropOfflineGate].
class AppDropOfflineStyle {
  const AppDropOfflineStyle({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.titleColor,
    required this.bodyColor,
    required this.buttonForeground,
    required this.fontFamily,
    required this.layout,
    required this.appName,
    this.cornerRadius = 16,
    this.useGoogleFont = false,
    this.title = "You're offline",
    this.subtitle,
    this.actionLabel = 'Try again',
  });

  final Color backgroundColor;
  final Color surfaceColor;
  final Color accentColor;
  final Color titleColor;
  final Color bodyColor;
  final Color buttonForeground;
  final String fontFamily;
  final AppDropOfflineLayout layout;
  final String appName;
  final double cornerRadius;
  final bool useGoogleFont;
  final String title;
  final String? subtitle;
  final String actionLabel;

  String get resolvedSubtitle =>
      subtitle ??
      'Reconnect to the internet to keep using $appName.';

  /// Builder admin shell — Plus Jakarta + AppDrop orange on slate.
  static const builder = AppDropOfflineStyle(
    backgroundColor: Color(0xFFF4F5F7),
    surfaceColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFFFF6A00),
    titleColor: Color(0xFF111827),
    bodyColor: Color(0xFF6B7280),
    buttonForeground: Color(0xFFFFFFFF),
    fontFamily: 'Plus Jakarta Sans',
    layout: AppDropOfflineLayout.canvas,
    appName: 'AppDrop',
    cornerRadius: 16,
  );

  /// Preview chrome before a store theme is loaded.
  static const preview = AppDropOfflineStyle(
    backgroundColor: Color(0xFFF7F8FA),
    surfaceColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFFFF6B00),
    titleColor: Color(0xFF1A202C),
    bodyColor: Color(0xFF718096),
    buttonForeground: Color(0xFFFFFFFF),
    fontFamily: 'Poppins',
    layout: AppDropOfflineLayout.stacked,
    appName: 'AppDrop Preview',
    useGoogleFont: true,
  );

  /// Storefront fallback before [AppDropThemeConfig] is available.
  static AppDropOfflineStyle storefront({
    required Color accent,
    required Color background,
    required Color titleColor,
    required String appName,
    String fontFamily = 'Poppins',
  }) {
    final onAccent =
        accent.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    return AppDropOfflineStyle(
      backgroundColor: background,
      surfaceColor: background,
      accentColor: accent,
      titleColor: titleColor,
      bodyColor: titleColor.withValues(alpha: 0.55),
      buttonForeground: onAccent,
      fontFamily: fontFamily,
      layout: AppDropOfflineLayout.stacked,
      appName: appName,
      useGoogleFont: true,
    );
  }

  factory AppDropOfflineStyle.fromThemeConfig(
    AppDropThemeConfig config, {
    required String appName,
  }) {
    final styling = config.appStyling;
    var accent = styling.defaultColor;
    if (accent == Colors.transparent) {
      final pb = config.productBlock;
      accent = _parseHex(pb['filled_button_bg']?.toString()) ??
          styling.bottomSelected;
    }
    if (accent == Colors.transparent) {
      accent = const Color(0xFF54A685);
    }
    final onAccent =
        accent.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    final title = styling.fontIconColor;
    return AppDropOfflineStyle(
      backgroundColor: styling.bgColor,
      surfaceColor: styling.bgColor,
      accentColor: accent,
      titleColor: title,
      bodyColor: title.withValues(alpha: 0.55),
      buttonForeground: onAccent,
      fontFamily: styling.fontFamily,
      layout: AppDropOfflineLayout.stacked,
      appName: appName,
      cornerRadius: 12,
      useGoogleFont: true,
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    var s = hex.trim().replaceAll('#', '');
    if (s.isEmpty) return null;
    if (s.length == 3) {
      s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
    }
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }
}

/// Full-screen premium offline notice that keeps [child] mounted underneath.
class AppDropOfflineGate extends StatefulWidget {
  const AppDropOfflineGate({
    super.key,
    required this.child,
    this.style,
    this.styleBuilder,
    this.onRetry,
    this.onConnectionRestored,
  });

  final Widget child;
  final AppDropOfflineStyle? style;
  final AppDropOfflineStyle Function(BuildContext context)? styleBuilder;
  final Future<void> Function()? onRetry;
  final VoidCallback? onConnectionRestored;

  @override
  State<AppDropOfflineGate> createState() => _AppDropOfflineGateState();
}

class _AppDropOfflineGateState extends State<AppDropOfflineGate> {
  final AppDropConnectivity _connectivity = AppDropConnectivity.instance;
  bool _retrying = false;
  bool _wasOnline = true;

  @override
  void initState() {
    super.initState();
    _wasOnline = _connectivity.isOnline;
    _connectivity.addListener(_onConnectivity);
    unawaited(_connectivity.ensureStarted());
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivity);
    super.dispose();
  }

  void _onConnectivity() {
    final online = _connectivity.isOnline;
    if (!_wasOnline && online) {
      widget.onConnectionRestored?.call();
    }
    _wasOnline = online;
    if (mounted) setState(() {});
  }

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final custom = widget.onRetry;
      if (custom != null) {
        await custom();
      } else {
        await _connectivity.refresh();
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = _connectivity.isOnline;
    final style = widget.styleBuilder?.call(context) ??
        widget.style ??
        AppDropOfflineStyle.preview;

    return Stack(
      children: [
        widget.child,
        if (!online)
          Positioned.fill(
            child: _AppDropOfflineNotice(
              style: style,
              retrying: _retrying,
              onRetry: _handleRetry,
            ),
          ),
      ],
    );
  }
}

class _AppDropOfflineNotice extends StatelessWidget {
  const _AppDropOfflineNotice({
    required this.style,
    required this.retrying,
    required this.onRetry,
  });

  final AppDropOfflineStyle style;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final content = _OfflineBody(
      style: style,
      retrying: retrying,
      onRetry: onRetry,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Material(
      color: style.backgroundColor,
      child: Stack(
        children: [
          if (style.layout == AppDropOfflineLayout.canvas) ...[
            Positioned(
              top: -80,
              right: -60,
              child: _Glow(color: style.accentColor, size: 280),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _Glow(
                color: style.accentColor.withValues(alpha: 0.07),
                size: 320,
              ),
            ),
          ],
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: style.layout == AppDropOfflineLayout.canvas
                      ? 24
                      : 32,
                  vertical: 32,
                ),
                child: style.layout == AppDropOfflineLayout.canvas
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: style.surfaceColor,
                            borderRadius:
                                BorderRadius.circular(style.cornerRadius),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                            child: content,
                          ),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: content,
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _OfflineBody extends StatelessWidget {
  const _OfflineBody({
    required this.style,
    required this.retrying,
    required this.onRetry,
  });

  final AppDropOfflineStyle style;
  final bool retrying;
  final VoidCallback onRetry;

  TextStyle _text({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.35,
    double letterSpacing = 0,
  }) {
    final base = TextStyle(
      fontFamily: style.fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    if (!style.useGoogleFont) return base;
    return AppDropThemeData.textStyle(
      fontFamily: style.fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ).copyWith(height: height, letterSpacing: letterSpacing);
  }

  @override
  Widget build(BuildContext context) {
    final isCanvas = style.layout == AppDropOfflineLayout.canvas;
    final titleSize = isCanvas ? 26.0 : 22.0;
    final mark = _WifiMark(accent: style.accentColor, compact: !isCanvas);

    return Semantics(
      container: true,
      liveRegion: true,
      label: "${style.title}. ${style.resolvedSubtitle}",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(height: isCanvas ? 28 : 24),
          Text(
            'NO CONNECTION',
            textAlign: TextAlign.center,
            style: _text(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.accentColor,
              letterSpacing: 1.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            style.title,
            textAlign: TextAlign.center,
            style: _text(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: style.titleColor,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            style.resolvedSubtitle,
            textAlign: TextAlign.center,
            style: _text(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: style.bodyColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _RetryButton(
            style: style,
            retrying: retrying,
            onRetry: onRetry,
            textStyle: _text(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: style.buttonForeground,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.style,
    required this.retrying,
    required this.onRetry,
    required this.textStyle,
  });

  final AppDropOfflineStyle style;
  final bool retrying;
  final VoidCallback onRetry;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !retrying,
      label: style.actionLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180, minHeight: 48),
        child: Material(
          color: style.accentColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: retrying ? null : onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (retrying)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: style.buttonForeground,
                      ),
                    )
                  else
                    Icon(
                      FluentIcons.arrow_sync_24_regular,
                      size: 18,
                      color: style.buttonForeground,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    retrying ? 'Checking…' : style.actionLabel,
                    style: textStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WifiMark extends StatelessWidget {
  const _WifiMark({required this.accent, required this.compact});

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disc = compact ? 72.0 : 80.0;
    final halo = disc + (compact ? 28.0 : 32.0);
    return SizedBox(
      width: halo,
      height: halo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.14),
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(
              FluentIcons.wifi_off_24_regular,
              size: compact ? 32 : 36,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.10),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
