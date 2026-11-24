import 'package:flutter/material.dart';

import '../theme_library.dart'; // WidgetNode, AppDropBuildEnv

/// Storefront / preview renderer for `rich_text`.
/// Uses [Text.rich] (not FlutterQuill) so nested builder previews cannot
/// hit-test or layout-crash a Quill editor.
Widget buildRichTextWidget(
  BuildContext context,
  WidgetNode node,
  AppDropBuildEnv env,
) {
  final raw = node.props;

  final enabled = (raw['enabled'] ?? true) == true;
  if (!enabled) return const SizedBox.shrink();

  final delta = _deltaFromProps(raw);
  if (_deltaIsBlank(delta)) return const SizedBox.shrink();

  final baseSizeSp = (raw['baseSizeSp'] is num)
      ? (raw['baseSizeSp'] as num).toDouble()
      : 14.0;
  final alignStr = (raw['align'] ?? 'left').toString();
  final baseColor = _colorFromHex(
    (raw['baseColor'] ?? '#374151').toString(),
    const Color(0xFF374151),
  );

  final lines = _linesFromDelta(delta, alignStr);
  final pad = env.r.dp(12);
  final markerW = env.r.dp(22);
  final indentStep = env.r.dp(16);
  final baseStyle = TextStyle(
    fontSize: baseSizeSp,
    color: baseColor,
    height: 1.4,
  );

  var orderedIndex = 0;
  final children = <Widget>[];
  for (final line in lines) {
    if (line.list == 'ordered') {
      orderedIndex += 1;
    } else {
      orderedIndex = 0;
    }
    Widget text = Text.rich(
      TextSpan(style: baseStyle, children: line.spans),
      textAlign: line.align,
    );
    if (line.list != null) {
      final marker = line.list == 'ordered' ? '$orderedIndex.' : '•';
      final markerStyle = _markerStyle(baseStyle, line.spans);
      text = Padding(
        padding: EdgeInsets.only(left: indentStep * line.indent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: line.list == 'ordered' ? markerW + env.r.dp(10) : markerW,
              child: Text(marker, style: markerStyle),
            ),
            Expanded(child: text),
          ],
        ),
      );
    }
    children.add(text);
  }

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: pad, vertical: env.r.dp(4)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _Line {
  const _Line({
    required this.spans,
    required this.align,
    this.list,
    this.indent = 0,
  });
  final List<InlineSpan> spans;
  final TextAlign align;
  final String? list;
  final int indent;
}

List<_Line> _linesFromDelta(
  List<Map<String, dynamic>> delta,
  String fallbackAlign,
) {
  final lines = <_Line>[];
  var spans = <InlineSpan>[];
  var lineAlign = _textAlign(fallbackAlign);

  void flush(Map<String, dynamic> newlineAttrs) {
    if (spans.isEmpty) {
      spans = [const TextSpan(text: '')];
    }
    final listRaw = newlineAttrs['list']?.toString().toLowerCase();
    String? list;
    if (listRaw == 'bullet' || listRaw == 'unordered') {
      list = 'bullet';
    } else if (listRaw == 'ordered' || listRaw == 'number' || listRaw == 'numbered') {
      list = 'ordered';
    }
    final indent = newlineAttrs['indent'] is num
        ? (newlineAttrs['indent'] as num).toInt().clamp(0, 8)
        : 0;
    if (newlineAttrs['align'] is String) {
      lineAlign = _textAlign(newlineAttrs['align'].toString(), fallbackAlign);
    }
    lines.add(
      _Line(spans: spans, align: lineAlign, list: list, indent: indent),
    );
    spans = <InlineSpan>[];
    lineAlign = _textAlign(fallbackAlign);
  }

  for (final op in delta) {
    final insert = op['insert'];
    if (insert is! String || insert.isEmpty) continue;
    final attrs = op['attributes'] is Map
        ? Map<String, dynamic>.from(op['attributes'] as Map)
        : const <String, dynamic>{};
    final pieces = insert.split('\n');
    for (var i = 0; i < pieces.length; i++) {
      final piece = pieces[i];
      if (piece.isNotEmpty) {
        spans.add(TextSpan(text: piece, style: _spanStyle(attrs)));
      }
      if (i != pieces.length - 1) {
        flush(attrs);
      }
    }
  }
  if (spans.isNotEmpty) flush(const {});
  if (lines.isEmpty) {
    lines.add(
      _Line(spans: const [TextSpan(text: '')], align: _textAlign(fallbackAlign)),
    );
  }
  return lines;
}

TextStyle _markerStyle(TextStyle base, List<InlineSpan> spans) {
  for (final span in spans) {
    if (span is TextSpan && span.style != null) {
      return base.merge(span.style);
    }
  }
  return base;
}

TextStyle _spanStyle(Map<String, dynamic> attrs) {
  final color = attrs['color'] != null
      ? _colorFromHex(attrs['color'].toString(), const Color(0xFF374151))
      : null;
  return TextStyle(
    fontWeight: attrs['bold'] == true ? FontWeight.w700 : null,
    fontStyle: attrs['italic'] == true ? FontStyle.italic : null,
    decoration: _decoration(attrs),
    color: color,
  );
}

TextDecoration? _decoration(Map<String, dynamic> attrs) {
  final underline = attrs['underline'] == true;
  final strike = attrs['strike'] == true || attrs['strikeThrough'] == true;
  if (underline && strike) {
    return TextDecoration.combine([
      TextDecoration.underline,
      TextDecoration.lineThrough,
    ]);
  }
  if (underline) return TextDecoration.underline;
  if (strike) return TextDecoration.lineThrough;
  return null;
}

TextAlign _textAlign(String value, [String fallback = 'left']) {
  switch (value.toLowerCase()) {
    case 'center':
    case 'centre':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'left':
      return TextAlign.left;
    default:
      if (fallback != value) return _textAlign(fallback);
      return TextAlign.left;
  }
}

List<Map<String, dynamic>> _deltaFromProps(Map raw) {
  final fromDelta = _normalizeDelta(raw['delta']);
  if (!_deltaIsBlank(fromDelta)) return fromDelta;

  final fromSpans = _deltaFromSpans(raw['spans']);
  if (fromSpans != null) return fromSpans;

  for (final key in ['text', 'content', 'body']) {
    final t = raw[key]?.toString().trim() ?? '';
    if (t.isNotEmpty) return _normalizeDelta([{'insert': '$t\n'}]);
  }
  return fromDelta;
}

bool _deltaIsBlank(List<Map<String, dynamic>> delta) {
  if (delta.isEmpty) return true;
  final buf = StringBuffer();
  for (final op in delta) {
    final insert = op['insert'];
    if (insert is String) buf.write(insert);
  }
  final plain = buf.toString().replaceAll('\n', ' ').trim().toLowerCase();
  return plain.isEmpty || plain == 'demo rich text' || plain == 'demo';
}

List<Map<String, dynamic>>? _deltaFromSpans(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final ops = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final text = (e['text'] ?? '').toString();
    if (text.trim().isEmpty) continue;
    final weight = (e['weight'] ?? '').toString().toLowerCase();
    final op = <String, dynamic>{'insert': text};
    final attrs = <String, dynamic>{};
    if (weight == 'bold' || weight == 'w700' || weight == 'w800') {
      attrs['bold'] = true;
    }
    final color = (e['color'] ?? '').toString().trim();
    if (color.isNotEmpty) {
      attrs['color'] = color.startsWith('#') ? color : '#$color';
    }
    if (attrs.isNotEmpty) op['attributes'] = attrs;
    ops.add(op);
  }
  if (ops.isEmpty) return null;
  return _normalizeDelta(ops);
}

List<Map<String, dynamic>> _normalizeDelta(dynamic deltaAny) {
  if (deltaAny is! List) {
    return const [
      {'insert': '\n'},
    ];
  }

  final list = <Map<String, dynamic>>[];
  for (final e in deltaAny) {
    if (e is Map) list.add(Map<String, dynamic>.from(e));
  }

  if (list.isEmpty) {
    return const [
      {'insert': '\n'},
    ];
  }

  final last = list.last['insert'];
  if (last is String && !last.endsWith('\n')) {
    list.add({'insert': '\n'});
  }
  return list;
}

Color _colorFromHex(String hex, Color fallback) {
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final n = int.tryParse(h, radix: 16);
  if (n == null) return fallback;
  return Color(n);
}
