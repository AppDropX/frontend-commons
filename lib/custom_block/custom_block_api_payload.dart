/// Parsed custom-block content from dashboard or mobile API responses.
class CustomBlockApiPayload {
  const CustomBlockApiPayload({
    required this.id,
    required this.title,
    required this.html,
    required this.css,
    required this.js,
    required this.displayMode,
  });

  final String id;
  final String title;
  final String html;
  final String css;
  final String js;
  final String displayMode;

  static Map<String, dynamic> detailPayloadFromApiResponse(dynamic decoded) {
    if (decoded is! Map) return {};
    final root = Map<String, dynamic>.from(decoded);
    final data = root['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final nested = dataMap['block'] ?? dataMap['custom_block'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return dataMap;
    }
    final block = root['block'] ?? root['custom_block'];
    if (block is Map) return Map<String, dynamic>.from(block);
    return root;
  }

  static List<Map<String, dynamic>> listItemMapsFromApiResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is! Map) return const [];

    final root = Map<String, dynamic>.from(decoded);
    final candidates = <dynamic>[
      root['items'],
      root['blocks'],
      (root['data'] is Map)
          ? (root['data'] as Map)['items']
          : null,
      (root['data'] is Map)
          ? (root['data'] as Map)['blocks']
          : null,
      root['data'],
    ];
    for (final c in candidates) {
      if (c is List) {
        return c
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  static CustomBlockApiPayload? findByIdInListResponse(
    dynamic decoded,
    String blockId,
  ) {
    final target = blockId.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final item in listItemMapsFromApiResponse(decoded)) {
      final parsed = fromDetailApiJson(item);
      if (parsed != null && parsed.id.toLowerCase() == target) return parsed;
    }
    return null;
  }

  static CustomBlockApiPayload? parseApiResponse(dynamic decoded) {
    final payload = detailPayloadFromApiResponse(decoded);
    if (payload.isEmpty) return null;
    return fromDetailApiJson(payload);
  }

  static CustomBlockApiPayload? fromDetailApiJson(Map<String, dynamic> json) {
    final flat = _flattenCustomBlockApiJson(json);

    var id = (flat['id'] ?? '').toString();
    if (id.isEmpty) {
      for (final key in ['uuid', '_id', 'block_id']) {
        final v = flat[key]?.toString();
        if (v != null && v.isNotEmpty) {
          id = v;
          break;
        }
      }
    }
    if (id.isEmpty) return null;

    return CustomBlockApiPayload(
      id: id,
      title: (flat['name'] ?? flat['title'] ?? '').toString(),
      html: (flat['html'] ?? '').toString(),
      css: (flat['css'] ?? '').toString(),
      js: (flat['js'] ?? '').toString(),
      displayMode: (flat['display_mode'] ?? '').toString(),
    );
  }

  static Map<String, dynamic> _flattenCustomBlockApiJson(
    Map<String, dynamic> json,
  ) {
    final out = Map<String, dynamic>.from(json);

    void mergeFrom(Map<String, dynamic> src) {
      src.forEach((k, v) {
        if (v == null) return;
        final cur = out[k];
        final empty = cur == null ||
            (cur is String && cur.isEmpty) ||
            (cur is List && cur.isEmpty);
        if (empty) out[k] = v;
      });
    }

    final config = json['config'];
    if (config is Map) mergeFrom(Map<String, dynamic>.from(config));

    final attributes = json['attributes'];
    if (attributes is Map) mergeFrom(Map<String, dynamic>.from(attributes));

    final content = json['content'];
    if (content is Map) {
      final c = Map<String, dynamic>.from(content);
      for (final key in ['html', 'css', 'js']) {
        if ((out[key] ?? '').toString().isEmpty && c[key] != null) {
          out[key] = c[key];
        }
      }
    }

    return out;
  }
}
