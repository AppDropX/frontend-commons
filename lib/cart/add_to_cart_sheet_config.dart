/// Options for the product-grid add-to-cart sheet.
///
/// Stored on `settings.product_block.config.add_to_cart_sheet` so the theme
/// API keeps accepting it inside the existing product block config bag.
class AddToCartSheetConfig {
  static const configKey = 'add_to_cart_sheet';

  const AddToCartSheetConfig({
    required this.presentation,
    required this.cornerRadius,
    required this.titleSize,
    required this.titleFontVariation,
    required this.titleColor,
    required this.showQuantity,
    required this.maxQuantity,
    required this.quantityHeading,
    required this.quantityStyle,
    required this.quantityStyleColor,
    required this.variant,
  });

  /// `bottom_sheet` or `popup`.
  final String presentation;

  /// Card corner radius in logical pixels. Popup uses every corner.
  /// A bottom sheet uses the top corners.
  final double cornerRadius;
  final double titleSize;

  /// `regular`, `semi_bold`, or `bold`.
  final String titleFontVariation;

  /// Empty uses the product block title color.
  final String titleColor;
  final bool showQuantity;
  final int maxQuantity;
  final String quantityHeading;

  /// `outlined` or `filled`.
  final String quantityStyle;
  final String quantityStyleColor;

  /// Same keys as the PDP product variant block.
  final Map<String, dynamic> variant;

  bool get isPopup => presentation == 'popup';

  bool get variantDropdown =>
      variantString('variantStyle', 'dropdown') == 'dropdown';

  static Map<String, dynamic> defaultVariant() => {
        'enabled': true,
        'variantStyle': 'dropdown',
        'groupTitle': '',
        'dropdownHint': 'Choose a Size',
        'dropdownUnavailableText': 'Unavailable',
        'dropdownHintFontVariation': 'regular',
        'dropdownHintSize': 14,
        'dropdownOptionFontVariation': 'regular',
        'dropdownOptionSize': 16,
        'dropdownCornerRadius': 8,
        'cornerRadius': 24,
        'backgroundColor': '#FFFFFF',
        'borderColor': '#D1D5DB',
        'innerTextColor': '#374151',
        'selectedBackgroundColor': '',
        'selectedForegroundColor': '',
        'labelColor': '#111827',
        'showRemainingStock': true,
        'remainingStockThreshold': 5,
        'remainingStockColor': '#DC2626',
        'showOutOfStockVariants': true,
      };

  factory AddToCartSheetConfig.defaults() =>
      AddToCartSheetConfig.fromJson(const {});

  factory AddToCartSheetConfig.fromProductBlock(
    Map<String, dynamic> productBlock,
  ) {
    final config = productBlock['config'];
    if (config is! Map) return AddToCartSheetConfig.defaults();
    final raw = config[configKey];
    if (raw is! Map) return AddToCartSheetConfig.defaults();
    return AddToCartSheetConfig.fromJson(Map<String, dynamic>.from(raw));
  }

  factory AddToCartSheetConfig.fromJson(Map<String, dynamic> json) {
    final variant = defaultVariant();
    final rawVariant = json['variant'];
    if (rawVariant is Map) {
      variant.addAll(Map<String, dynamic>.from(rawVariant));
    }
    final presentation = json['presentation']?.toString().trim().toLowerCase();
    final style = json['quantity_style']?.toString().trim().toLowerCase();
    return AddToCartSheetConfig(
      presentation: presentation == 'popup' ? 'popup' : 'bottom_sheet',
      cornerRadius: _double(json['corner_radius'], 16).clamp(0, 24),
      titleSize: _double(json['title_size'], 20).clamp(14, 28),
      titleFontVariation: _fontVariation(json['title_font_variation'], 'semi_bold'),
      titleColor: _optionalHex(json['title_color']),
      showQuantity: _bool(json['show_quantity'], true),
      maxQuantity: _int(json['max_quantity'], 10).clamp(1, 99),
      quantityHeading: _text(json['quantity_heading'], 'Quantity'),
      quantityStyle: style == 'filled' ? 'filled' : 'outlined',
      quantityStyleColor: _hex(json['quantity_style_color'], '#111827'),
      variant: variant,
    );
  }

  Map<String, dynamic> toJson() => {
        'presentation': isPopup ? 'popup' : 'bottom_sheet',
        'corner_radius': cornerRadius.clamp(0, 24).round(),
        'title_size': titleSize.clamp(14, 28).round(),
        'title_font_variation': titleFontVariation,
        'title_color': titleColor,
        'show_quantity': showQuantity,
        'max_quantity': maxQuantity.clamp(1, 99),
        'quantity_heading': quantityHeading,
        'quantity_style': quantityStyle == 'filled' ? 'filled' : 'outlined',
        'quantity_style_color': _hex(quantityStyleColor, '#111827'),
        'variant': Map<String, dynamic>.from(variant),
      };

  AddToCartSheetConfig copyWith({
    String? presentation,
    double? cornerRadius,
    double? titleSize,
    String? titleFontVariation,
    String? titleColor,
    bool? showQuantity,
    int? maxQuantity,
    String? quantityHeading,
    String? quantityStyle,
    String? quantityStyleColor,
    Map<String, dynamic>? variant,
  }) {
    return AddToCartSheetConfig(
      presentation: presentation ?? this.presentation,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      titleSize: titleSize ?? this.titleSize,
      titleFontVariation: titleFontVariation ?? this.titleFontVariation,
      titleColor: titleColor ?? this.titleColor,
      showQuantity: showQuantity ?? this.showQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      quantityHeading: quantityHeading ?? this.quantityHeading,
      quantityStyle: quantityStyle ?? this.quantityStyle,
      quantityStyleColor: quantityStyleColor ?? this.quantityStyleColor,
      variant: variant ?? this.variant,
    );
  }

  AddToCartSheetConfig withVariant(String key, Object? value) {
    final next = Map<String, dynamic>.from(variant);
    next[key] = value;
    return copyWith(variant: next);
  }

  String variantString(String key, String fallback) {
    final value = variant[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool variantBool(String key, bool fallback) => _bool(variant[key], fallback);

  double variantNum(String key, double fallback) {
    final value = variant[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

/// Sample product used by the theme-settings device preview.
Map<String, dynamic> addToCartSheetPreviewProduct() {
  Map<String, dynamic> size(
    String id,
    String label,
    int stock,
    num selling,
    num retail,
  ) =>
      {
        'id': id,
        'title': label,
        'price': selling,
        'compare_at_price': retail,
        'inventory_quantity': stock,
      };

  return {
    'id': 'preview-add-to-cart-sheet',
    'productId': 'preview-add-to-cart-sheet',
    'title': 'Bison Dark Brown Leather Belt',
    'sellingPrice': 4500,
    'retailPrice': 7000,
    'options': [
      {'name': 'Size'},
    ],
    'variants': [
      size('size-32', '32', 8, 4500, 7000),
      size('size-34', '34', 2, 4700, 7600),
      size('size-36', '36', 6, 5000, 8332),
      size('size-38', '38', 0, 4800, 7200),
    ],
  };
}

bool _bool(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return fallback;
}

int _int(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _text(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _double(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String _fontVariation(dynamic value, String fallback) {
  final raw = value?.toString().trim().toLowerCase() ?? '';
  if (raw == 'bold') return 'bold';
  if (raw == 'regular') return 'regular';
  if (raw == 'semi_bold' || raw == 'semibold') return 'semi_bold';
  return fallback;
}

/// Empty when the merchant has not picked a color yet.
String _optionalHex(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  return _hex(raw, '');
}

String _hex(dynamic value, String fallback) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return fallback;
  final body = raw.startsWith('#') ? raw.substring(1) : raw;
  if (body.isEmpty) return fallback;
  return '#${body.toUpperCase()}';
}
