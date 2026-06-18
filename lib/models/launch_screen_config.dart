/// Reference shortest side used by the builder iPhone preview frame (330 logical px).
const double kLaunchScreenLogoReferenceShortestSide = 330;

class LaunchScreenAppIcon {
  const LaunchScreenAppIcon({
    required this.enabled,
    this.logoUrl,
    this.logoSize = 'medium',
  });

  final bool enabled;
  final String? logoUrl;
  final String logoSize;

  /// Logo edge length at [kLaunchScreenLogoReferenceShortestSide] (builder preview baseline).
  static double baseLogoDimension(String logoSize) {
    switch (logoSize.trim().toLowerCase()) {
      case 'small':
        return 175;
      case 'large':
        return 250;
      default:
        return 200;
    }
  }

  /// Scales logo size proportionally to the device/preview shortest side.
  double logoDimensionForShortestSide(double shortestSide) {
    if (shortestSide <= 0) return baseLogoDimension(logoSize);
    return baseLogoDimension(logoSize) *
        (shortestSide / kLaunchScreenLogoReferenceShortestSide);
  }

  factory LaunchScreenAppIcon.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LaunchScreenAppIcon(enabled: false);
    return LaunchScreenAppIcon(
      enabled: json['enabled'] == true,
      logoUrl: json['logo_url']?.toString(),
      logoSize: json['logo_size']?.toString() ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'logo_url': enabled ? logoUrl : null,
        'logo_size': logoSize,
      };

  /// Logo size at the builder preview reference width (330 logical px).
  double get logoDimension => baseLogoDimension(logoSize);
}

class LaunchScreenBackground {
  const LaunchScreenBackground({
    required this.enabled,
    this.mode = 'color',
    this.color = '#FFFFFF',
    this.imageUrl,
  });

  final bool enabled;
  final String mode;
  final String color;
  final String? imageUrl;

  factory LaunchScreenBackground.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LaunchScreenBackground(enabled: true);
    }
    return LaunchScreenBackground(
      enabled: json['enabled'] == true,
      mode: json['mode']?.toString() ?? 'color',
      color: json['color']?.toString() ?? '#FFFFFF',
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'mode': mode,
        'color': color,
        'image_url': mode == 'image' ? imageUrl : null,
      };
}

class LaunchScreenLoader {
  const LaunchScreenLoader({
    required this.enabled,
    this.color = '#FF6B00',
  });

  final bool enabled;
  final String color;

  factory LaunchScreenLoader.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LaunchScreenLoader(enabled: false);
    return LaunchScreenLoader(
      enabled: json['enabled'] == true,
      color: json['color']?.toString() ?? '#FF6B00',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'color': color,
      };
}

class LaunchScreenConfig {
  const LaunchScreenConfig({
    required this.appIcon,
    required this.background,
    required this.loader,
    this.updatedAt,
  });

  final LaunchScreenAppIcon appIcon;
  final LaunchScreenBackground background;
  final LaunchScreenLoader loader;
  final String? updatedAt;

  factory LaunchScreenConfig.fromJson(Map<String, dynamic> json) {
    return LaunchScreenConfig(
      appIcon: LaunchScreenAppIcon.fromJson(
        json['app_icon'] is Map
            ? Map<String, dynamic>.from(json['app_icon'] as Map)
            : null,
      ),
      background: LaunchScreenBackground.fromJson(
        json['background'] is Map
            ? Map<String, dynamic>.from(json['background'] as Map)
            : null,
      ),
      loader: LaunchScreenLoader.fromJson(
        json['loader'] is Map
            ? Map<String, dynamic>.from(json['loader'] as Map)
            : null,
      ),
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'app_icon': appIcon.toJson(),
        'background': background.toJson(),
        'loader': loader.toJson(),
      };

  static LaunchScreenConfig get defaults => const LaunchScreenConfig(
        appIcon: LaunchScreenAppIcon(enabled: true, logoSize: 'medium'),
        background: LaunchScreenBackground(enabled: true),
        loader: LaunchScreenLoader(enabled: true),
      );

  static LaunchScreenConfig? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    try {
      final root = Map<String, dynamic>.from(raw);
      final normalized = _extractPayload(root);
      return LaunchScreenConfig.fromJson(normalized);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> root) {
    if (root.containsKey('app_icon') ||
        root.containsKey('background') ||
        root.containsKey('loader')) {
      return root;
    }

    final data = root['data'];
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      if (m.containsKey('app_icon') ||
          m.containsKey('background') ||
          m.containsKey('loader')) {
        return m;
      }
      final nested = m['launch_screen'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }

    final nested = root['launch_screen'];
    if (nested is Map) return Map<String, dynamic>.from(nested);

    return root;
  }
}
