import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../theme_library.dart'; // WidgetNode, AppDropBuildEnv

/// ✅ Preview renderer for "rich_text" block using FlutterQuill (read-only)
Widget buildRichTextWidget(
    BuildContext context, WidgetNode node, AppDropBuildEnv env) {
  final raw = node.props;

  final enabled = (raw['enabled'] ?? true) == true;
  if (!enabled) return const SizedBox.shrink();

  final deltaAny = raw['delta'];
  final delta = _normalizeDelta(deltaAny);

  final baseSizeSp = (raw['baseSizeSp'] is num)
      ? (raw['baseSizeSp'] as num).toDouble()
      : 14.0;
  final alignStr = (raw['align'] ?? 'left').toString();

  final deltaWithAlign = _deltaWithBlockAlignment(delta, alignStr);

  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear((baseSizeSp / 14.0).clamp(0.5, 3.0)),
    ),
    child: _QuillReadOnlyView(
      delta: deltaWithAlign,
    ),
  );
}

/// ---------- Read-only widget (stateful so we don't leak FocusNode/ScrollController) ----------
class _QuillReadOnlyView extends StatefulWidget {
  final List<Map<String, dynamic>> delta;
  const _QuillReadOnlyView({required this.delta});

  @override
  State<_QuillReadOnlyView> createState() => _QuillReadOnlyViewState();
}

class _QuillReadOnlyViewState extends State<_QuillReadOnlyView> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = _makeController(widget.delta);
  }

  @override
  void didUpdateWidget(covariant _QuillReadOnlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // delta changed => rebuild document
    if (!_sameDelta(oldWidget.delta, widget.delta)) {
      _controller = _makeController(widget.delta);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  quill.QuillController _makeController(List<Map<String, dynamic>> delta) {
    final doc = quill.Document.fromJson(delta);
    final c = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    c.readOnly = true; // ✅ this is correct in flutter_quill 11.x
    return c;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ IMPORTANT: Preview page already has SingleChildScrollView
    // So we make QuillEditor non-interactive and let outer scroll handle it.
    return IgnorePointer(
      ignoring: true, // ✅ read-only + no focus issues
      child: quill.QuillEditor(
        controller: _controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        config: const quill.QuillEditorConfig(
          autoFocus: false,
          expands: false,
          padding: EdgeInsets.zero,
          showCursor: false,
        ),
      ),
    );
  }
}

/// Injects block-level "align" attribute so Quill renders alignment.
List<Map<String, dynamic>> _deltaWithBlockAlignment(
    List<Map<String, dynamic>> delta, String align) {
  if (align == 'left') return delta;
  final out = <Map<String, dynamic>>[];
  for (final op in delta) {
    final map = Map<String, dynamic>.from(op);
    final insert = map['insert'];
    final isLine = insert is String && insert.toString().contains('\n');
    if (isLine) {
      final attrs = map['attributes'] is Map
          ? Map<String, dynamic>.from(map['attributes'] as Map)
          : <String, dynamic>{};
      attrs['align'] = align;
      map['attributes'] = attrs;
    }
    out.add(map);
  }
  return out;
}

/// ---------- helpers ----------
List<Map<String, dynamic>> _normalizeDelta(dynamic deltaAny) {
  // if delta is missing, return minimal doc
  if (deltaAny is! List) {
    return const [
      {"insert": "\n"}
    ];
  }

  final list = <Map<String, dynamic>>[];
  for (final e in deltaAny) {
    if (e is Map) list.add(Map<String, dynamic>.from(e));
  }

  if (list.isEmpty) {
    return const [
      {"insert": "\n"}
    ];
  }

  // ✅ Quill requires final newline
  final last = list.last['insert'];
  if (last is String && !last.endsWith('\n')) {
    list.add({"insert": "\n"});
  }
  return list;
}

bool _sameDelta(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].toString() != b[i].toString()) return false;
  }
  return true;
}
