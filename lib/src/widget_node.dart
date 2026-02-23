import '../theme_library.dart';

typedef JsonMap = Map<String, dynamic>;

class WidgetNode {
  final String type;
  final JsonMap props;
  final List<WidgetNode> children;

  WidgetNode({required this.type, JsonMap? props, List<WidgetNode>? children})
      : props = props ?? <String, dynamic>{},
        children = children ?? <WidgetNode>[];

  factory WidgetNode.fromJson(dynamic json) {
    final map = JsonMap.from(json as Map);
    final type = (map['type'] ?? '').toString();
    final JsonMap props;
    if (map.containsKey('props')) {
      props = JsonMap.from(map['props'] as Map);
    } else {
      // PageBlock.toJson() spreads data at top level (no "props" wrapper)
      props = JsonMap.from(map)
        ..remove('type')
        ..remove('id')
        ..remove('children');
    }
    final kids = (map['children'] is List) ? (map['children'] as List) : const [];
    return WidgetNode(
      type: type,
      props: props,
      children: kids.map((e) => WidgetNode.fromJson(e)).toList(),
    );
  }

  static List<WidgetNode> listFromJson(List<dynamic> list) {
    return list.map((e) => WidgetNode.fromJson(e)).toList();
  }

  // helpers
  bool b(String k, {bool def = false}) {
    final v = props[k];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return def;
  }

  String s(String k, {String def = ''}) => (props[k] ?? def).toString();

  int i(String k, {int def = 0}) {
    final v = props[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  double d(String k, {double def = 0}) {
    final v = props[k];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  JsonMap? m(String k) {
    final v = props[k];
    if (v is Map) return JsonMap.from(v);
    return null;
  }

  List<dynamic>? l(String k) {
    final v = props[k];
    if (v is List) return v;
    return null;
  }
}

typedef AppDropActionHandler = void Function(dynamic ctx, Map<String, dynamic> action);

class AppDropBuildEnv {
  final R r;
  final dynamic Function(dynamic ctx, WidgetNode node) renderNode;
  final AppDropActionHandler? onAction;

  AppDropBuildEnv({required this.r, required this.renderNode, this.onAction});

  void dispatchAction(dynamic ctx, Map<String, dynamic> action) {
    onAction?.call(ctx, action);
  }
}
