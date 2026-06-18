/// Per-page app bar layout for storefront preview and builder.
///
/// Values are stable string ids for JSON persistence.
class PageToolbarConfig {
  /// Leading: [ToolbarLeft.none], [ToolbarLeft.sideNavigation], [ToolbarLeft.back].
  final String left;

  /// Center: home/custom — [ToolbarCenter.text], [ToolbarCenter.logo] (reserved).
  /// PLP — [ToolbarCenter.collectionSearch].
  final String center;

  /// Shown when [center] is [ToolbarCenter.text].
  final String centerText;

  /// Image URL when [center] is [ToolbarCenter.logo].
  final String centerLogoUrl;

  /// Trailing actions (inner → outer). Each: [ToolbarRight.none], [ToolbarRight.cart], etc.
  final String rightSlot1;
  final String rightSlot2;

  const PageToolbarConfig({
    this.left = ToolbarLeft.sideNavigation,
    this.center = ToolbarCenter.text,
    this.centerText = 'Home',
    this.centerLogoUrl = '',
    this.rightSlot1 = ToolbarRight.none,
    this.rightSlot2 = ToolbarRight.cart,
  });

  static const PageToolbarConfig homeDefaults = PageToolbarConfig(
    left: ToolbarLeft.sideNavigation,
    center: ToolbarCenter.text,
    centerText: 'Home',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.cart,
  );

  static const PageToolbarConfig plpDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.collectionSearch,
    centerText: '',
    rightSlot1: ToolbarRight.wishlist,
    rightSlot2: ToolbarRight.cart,
  );

  /// PDP: back leading, title from scaffold, wishlist only on the trailing side.
  static const PageToolbarConfig pdpDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.wishlist,
    rightSlot2: ToolbarRight.none,
  );

  /// Cart: back leading, title from page name, no trailing actions in preview.
  static const PageToolbarConfig cartDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.none,
  );

  static const PageToolbarConfig wishlistDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.none,
  );

  static const PageToolbarConfig searchDefaults = PageToolbarConfig(
    left: ToolbarLeft.back,
    center: ToolbarCenter.text,
    centerText: '',
    rightSlot1: ToolbarRight.none,
    rightSlot2: ToolbarRight.cart,
  );

  PageToolbarConfig copyWith({
    String? left,
    String? center,
    String? centerText,
    String? centerLogoUrl,
    String? rightSlot1,
    String? rightSlot2,
  }) {
    return PageToolbarConfig(
      left: left ?? this.left,
      center: center ?? this.center,
      centerText: centerText ?? this.centerText,
      centerLogoUrl: centerLogoUrl ?? this.centerLogoUrl,
      rightSlot1: rightSlot1 ?? this.rightSlot1,
      rightSlot2: rightSlot2 ?? this.rightSlot2,
    );
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'center': center,
        'centerText': centerText,
        'centerLogoUrl': centerLogoUrl,
        'rightSlot1': rightSlot1,
        'rightSlot2': rightSlot2,
      };

  /// Stored user overrides; `null` means “use defaults for page type”.
  static PageToolbarConfig? decode(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    return PageToolbarConfig(
      left: json['left'] as String? ?? ToolbarLeft.sideNavigation,
      center: json['center'] as String? ?? ToolbarCenter.text,
      centerText: json['centerText'] as String? ?? 'Home',
      centerLogoUrl: json['centerLogoUrl'] as String? ?? '',
      rightSlot1: json['rightSlot1'] as String? ?? ToolbarRight.none,
      rightSlot2: json['rightSlot2'] as String? ?? ToolbarRight.cart,
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
          rightSlot1 == other.rightSlot1 &&
          rightSlot2 == other.rightSlot2;

  @override
  int get hashCode =>
      Object.hash(left, center, centerText, centerLogoUrl, rightSlot1, rightSlot2);
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
}

abstract class ToolbarRight {
  static const none = 'none';
  static const cart = 'cart';
  static const wishlist = 'wishlist';
  static const search = 'search';
}
