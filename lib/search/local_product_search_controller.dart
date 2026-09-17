import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'product_search_entry.dart';

/// Idle time before a typed query is executed.
const Duration kAppDropSearchDebounce = Duration(milliseconds: 350);

/// Results revealed per page in local search mode.
const int kAppDropSearchPageSize = 24;

/// Debounced local search with stale-query protection and result paging.
///
/// Used by appdrop_preview and builder preview. Pilot search hits
/// `GET /api/mobile/products?search=` with the same debounce.
class LocalProductSearchController extends ChangeNotifier {
  LocalProductSearchController({
    this.pageSize = kAppDropSearchPageSize,
    this.debounce = kAppDropSearchDebounce,
  });

  final int pageSize;
  final Duration debounce;

  LocalProductSearchIndex? _index;
  Timer? _debounceTimer;
  String _typedQuery = '';
  String _activeQuery = '';
  int _generation = 0;

  List<ProductSearchEntry> _matches = const [];
  List<Map<String, dynamic>> _gridItems = const [];
  int _visible = 0;
  bool _searching = false;

  List<ProductSearchEntry> get results =>
      _matches.take(_visible).toList(growable: false);

  /// Stable product-grid payloads, mapped once when results change.
  List<Map<String, dynamic>> get gridItems => _gridItems;

  String get query => _typedQuery;
  bool get hasQuery => _typedQuery.isNotEmpty;
  bool get isSearching => _searching;
  bool get hasMore => _visible < _matches.length;
  bool get isEmptyResult =>
      hasQuery && results.isEmpty && !_searching && _index != null;

  /// Rebuilds the index when [rows] changes (e.g. after catalog load).
  void setCatalog(Iterable<Map<String, dynamic>> rows) {
    _index = LocalProductSearchIndex(rows);
    if (_activeQuery.isNotEmpty) {
      _applyMatches(_activeQuery, reset: true);
    }
    notifyListeners();
  }

  void onQueryChanged(String raw) {
    final next = raw.trim();
    if (next == _typedQuery) return;
    _typedQuery = next;
    _debounceTimer?.cancel();
    if (next.isEmpty) {
      _clearResults();
      return;
    }
    _debounceTimer = Timer(debounce, () => _run(next));
  }

  void submit() {
    _debounceTimer?.cancel();
    if (_typedQuery.isEmpty) return;
    _run(_typedQuery);
  }

  void clear() {
    _debounceTimer?.cancel();
    _typedQuery = '';
    _clearResults();
  }

  void loadMore() {
    if (_visible >= _matches.length) return;
    _visible = math.min(_visible + pageSize, _matches.length);
    _rebuildGridItems();
    notifyListeners();
  }

  void _run(String query) {
    if (query == _activeQuery) return;
    _activeQuery = query;
    final generation = ++_generation;
    _searching = true;
    notifyListeners();

    _applyMatches(query, reset: true);

    if (generation == _generation) {
      _searching = false;
      notifyListeners();
    }
  }

  void _applyMatches(String query, {required bool reset}) {
    final index = _index;
    _matches = index?.search(query) ?? const [];
    final floor = reset ? pageSize : math.max(_visible, pageSize);
    _visible = math.min(floor, _matches.length);
    _rebuildGridItems();
  }

  void _rebuildGridItems() {
    _gridItems = [
      for (final entry in _matches.take(_visible)) entry.toGridItem(),
    ];
  }

  void _clearResults() {
    _debounceTimer?.cancel();
    _activeQuery = '';
    _generation++;
    _matches = const [];
    _gridItems = const [];
    _visible = 0;
    _searching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
