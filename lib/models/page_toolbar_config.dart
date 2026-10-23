import '../utils/toolbar_icons.dart';

/// Per-page app bar layout for storefront preview and builder.
///
/// Values are stable string ids for JSON persistence.
class PageToolbarConfig {
  /// Leading: [ToolbarLeft.none], [ToolbarLeft.sideNavigation], [ToolbarLeft.back].
  final String left;

  /// Center: home/custom — [ToolbarCenter.text], [ToolbarCenter.logo].
  /// PLP also allows [ToolbarCenter.collectionSearch].
  final String center;

  /// Shown when [center] is [ToolbarCenter.text].
  final String centerText;

  /// Image URL when [center] is [ToolbarCenter.logo].
  final String centerLogoUrl;

  /// Title / logo placement: [ToolbarTitleAlignment.center] or
  /// [ToolbarTitleAlignment.left].
  final String titleAlignment;

  /// Trailing actions (inner → outer). Each: [ToolbarRight.none], [ToolbarRight.cart], etc.
  final String rightSlot1;
  final String rightSlot2;
  final String rightSlot3;

  /// Optional glyph override (see [ToolbarGlyph]). Empty = default for the action.
  final String leftIcon;
  final String rightSlot1Icon;
  final String rightSlot2Icon;
  final String rightSlot3Icon;

  /// Optional SVG (or tinted PNG) URL. Non-empty takes precedence over the glyph.
  final String leftIconUrl;
  final String rightSlot1IconUrl;
  final String rightSlot2IconUrl;
  final String rightSlot3IconUrl;

  /// Per-page toolbar background (`#RRGGBB`). Empty inherits global app styling.
  final String toolbarBg;

  /// Per-page toolbar foreground / icon color. Empty inherits global app styling.
  final String toolbarFont;

  /// Per-page screen background. Empty inherits global `bg_color`.
  final String screenBg;

  /// Home only: push center + right layout to every other page.
  final bool syncWithAllPages;

  /// Optional second-row search field under the title / logo row.
  final ToolbarSearchBarConfig searchBar;

  const PageToolbarConfig({
    this.left = ToolbarLeft.sideNavigation,
    this.center = ToolbarCenter.text,
    this.centerText = 'Home',
    this.centerLogoUrl = '',
    this.titleAlignment = ToolbarTitleAlignment.center,
    this.rightSlot1 = ToolbarRight.none,
    this.rightSlot2 = ToolbarRight.cart,
    this.rightSlot3 = ToolbarRight.none,
    this.leftIcon = '',
    this.rightSlot1Icon = '',
    this.rightSlot2Icon = '',
    this.rightSlot3Icon = '',
    this.leftIconUrl = '',
    this.rightSlot1IconUrl = '',
    this.rightSlot2IconUrl = '',
    this.rightSlot3IconUrl = '',
    this.toolbarBg = '',
    this.toolbarFont = '',
    this.screenBg = '',
    this.syncWithAllPages = false,
    this.searchBar = ToolbarSearchBarConfig.defaults,
  });

  static const PageToolbarConfig homeDefaults = PageToolbarConfig(
    left: ToolbarLeft.sideNavigation,
    center: ToolbarCenter.text,
    centerText: 'Home',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.cart,
    rightSlot3: ToolbarRight.none,
  );

  static const PageToolbarConfig plpDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.collectionSearch,
    centerText: '',
    rightSlot1: ToolbarRight.wishlist,
    rightSlot2: ToolbarRight.cart,
    rightSlot3: ToolbarRight.none,
  );

  /// PDP: back leading, title from scaffold, wishlist only on the trailing side.
  static const PageToolbarConfig pdpDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.wishlist,
    rightSlot2: ToolbarRight.none,
    rightSlot3: ToolbarRight.none,
  );

  /// Cart: back leading, title from page name, no trailing actions in preview.
  static const PageToolbarConfig cartDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.none,
    rightSlot3: ToolbarRight.none,
  );

  static const PageToolbarConfig wishlistDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.none,
    rightSlot3: ToolbarRight.none,
  );

  static const PageToolbarConfig searchDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.cart,
    rightSlot3: ToolbarRight.none,
  );

  bool get isTitleLeftAligned =>
      titleAlignment == ToolbarTitleAlignment.left;

  bool get showsInlineSearchBar => searchBar.visible;

  bool get hasRightSideNavigation =>
      rightSlot1 == ToolbarRight.sideNavigation ||
      rightSlot2 == ToolbarRight.sideNavigation ||
      rightSlot3 == ToolbarRight.sideNavigation;

  /// Sets title / logo alignment independently of left-panel icons.
  PageToolbarConfig withTitleAlignment(String value) {
    final align = value == ToolbarTitleAlignment.left
        ? ToolbarTitleAlignment.left
        : ToolbarTitleAlignment.center;
    return copyWith(titleAlignment: align);
  }

  /// Dropdown choices for a right slot: [ToolbarRight.none] plus values not
  /// already used in the other slots. The slot's current value always remains.
  List<String> rightSlotChoicesFor(int index) {
    final String current;
    if (index == 1) {
      current = rightSlot1;
    } else if (index == 2) {
      current = rightSlot2;
    } else {
      current = rightSlot3;
    }
    final taken = <String>{};
    if (index != 1) taken.add(rightSlot1);
    if (index != 2) taken.add(rightSlot2);
    if (index != 3) taken.add(rightSlot3);
    taken.remove(ToolbarRight.none);
    taken.remove(current);
    return [
      for (final c in ToolbarRight.slotChoices)
        if (c == ToolbarRight.none || c == current || !taken.contains(c)) c,
    ];
  }

  PageToolbarConfig withLeftControl(String value) {
    if (value == ToolbarLeft.sideNavigation) {
      return copyWith(
        left: value,
        leftIcon: '',
        leftIconUrl: '',
        titleAlignment: ToolbarTitleAlignment.center,
        rightSlot1: _clearNav(rightSlot1),
        rightSlot2: _clearNav(rightSlot2),
        rightSlot3: _clearNav(rightSlot3),
      );
    }
    if (value == ToolbarLeft.none) {
      return copyWith(left: value, leftIcon: '', leftIconUrl: '');
    }
    return copyWith(left: value, leftIcon: '', leftIconUrl: '');
  }

  /// Sets a trailing slot. Picking [ToolbarRight.sideNavigation] clears it
  /// from [left] and the other right slots so only one menu icon remains.
  PageToolbarConfig withRightSlot(int index, String value) {
    var s1 = rightSlot1;
    var s2 = rightSlot2;
    var s3 = rightSlot3;
    if (index == 1) s1 = value;
    if (index == 2) s2 = value;
    if (index == 3) s3 = value;
    if (value == ToolbarRight.sideNavigation) {
      if (index != 1) s1 = _clearNav(s1);
      if (index != 2) s2 = _clearNav(s2);
      if (index != 3) s3 = _clearNav(s3);
      return copyWith(
        left: left == ToolbarLeft.sideNavigation ? ToolbarLeft.none : left,
        leftIcon: left == ToolbarLeft.sideNavigation ? '' : leftIcon,
        leftIconUrl: left == ToolbarLeft.sideNavigation ? '' : leftIconUrl,
        rightSlot1: s1,
        rightSlot2: s2,
        rightSlot3: s3,
        rightSlot1Icon: index == 1 ? '' : rightSlot1Icon,
        rightSlot1IconUrl: index == 1 ? '' : rightSlot1IconUrl,
        rightSlot2Icon: index == 2 ? '' : rightSlot2Icon,
        rightSlot2IconUrl: index == 2 ? '' : rightSlot2IconUrl,
        rightSlot3Icon: index == 3 ? '' : rightSlot3Icon,
        rightSlot3IconUrl: index == 3 ? '' : rightSlot3IconUrl,
      );
    }
    return copyWith(
      rightSlot1: s1,
      rightSlot2: s2,
      rightSlot3: s3,
      rightSlot1Icon: index == 1 ? '' : rightSlot1Icon,
      rightSlot1IconUrl: index == 1 ? '' : rightSlot1IconUrl,
      rightSlot2Icon: index == 2 ? '' : rightSlot2Icon,
      rightSlot2IconUrl: index == 2 ? '' : rightSlot2IconUrl,
      rightSlot3Icon: index == 3 ? '' : rightSlot3Icon,
      rightSlot3IconUrl: index == 3 ? '' : rightSlot3IconUrl,
    );
  }

  PageToolbarConfig copyWith({
    String? left,
    String? center,
    String? centerText,
    String? centerLogoUrl,
    String? titleAlignment,
    String? rightSlot1,
    String? rightSlot2,
    String? rightSlot3,
    String? leftIcon,
    String? rightSlot1Icon,
    String? rightSlot2Icon,
    String? rightSlot3Icon,
    String? leftIconUrl,
    String? rightSlot1IconUrl,
    String? rightSlot2IconUrl,
    String? rightSlot3IconUrl,
    String? toolbarBg,
    String? toolbarFont,
    String? screenBg,
    bool? syncWithAllPages,
    ToolbarSearchBarConfig? searchBar,
  }) {
    return PageToolbarConfig(
      left: left ?? this.left,
      center: center ?? this.center,
      centerText: centerText ?? this.centerText,
      centerLogoUrl: centerLogoUrl ?? this.centerLogoUrl,
      titleAlignment: titleAlignment ?? this.titleAlignment,
      rightSlot1: rightSlot1 ?? this.rightSlot1,
      rightSlot2: rightSlot2 ?? this.rightSlot2,
      rightSlot3: rightSlot3 ?? this.rightSlot3,
      leftIcon: leftIcon ?? this.leftIcon,
      rightSlot1Icon: rightSlot1Icon ?? this.rightSlot1Icon,
      rightSlot2Icon: rightSlot2Icon ?? this.rightSlot2Icon,
      rightSlot3Icon: rightSlot3Icon ?? this.rightSlot3Icon,
      leftIconUrl: leftIconUrl ?? this.leftIconUrl,
      rightSlot1IconUrl: rightSlot1IconUrl ?? this.rightSlot1IconUrl,
      rightSlot2IconUrl: rightSlot2IconUrl ?? this.rightSlot2IconUrl,
      rightSlot3IconUrl: rightSlot3IconUrl ?? this.rightSlot3IconUrl,
      toolbarBg: toolbarBg ?? this.toolbarBg,
      toolbarFont: toolbarFont ?? this.toolbarFont,
      screenBg: screenBg ?? this.screenBg,
      syncWithAllPages: syncWithAllPages ?? this.syncWithAllPages,
      searchBar: searchBar ?? this.searchBar,
    );
  }

  /// Copies homepage center + right slots onto this page (keeps left, colors, visibility).
  PageToolbarConfig withSyncedLayoutFrom(PageToolbarConfig source) {
    return copyWith(
      center: source.center,
      centerText: source.centerText,
      centerLogoUrl: source.centerLogoUrl,
      titleAlignment: source.titleAlignment,
      rightSlot1: source.rightSlot1,
      rightSlot2: source.rightSlot2,
      rightSlot3: source.rightSlot3,
      rightSlot1Icon: source.rightSlot1Icon,
      rightSlot2Icon: source.rightSlot2Icon,
      rightSlot3Icon: source.rightSlot3Icon,
      rightSlot1IconUrl: source.rightSlot1IconUrl,
      rightSlot2IconUrl: source.rightSlot2IconUrl,
      rightSlot3IconUrl: source.rightSlot3IconUrl,
      searchBar: source.searchBar,
      syncWithAllPages: false,
    );
  }

  bool sameLayoutAs(PageToolbarConfig other) {
    return center == other.center &&
        centerText == other.centerText &&
        centerLogoUrl == other.centerLogoUrl &&
        titleAlignment == other.titleAlignment &&
        rightSlot1 == other.rightSlot1 &&
        rightSlot2 == other.rightSlot2 &&
        rightSlot3 == other.rightSlot3 &&
        rightSlot1Icon == other.rightSlot1Icon &&
        rightSlot2Icon == other.rightSlot2Icon &&
        rightSlot3Icon == other.rightSlot3Icon &&
        rightSlot1IconUrl == other.rightSlot1IconUrl &&
        rightSlot2IconUrl == other.rightSlot2IconUrl &&
        rightSlot3IconUrl == other.rightSlot3IconUrl &&
        searchBar == other.searchBar;
  }

  /// Cache key for per-page color overlays (empty = inherit global styling).
  String get appearanceCacheKey => '$toolbarBg|$toolbarFont|$screenBg';

  Map<String, dynamic> toJson() => {
        'left': left,
        'center': center,
        'centerText': centerText,
        'centerLogoUrl': centerLogoUrl,
        'titleAlignment': titleAlignment,
        'rightSlot1': rightSlot1,
        'rightSlot2': rightSlot2,
        'rightSlot3': rightSlot3,
        'leftIcon': leftIcon,
        'rightSlot1Icon': rightSlot1Icon,
        'rightSlot2Icon': rightSlot2Icon,
        'rightSlot3Icon': rightSlot3Icon,
        'leftIconUrl': leftIconUrl,
        'rightSlot1IconUrl': rightSlot1IconUrl,
        'rightSlot2IconUrl': rightSlot2IconUrl,
        'rightSlot3IconUrl': rightSlot3IconUrl,
        'toolbarBg': toolbarBg,
        'toolbarFont': toolbarFont,
        'screenBg': screenBg,
        'syncWithAllPages': syncWithAllPages,
        'searchBar': searchBar.toJson(),
      };

  /// Stored user overrides; `null` means “use defaults for page type”.
  static PageToolbarConfig? decode(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final logoUrl = json['centerLogoUrl'] as String? ?? '';
    final rawCenter = json['center'] as String? ?? ToolbarCenter.text;
    final legacyCenterSearch = rawCenter == ToolbarCenter.searchBar;
    final center = legacyCenterSearch
        ? (logoUrl.trim().isNotEmpty ? ToolbarCenter.logo : ToolbarCenter.text)
        : rawCenter;
    final nested = ToolbarSearchBarConfig.fromJson(
      _mapFromJson(json['searchBar'] ?? json['search_bar']),
    );
    final showSearch = nested.visible ||
        legacyCenterSearch ||
        _boolFromJson(json['showSearchBar'] ?? json['show_search_bar']);
    return PageToolbarConfig(
      left: json['left'] as String? ?? ToolbarLeft.sideNavigation,
      center: center,
      centerText: json['centerText'] as String? ?? 'Home',
      centerLogoUrl: logoUrl,
      titleAlignment: _titleAlignmentFromJson(json['titleAlignment']),
      rightSlot1: json['rightSlot1'] as String? ?? ToolbarRight.none,
      rightSlot2: json['rightSlot2'] as String? ?? ToolbarRight.cart,
      rightSlot3: json['rightSlot3'] as String? ?? ToolbarRight.none,
      leftIcon: json['leftIcon'] as String? ?? '',
      rightSlot1Icon: json['rightSlot1Icon'] as String? ?? '',
      rightSlot2Icon: json['rightSlot2Icon'] as String? ?? '',
      rightSlot3Icon: json['rightSlot3Icon'] as String? ?? '',
      leftIconUrl: json['leftIconUrl'] as String? ?? '',
      rightSlot1IconUrl: json['rightSlot1IconUrl'] as String? ?? '',
      rightSlot2IconUrl: json['rightSlot2IconUrl'] as String? ?? '',
      rightSlot3IconUrl: json['rightSlot3IconUrl'] as String? ?? '',
      toolbarBg: _hexOrEmpty(json['toolbarBg'] ?? json['toolbar_bg']),
      toolbarFont: _hexOrEmpty(json['toolbarFont'] ?? json['toolbar_font']),
      screenBg: _hexOrEmpty(json['screenBg'] ?? json['screen_bg']),
      syncWithAllPages: _boolFromJson(json['syncWithAllPages']),
      searchBar: nested.copyWith(visible: showSearch),
    );
  }

  factory PageToolbarConfig.fromJson(Map<String, dynamic>? json) {
    return decode(json) ?? homeDefaults;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageToolbarConfig &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          center == other.center &&
          centerText == other.centerText &&
          centerLogoUrl == other.centerLogoUrl &&
          titleAlignment == other.titleAlignment &&
          rightSlot1 == other.rightSlot1 &&
          rightSlot2 == other.rightSlot2 &&
          rightSlot3 == other.rightSlot3 &&
          leftIcon == other.leftIcon &&
          rightSlot1Icon == other.rightSlot1Icon &&
          rightSlot2Icon == other.rightSlot2Icon &&
          rightSlot3Icon == other.rightSlot3Icon &&
          leftIconUrl == other.leftIconUrl &&
          rightSlot1IconUrl == other.rightSlot1IconUrl &&
          rightSlot2IconUrl == other.rightSlot2IconUrl &&
          rightSlot3IconUrl == other.rightSlot3IconUrl &&
          toolbarBg == other.toolbarBg &&
          toolbarFont == other.toolbarFont &&
          screenBg == other.screenBg &&
          syncWithAllPages == other.syncWithAllPages &&
          searchBar == other.searchBar;

  @override
  int get hashCode => Object.hash(
        left,
        center,
        centerText,
        centerLogoUrl,
        titleAlignment,
        rightSlot1,
        rightSlot2,
        rightSlot3,
        leftIcon,
        rightSlot1Icon,
        rightSlot2Icon,
        Object.hash(
          rightSlot3Icon,
          leftIconUrl,
          rightSlot1IconUrl,
          rightSlot2IconUrl,
          rightSlot3IconUrl,
          toolbarBg,
          toolbarFont,
          screenBg,
          syncWithAllPages,
          searchBar,
        ),
      );

  String resolvedLeftGlyph() {
    if (leftIcon.isNotEmpty) return leftIcon;
    return ToolbarGlyph.defaultForAction(left);
  }

  String resolvedRightGlyph(int index) {
    String custom;
    if (index == 1) {
      custom = rightSlot1Icon;
    } else if (index == 2) {
      custom = rightSlot2Icon;
    } else {
      custom = rightSlot3Icon;
    }
    if (custom.isNotEmpty) return custom;
    String action;
    if (index == 1) {
      action = rightSlot1;
    } else if (index == 2) {
      action = rightSlot2;
    } else {
      action = rightSlot3;
    }
    return ToolbarGlyph.defaultForAction(action);
  }

  String resolvedLeftIconUrl() => leftIconUrl.trim();

  String resolvedRightIconUrl(int index) {
    if (index == 1) return rightSlot1IconUrl.trim();
    if (index == 2) return rightSlot2IconUrl.trim();
    return rightSlot3IconUrl.trim();
  }

  PageToolbarConfig withSearchVisual({required String glyph, String url = ''}) {
    return copyWith(
      searchBar: searchBar.copyWith(icon: glyph, iconUrl: url),
    );
  }

  PageToolbarConfig withLeftVisual({required String glyph, String url = ''}) {
    return copyWith(leftIcon: glyph, leftIconUrl: url);
  }

  PageToolbarConfig withRightVisual(
    int index, {
    required String glyph,
    String url = '',
  }) {
    switch (index) {
      case 1:
        return copyWith(rightSlot1Icon: glyph, rightSlot1IconUrl: url);
      case 2:
        return copyWith(rightSlot2Icon: glyph, rightSlot2IconUrl: url);
      default:
        return copyWith(rightSlot3Icon: glyph, rightSlot3IconUrl: url);
    }
  }
}

String _clearNav(String slot) =>
    slot == ToolbarRight.sideNavigation ? ToolbarRight.none : slot;

String _titleAlignmentFromJson(dynamic raw) {
  final v = raw?.toString().trim().toLowerCase() ?? '';
  if (v == ToolbarTitleAlignment.left) return ToolbarTitleAlignment.left;
  return ToolbarTitleAlignment.center;
}

String _hexOrEmpty(dynamic raw) {
  if (raw == null) return '';
  final s = raw.toString().trim();
  if (s.isEmpty) return '';
  return s.startsWith('#') ? s : '#$s';
}

bool _boolFromJson(dynamic raw) {
  if (raw is bool) return raw;
  final s = raw?.toString().trim().toLowerCase() ?? '';
  return s == 'true' || s == '1';
}

Map<String, dynamic>? _mapFromJson(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

double? _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

abstract class ToolbarLeft {
  static const none = 'none';
  static const sideNavigation = 'side_navigation';
  static const back = 'back';
}

abstract class ToolbarCenter {
  static const none = 'none';
  static const text = 'text';
  static const logo = 'logo';
  static const collectionSearch = 'collection_search';

  /// Legacy center id. Decoded as [ToolbarSearchBarConfig.visible] instead.
  static const searchBar = 'search_bar';
}

abstract class ToolbarTitleAlignment {
  static const left = 'left';
  static const center = 'center';
}

abstract class ToolbarRight {
  static const none = 'none';
  static const cart = 'cart';
  static const wishlist = 'wishlist';
  static const search = 'search';
  static const sideNavigation = 'side_navigation';

  static const slotChoices = <String>[
    none,
    wishlist,
    cart,
    search,
    sideNavigation,
  ];
}

const String kToolbarSearchDefaultHint = 'What are you looking for?';
const double kToolbarSearchDefaultCornerRadius = 8;
const String kToolbarSearchDefaultBg = '#FFFFFF';
const String kToolbarSearchDefaultBorderColor = '#E5E7EB';
const String kToolbarSearchDefaultHintColor = '#9CA3AF';

/// Style for the second-row toolbar search field.
class ToolbarSearchBarConfig {
  const ToolbarSearchBarConfig({
    this.visible = false,
    this.hintText = kToolbarSearchDefaultHint,
    this.cornerRadius = kToolbarSearchDefaultCornerRadius,
    this.backgroundColor = kToolbarSearchDefaultBg,
    this.borderColor = kToolbarSearchDefaultBorderColor,
    this.iconColor = '',
    this.hintColor = kToolbarSearchDefaultHintColor,
    this.icon = ToolbarGlyph.search,
    this.iconUrl = '',
  });

  static const defaults = ToolbarSearchBarConfig();

  /// When true, the search field sits under the title / logo row.
  final bool visible;
  final String hintText;
  final double cornerRadius;
  final String backgroundColor;
  final String borderColor;

  /// Filled suffix-button color. Empty inherits the theme accent.
  final String iconColor;
  final String hintColor;
  final String icon;
  final String iconUrl;

  String get resolvedHint {
    final t = hintText.trim();
    return t.isEmpty ? kToolbarSearchDefaultHint : t;
  }

  String get resolvedIcon {
    final g = icon.trim();
    return g.isEmpty ? ToolbarGlyph.search : g;
  }

  String get resolvedIconUrl => iconUrl.trim();

  ToolbarSearchBarConfig copyWith({
    bool? visible,
    String? hintText,
    double? cornerRadius,
    String? backgroundColor,
    String? borderColor,
    String? iconColor,
    String? hintColor,
    String? icon,
    String? iconUrl,
  }) {
    return ToolbarSearchBarConfig(
      visible: visible ?? this.visible,
      hintText: hintText ?? this.hintText,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      iconColor: iconColor ?? this.iconColor,
      hintColor: hintColor ?? this.hintColor,
      icon: icon ?? this.icon,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'visible': visible,
        'hintText': hintText,
        'cornerRadius': cornerRadius,
        'backgroundColor': backgroundColor,
        'borderColor': borderColor,
        'iconColor': iconColor,
        'hintColor': hintColor,
        'icon': icon,
        'iconUrl': iconUrl,
      };

  factory ToolbarSearchBarConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return defaults;
    final hint =
        (json['hintText'] ?? json['hint_text'] ?? '').toString().trim();
    final bg = _hexOrEmpty(
      json['backgroundColor'] ?? json['background_color'],
    );
    final borderColor = _hexOrEmpty(json['borderColor'] ?? json['border_color']);
    final hintColor = _hexOrEmpty(json['hintColor'] ?? json['hint_color']);
    final icon = (json['icon'] ?? json['glyph'] ?? '').toString().trim();
    final radius = _readDouble(
          json['cornerRadius'] ?? json['corner_radius'] ?? json['borderRadius'],
        )?.clamp(0, 24).toDouble() ??
        kToolbarSearchDefaultCornerRadius;
    return ToolbarSearchBarConfig(
      visible: _boolFromJson(json['visible']),
      hintText: hint.isEmpty ? kToolbarSearchDefaultHint : hint,
      cornerRadius: radius,
      backgroundColor: bg.isEmpty ? kToolbarSearchDefaultBg : bg,
      borderColor:
          borderColor.isEmpty ? kToolbarSearchDefaultBorderColor : borderColor,
      iconColor: _hexOrEmpty(json['iconColor'] ?? json['icon_color']),
      hintColor: hintColor.isEmpty ? kToolbarSearchDefaultHintColor : hintColor,
      icon: icon.isEmpty ? ToolbarGlyph.search : icon,
      iconUrl: (json['iconUrl'] ?? json['icon_url'] ?? '').toString().trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolbarSearchBarConfig &&
          runtimeType == other.runtimeType &&
          visible == other.visible &&
          hintText == other.hintText &&
          cornerRadius == other.cornerRadius &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          iconColor == other.iconColor &&
          hintColor == other.hintColor &&
          icon == other.icon &&
          iconUrl == other.iconUrl;

  @override
  int get hashCode => Object.hash(
        visible,
        hintText,
        cornerRadius,
        backgroundColor,
        borderColor,
        iconColor,
        hintColor,
        icon,
        iconUrl,
      );
}
