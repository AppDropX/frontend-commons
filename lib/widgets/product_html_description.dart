import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../src/responsive.dart';
import '../theme/appdrop_theme_data.dart';

const Set<String> _kBlockTags = {
  'p',
  'div',
  'ul',
  'ol',
  'li',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'blockquote',
  'section',
  'article',
  'header',
  'footer',
  'table',
  'tr',
  'pre',
  'hr',
  'html',
  'body',
};

const Set<String> _kSkipTags = {
  'script',
  'style',
  'noscript',
  'iframe',
  'svg',
};

/// Renders a Shopify-style product description (`p`, lists, `strong`, headings).
class ProductHtmlDescription extends StatelessWidget {
  const ProductHtmlDescription({
    super.key,
    required this.html,
    required this.style,
    required this.r,
    this.fontFamily,
  });

  final String html;
  final TextStyle style;
  final R r;

  /// Theme family (`Poppins`, `Lato`, …). When set, bold and semi bold
  /// load their own font file instead of faux-bolding one face.
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks(
      html_parser.parseFragment(html).nodes,
      style,
      r,
      fontFamily: fontFamily,
    );
    if (blocks.isEmpty) {
      final plain = html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (plain.isEmpty) return const SizedBox.shrink();
      return Text(plain, style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}

bool productDescriptionLooksLikeHtml(String value) {
  return RegExp(r'<\s*/?\s*[a-zA-Z][^>]*>').hasMatch(value);
}

List<Widget> _blocks(
  List<dom.Node> nodes,
  TextStyle style,
  R r, {
  String? fontFamily,
}) {
  final out = <Widget>[];
  final inline = <dom.Node>[];

  void flushInline() {
    if (inline.isEmpty) return;
    final spans = _inlineSpans(inline, style, fontFamily: fontFamily);
    inline.clear();
    if (spans.isEmpty) return;
    out.add(_paragraph(spans, style, r));
  }

  for (final node in nodes) {
    if (node is dom.Element) {
      final tag = node.localName?.toLowerCase() ?? '';
      if (_kSkipTags.contains(tag)) continue;
      if (tag == 'br') {
        inline.add(node);
        continue;
      }
      if (_kBlockTags.contains(tag)) {
        flushInline();
        final block = _blockElement(node, style, r, fontFamily: fontFamily);
        if (block != null) out.add(block);
        continue;
      }
    }
    if (node is dom.Text && node.text.trim().isEmpty && inline.isEmpty) {
      continue;
    }
    inline.add(node);
  }
  flushInline();
  return out;
}

Widget? _blockElement(
  dom.Element element,
  TextStyle style,
  R r, {
  String? fontFamily,
}) {
  final tag = element.localName?.toLowerCase() ?? '';
  final next = _styled(element, style, fontFamily: fontFamily);
  if (tag == 'ul' || tag == 'ol') {
    return _list(element, next, r,
        ordered: tag == 'ol', fontFamily: fontFamily);
  }
  if (tag == 'hr') {
    return Padding(
      padding: EdgeInsets.only(bottom: r.dp(8)),
      child:
          Divider(height: r.dp(1), color: next.color?.withValues(alpha: 0.25)),
    );
  }
  if (tag == 'li') {
    return _listItem(element, next, r, marker: '•', fontFamily: fontFamily);
  }
  if (_isHeading(tag)) {
    final heading = _headingStyle(tag, next, fontFamily: fontFamily);
    if (_hasBlockChild(element)) {
      final children =
          _blocks(element.nodes, heading, r, fontFamily: fontFamily);
      if (children.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    final spans = _inlineSpans(element.nodes, heading, fontFamily: fontFamily);
    if (spans.isEmpty) return null;
    return _paragraph(spans, heading, r);
  }
  if (_hasBlockChild(element)) {
    final children = _blocks(element.nodes, next, r, fontFamily: fontFamily);
    if (children.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
  final spans = _inlineSpans(element.nodes, next, fontFamily: fontFamily);
  if (spans.isEmpty) return null;
  return _paragraph(spans, next, r);
}

Widget _list(
  dom.Element element,
  TextStyle style,
  R r, {
  required bool ordered,
  String? fontFamily,
}) {
  final items = <dom.Element>[
    for (final node in element.nodes)
      if (node is dom.Element && node.localName?.toLowerCase() == 'li') node,
  ];
  return Padding(
    padding: EdgeInsets.only(bottom: r.dp(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          _listItem(
            items[i],
            style,
            r,
            marker: ordered ? '${i + 1}.' : '•',
            fontFamily: fontFamily,
          ),
      ],
    ),
  );
}

Widget _listItem(
  dom.Element element,
  TextStyle style,
  R r, {
  required String marker,
  String? fontFamily,
}) {
  final itemStyle = _styled(element, style, fontFamily: fontFamily);
  if (_hasBlockChild(element)) {
    return Padding(
      padding: EdgeInsets.only(bottom: r.dp(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker, style: itemStyle),
          SizedBox(width: r.dp(6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _blocks(
                element.nodes,
                itemStyle,
                r,
                fontFamily: fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
  final spans = _inlineSpans(element.nodes, itemStyle, fontFamily: fontFamily);
  return Padding(
    padding: EdgeInsets.only(bottom: r.dp(6)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(marker, style: itemStyle),
        SizedBox(width: r.dp(6)),
        Expanded(
          child: spans.isEmpty
              ? const SizedBox.shrink()
              : Text.rich(TextSpan(style: itemStyle, children: spans)),
        ),
      ],
    ),
  );
}

Widget _paragraph(List<InlineSpan> spans, TextStyle style, R r) {
  return Padding(
    padding: EdgeInsets.only(bottom: r.dp(8)),
    child: Text.rich(TextSpan(style: style, children: spans)),
  );
}

bool _hasBlockChild(dom.Element element) {
  for (final node in element.nodes) {
    if (node is! dom.Element) continue;
    final tag = node.localName?.toLowerCase() ?? '';
    if (_kBlockTags.contains(tag)) return true;
  }
  return false;
}

bool _isHeading(String tag) {
  return tag == 'h1' ||
      tag == 'h2' ||
      tag == 'h3' ||
      tag == 'h4' ||
      tag == 'h5' ||
      tag == 'h6';
}

TextStyle _headingStyle(String tag, TextStyle base, {String? fontFamily}) {
  final size = base.fontSize ?? 14;
  var bump = 0.0;
  switch (tag) {
    case 'h1':
      bump = 8;
      break;
    case 'h2':
      bump = 6;
      break;
    case 'h3':
      bump = 4;
      break;
    case 'h4':
      bump = 2;
      break;
    default:
      bump = 0;
  }
  return _withWeight(
    base,
    FontWeight.w700,
    fontFamily,
    fontSize: size + bump,
    height: 1.3,
  );
}

TextStyle _styled(dom.Element element, TextStyle base, {String? fontFamily}) {
  var style = base;
  final tag = element.localName?.toLowerCase() ?? '';
  if (tag == 'strong' || tag == 'b') {
    style = _withWeight(style, FontWeight.w700, fontFamily);
  } else if (tag == 'em' || tag == 'i') {
    style = style.copyWith(fontStyle: FontStyle.italic);
  } else if (tag == 'u') {
    style = style.copyWith(decoration: TextDecoration.underline);
  }

  final css = element.attributes['style'] ?? '';
  final weight = RegExp(
    r'font-weight\s*:\s*([^;]+)',
    caseSensitive: false,
  ).firstMatch(css);
  if (weight != null) {
    final value = weight.group(1)!.trim().toLowerCase();
    if (value == 'bold' ||
        value == 'bolder' ||
        value == '700' ||
        value == '800' ||
        value == '900') {
      style = _withWeight(style, FontWeight.w700, fontFamily);
    } else if (value == '600' || value == 'semibold' || value == 'semi-bold') {
      style = _withWeight(style, FontWeight.w600, fontFamily);
    } else if (value == '500' || value == 'medium') {
      style = _withWeight(style, FontWeight.w500, fontFamily);
    } else if (value == 'normal' || value == '400') {
      style = _withWeight(style, FontWeight.w400, fontFamily);
    }
  }
  if (RegExp(r'font-style\s*:\s*italic', caseSensitive: false).hasMatch(css)) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  return style;
}

TextStyle _withWeight(
  TextStyle base,
  FontWeight weight,
  String? fontFamily, {
  double? fontSize,
  double? height,
}) {
  final size = fontSize ?? base.fontSize;
  if (fontFamily == null || fontFamily.trim().isEmpty) {
    return base.copyWith(
      fontWeight: weight,
      fontSize: size,
      height: height ?? base.height,
    );
  }
  return AppDropThemeData.textStyle(
    fontFamily: fontFamily,
    fontSize: size ?? 14,
    fontWeight: weight,
    color: base.color,
  ).copyWith(
    height: height ?? base.height,
    fontStyle: base.fontStyle,
    decoration: base.decoration,
    letterSpacing: base.letterSpacing,
  );
}

List<InlineSpan> _inlineSpans(
  List<dom.Node> nodes,
  TextStyle style, {
  String? fontFamily,
}) {
  final spans = <TextSpan>[];

  void addText(String raw, TextStyle spanStyle) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return;
    final last = spans.isEmpty ? null : spans.last;
    if (last != null && last.style == spanStyle && last.text != null) {
      spans[spans.length - 1] = TextSpan(
        text: '${last.text}$collapsed',
        style: spanStyle,
      );
      return;
    }
    spans.add(TextSpan(text: collapsed, style: spanStyle));
  }

  void walk(dom.Node node, TextStyle spanStyle) {
    if (node is dom.Text) {
      addText(node.text, spanStyle);
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName?.toLowerCase() ?? '';
    if (_kSkipTags.contains(tag)) return;
    if (tag == 'br') {
      spans.add(TextSpan(text: '\n', style: spanStyle));
      return;
    }
    if (_kBlockTags.contains(tag)) {
      for (final child in node.nodes) {
        walk(child, spanStyle);
      }
      addText(' ', spanStyle);
      return;
    }
    final next = _styled(node, spanStyle, fontFamily: fontFamily);
    if (node.nodes.isEmpty) return;
    for (final child in node.nodes) {
      walk(child, next);
    }
  }

  for (final node in nodes) {
    walk(node, style);
  }
  if (spans.isEmpty) return const [];

  final first = spans.first.text;
  if (first != null) {
    final trimmed = first.trimLeft();
    if (trimmed.isEmpty) {
      spans.removeAt(0);
    } else if (trimmed != first) {
      spans[0] = TextSpan(text: trimmed, style: spans.first.style);
    }
  }
  if (spans.isEmpty) return const [];
  final last = spans.last.text;
  if (last != null) {
    final trimmed = last.trimRight();
    if (trimmed.isEmpty) {
      spans.removeLast();
    } else if (trimmed != last) {
      spans[spans.length - 1] =
          TextSpan(text: trimmed, style: spans.last.style);
    }
  }
  return spans;
}
