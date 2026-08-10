import 'dart:convert';

import '../custom_block/custom_block_api_payload.dart';

/// API-safe theme link fields (`link_type`, `link_value`, `url_open_type`).
class ThemeLinkApiFields {
  const ThemeLinkApiFields({
    required this.linkType,
    this.linkValue,
    this.urlOpenType,
  });

  final String linkType;
  final String? linkValue;
  final String? urlOpenType;
}

/// UI/editor theme link fields (includes [ThemeLinkTypes.customBlock]).
class ThemeLinkUiFields {
  const ThemeLinkUiFields({
    required this.linkType,
    this.linkValue,
    this.urlOpenType,
    this.blockTitle,
    this.blockHtml,
    this.blockCss,
    this.blockJs,
  });

  final String linkType;
  final String? linkValue;
  final String? urlOpenType;
  final String? blockTitle;
  final String? blockHtml;
  final String? blockCss;
  final String? blockJs;
}

/// Canonical theme nav link types for builder UI + API encoding.
///
/// Custom blocks are stored as internal `url` deep links because the theme API
/// only accepts `system` | `collection` | `url`. Block HTML is embedded in the
/// deep-link query (`?p=`) so mobile apps can render without a catalog API.
class ThemeLinkTypes {
  ThemeLinkTypes._();

  static const system = 'system';
  static const collection = 'collection';
  static const url = 'url';

  /// Editor-only link type; API stores as internal `url` deep link.
  static const customBlock = 'custom_block';

  static const _deepLinkPrefix = 'appdrop://custom-block/';

  static bool isCustomBlock(String linkType) {
    final t = linkType.trim().toLowerCase();
    return t == customBlock || t == 'block';
  }

  static String normalize(String? linkType) {
    final raw = (linkType ?? '').trim();
    if (raw.isEmpty) return system;
    if (raw.toLowerCase() == 'block') return customBlock;
    return raw;
  }

  static String customBlockDeepLink(
    String blockId, {
    String? title,
    String? html,
    String? css,
    String? js,
  }) {
    final id = blockId.trim();
    final hasContent = (html ?? '').trim().isNotEmpty ||
        (css ?? '').trim().isNotEmpty ||
        (js ?? '').trim().isNotEmpty;
    if (!hasContent) {
      return '$_deepLinkPrefix$id';
    }
    final payload = <String, String>{
      if ((title ?? '').trim().isNotEmpty) 't': title!.trim(),
      if ((html ?? '').isNotEmpty) 'h': html!,
      if ((css ?? '').isNotEmpty) 'c': css!,
      if ((js ?? '').isNotEmpty) 'j': js!,
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return Uri(
      scheme: 'appdrop',
      host: 'custom-block',
      pathSegments: [id],
      queryParameters: {'p': encoded},
    ).toString();
  }

  static String? parseCustomBlockId(String? linkValue) {
    final v = (linkValue ?? '').trim();
    if (v.isEmpty) return null;
    try {
      final uri = Uri.parse(v);
      if (uri.scheme.toLowerCase() == 'appdrop' &&
          uri.host.toLowerCase() == 'custom-block') {
        final id = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.trim()
            : uri.path.replaceFirst('/', '').trim();
        return id.isEmpty ? null : id;
      }
    } catch (_) {}
    final lower = v.toLowerCase();
    if (lower.startsWith(_deepLinkPrefix)) {
      final rest = v.substring(_deepLinkPrefix.length);
      final id = rest.split(RegExp(r'[?#]')).first.trim();
      return id.isEmpty ? null : id;
    }
    return null;
  }

  /// Extracts embedded custom-block content from a deep link, if present.
  static CustomBlockApiPayload? parseCustomBlockPayload(String? linkValue) {
    final id = parseCustomBlockId(linkValue);
    if (id == null) return null;
    final raw = (linkValue ?? '').trim();
    if (raw.isEmpty) return null;
    try {
      final uri = Uri.parse(raw);
      final encoded = uri.queryParameters['p'];
      if (encoded == null || encoded.isEmpty) return null;
      final normalized = base64Url.normalize(encoded);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      final html = (m['h'] ?? '').toString();
      final css = (m['c'] ?? '').toString();
      final js = (m['j'] ?? '').toString();
      if (html.trim().isEmpty && css.trim().isEmpty && js.trim().isEmpty) {
        return null;
      }
      return CustomBlockApiPayload(
        id: id,
        title: (m['t'] ?? '').toString(),
        html: html,
        css: css,
        js: js,
        displayMode: 'full_screen',
      );
    } catch (_) {
      return null;
    }
  }

  /// Maps editor state to API-supported fields (`system` | `collection` | `url`).
  static ThemeLinkApiFields toApiFields({
    required String linkType,
    String? linkValue,
    String? urlOpenType,
    String? blockTitle,
    String? blockHtml,
    String? blockCss,
    String? blockJs,
  }) {
    final uiType = normalize(linkType);
    if (isCustomBlock(uiType)) {
      final id = (linkValue ?? '').trim();
      return ThemeLinkApiFields(
        linkType: url,
        linkValue: id.isEmpty
            ? null
            : customBlockDeepLink(
                id,
                title: blockTitle,
                html: blockHtml,
                css: blockCss,
                js: blockJs,
              ),
        urlOpenType: 'internal',
      );
    }
    return ThemeLinkApiFields(
      linkType: uiType,
      linkValue: linkValue,
      urlOpenType: uiType == url ? urlOpenType : null,
    );
  }

  /// Maps API JSON back to editor/runtime fields.
  static ThemeLinkUiFields fromApiFields({
    required String linkType,
    String? linkValue,
    String? urlOpenType,
  }) {
    final blockId = parseCustomBlockId(linkValue);
    if (blockId != null) {
      final payload = parseCustomBlockPayload(linkValue);
      return ThemeLinkUiFields(
        linkType: customBlock,
        linkValue: blockId,
        urlOpenType: null,
        blockTitle: payload?.title,
        blockHtml: payload?.html,
        blockCss: payload?.css,
        blockJs: payload?.js,
      );
    }
    if (isCustomBlock(linkType)) {
      return ThemeLinkUiFields(
        linkType: customBlock,
        linkValue: linkValue,
        urlOpenType: null,
      );
    }
    return ThemeLinkUiFields(
      linkType: normalize(linkType),
      linkValue: linkValue,
      urlOpenType: urlOpenType,
    );
  }

  /// Block id for navigation from either UI or API-encoded link rows.
  static String? blockIdForNavigation({
    required String linkType,
    required String linkValue,
  }) {
    final fromDeepLink = parseCustomBlockId(linkValue);
    if (fromDeepLink != null) return fromDeepLink;
    if (isCustomBlock(linkType)) {
      final id = linkValue.trim();
      return id.isEmpty ? null : id;
    }
    return null;
  }

  /// Seeds / collects custom-block payloads embedded in theme nav link rows.
  static Iterable<CustomBlockApiPayload> customBlockPayloadsInThemeSettings(
    Map<String, dynamic> themeSettings,
  ) {
    final out = <String, CustomBlockApiPayload>{};

    void scan(List<dynamic>? rows) {
      if (rows == null) return;
      for (final raw in rows) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final payload = parseCustomBlockPayload(m['link_value']?.toString());
        if (payload != null) out[payload.id] = payload;
      }
    }

    scan(themeSettings['bottom_bar'] is Map
        ? (themeSettings['bottom_bar'] as Map)['items'] as List?
        : null);
    scan(themeSettings['top_navigation'] is Map
        ? (themeSettings['top_navigation'] as Map)['tabs'] as List?
        : null);
    scan(themeSettings['side_menu'] is Map
        ? (themeSettings['side_menu'] as Map)['menu_items'] as List?
        : null);

    return out.values;
  }

  /// Collects custom-block ids referenced in theme nav link rows.
  static Iterable<String> customBlockIdsInThemeSettings(
    Map<String, dynamic> themeSettings,
  ) {
    final ids = <String>{};

    void scan(List<dynamic>? rows) {
      if (rows == null) return;
      for (final raw in rows) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final id = blockIdForNavigation(
          linkType: (m['link_type'] ?? '').toString(),
          linkValue: (m['link_value'] ?? '').toString(),
        );
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }

    scan(themeSettings['bottom_bar'] is Map
        ? (themeSettings['bottom_bar'] as Map)['items'] as List?
        : null);
    scan(themeSettings['top_navigation'] is Map
        ? (themeSettings['top_navigation'] as Map)['tabs'] as List?
        : null);
    scan(themeSettings['side_menu'] is Map
        ? (themeSettings['side_menu'] as Map)['menu_items'] as List?
        : null);

    return ids;
  }
}
