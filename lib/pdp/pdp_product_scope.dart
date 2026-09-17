import 'package:flutter/widgets.dart';

import '../product/product_variant_model.dart';

/// PDP selection state: chosen variant drives price and cart payload.
class PdpProductController extends ChangeNotifier {
  PdpProductController(Map<String, dynamic> product)
      : _product = Map<String, dynamic>.from(product) {
    _syncVariants(keepId: null);
  }

  Map<String, dynamic> _product;
  List<ProductVariantOption> variants = const [];
  int _selectedIndex = 0;

  Map<String, dynamic> get product => _product;

  String get variantGroupLabel => productVariantGroupLabel(_product);

  ProductVariantOption? get selectedVariant {
    if (variants.isEmpty) return null;
    final clamped = _selectedIndex.clamp(0, variants.length - 1);
    return variants[clamped];
  }

  int get selectedIndex {
    if (variants.isEmpty) return 0;
    return _selectedIndex.clamp(0, variants.length - 1);
  }

  bool get hasVariants => variants.length > 1;

  /// Replaces the product payload (e.g. after a full-row fetch adds variants)
  /// and keeps the previously selected variant when it still exists.
  void applyProduct(Map<String, dynamic> product) {
    final keepId = selectedVariant?.id;
    _product = Map<String, dynamic>.from(product);
    _syncVariants(keepId: keepId);
    notifyListeners();
  }

  void _syncVariants({String? keepId}) {
    variants = parseProductVariants(_product);
    if (variants.isEmpty) {
      _selectedIndex = 0;
      return;
    }
    if (keepId != null && keepId.isNotEmpty) {
      final idx = variants.indexWhere((v) => v.id == keepId);
      if (idx >= 0 && !variants[idx].isOutOfStock) {
        _selectedIndex = idx;
        return;
      }
    }
    final clamped = _selectedIndex.clamp(0, variants.length - 1);
    if (!variants[clamped].isOutOfStock) {
      _selectedIndex = clamped;
      return;
    }
    _selectedIndex = _firstInStockIndex();
  }

  int _firstInStockIndex() {
    final inStock = variants.indexWhere((v) => !v.isOutOfStock);
    if (inStock >= 0) return inStock;
    return _selectedIndex.clamp(0, variants.length - 1);
  }

  void selectVariant(int index) {
    if (variants.isEmpty) return;
    final clamped = index.clamp(0, variants.length - 1);
    if (variants[clamped].isOutOfStock) return;
    if (_selectedIndex == clamped) return;
    _selectedIndex = clamped;
    notifyListeners();
  }

  double get sellingPrice {
    final selected = selectedVariant;
    if (selected != null && selected.hasPrice) return selected.sellingPrice;
    if (variants.isNotEmpty) return selected?.sellingPrice ?? 0;
    return _baseSellingPrice();
  }

  double get retailPrice {
    final selected = selectedVariant;
    if (selected != null) {
      final retail = selected.retailPrice;
      if (retail != null && retail > 0) return retail;
      if (selected.hasPrice) return selected.sellingPrice;
    }
    if (variants.isNotEmpty) return selected?.retailPrice ?? selected?.sellingPrice ?? 0;
    return _baseRetailPrice();
  }

  int get discountPercent {
    final retail = retailPrice;
    final selling = sellingPrice;
    if (retail > selling && retail > 0) {
      return (((retail - selling) / retail) * 100).round();
    }
    final fromProduct = _product['discountPercent'];
    if (fromProduct is num) return fromProduct.round();
    return 0;
  }

  String get formattedPriceLine {
    final selling = sellingPrice;
    if (selling <= 0) return '';
    final retail = retailPrice;
    if (retail > selling && retail > 0) {
      final sellStr = selling == selling.roundToDouble()
          ? selling.toStringAsFixed(0)
          : selling.toStringAsFixed(2);
      final retailStr = retail == retail.roundToDouble()
          ? retail.toStringAsFixed(0)
          : retail.toStringAsFixed(2);
      return '₹$sellStr  ·  was ₹$retailStr';
    }
    final sellStr = selling == selling.roundToDouble()
        ? selling.toStringAsFixed(0)
        : selling.toStringAsFixed(2);
    return '₹$sellStr';
  }

  Map<String, dynamic> get effectiveProduct {
    final selected = selectedVariant;
    if (selected == null) return Map<String, dynamic>.from(_product);
    return productWithSelectedVariant(_product, selected);
  }

  double _baseSellingPrice() {
    final sp = _product['sellingPrice'];
    if (sp != null) {
      final parsed = parseApiNumber(sp);
      if (parsed > 0) return parsed;
    }
    return parseApiNumber(_product['price']);
  }

  double _baseRetailPrice() {
    final rp = _product['retailPrice'];
    if (rp != null) {
      final parsed = parseApiNumber(rp);
      if (parsed > 0) return parsed;
    }
    final compare = _product['compare_at_price'];
    if (compare != null) {
      final parsed = parseApiNumber(compare);
      if (parsed > 0) return parsed;
    }
    return _baseSellingPrice();
  }
}

/// Provides [PdpProductController] to PDP blocks (variant chips, price, add to cart).
class PdpProductScope extends InheritedNotifier<PdpProductController> {
  const PdpProductScope({
    super.key,
    required PdpProductController controller,
    required super.child,
  }) : super(notifier: controller);

  static PdpProductController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PdpProductScope>()
        ?.notifier;
  }
}

/// Host widget that owns [PdpProductController] lifecycle for a PDP screen.
class PdpProductScopeHost extends StatefulWidget {
  const PdpProductScopeHost({
    super.key,
    required this.product,
    required this.child,
  });

  final Map<String, dynamic> product;
  final Widget child;

  @override
  State<PdpProductScopeHost> createState() => _PdpProductScopeHostState();
}

class _PdpProductScopeHostState extends State<PdpProductScopeHost> {
  late PdpProductController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdpProductController(widget.product);
  }

  @override
  void didUpdateWidget(covariant PdpProductScopeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = (oldWidget.product['productId'] ?? oldWidget.product['id'])
        ?.toString();
    final newId =
        (widget.product['productId'] ?? widget.product['id'])?.toString();
    if (oldId != newId) {
      _controller.dispose();
      _controller = PdpProductController(widget.product);
      return;
    }
    _controller.applyProduct(widget.product);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdpProductScope(
      controller: _controller,
      child: widget.child,
    );
  }
}
