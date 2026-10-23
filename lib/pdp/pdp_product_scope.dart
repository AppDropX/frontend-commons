import 'package:flutter/widgets.dart';

import '../product/product_variant_model.dart';
import '../widgets/product_price_row.dart';

/// PDP selection state: chosen variant drives price and cart payload.
class PdpProductController extends ChangeNotifier {
  PdpProductController(
    Map<String, dynamic> product, {
    this.selectFirstInStock = false,
  }) : _product = Map<String, dynamic>.from(product) {
    _syncVariants(keepId: null);
  }

  /// List sheets keep the previous first-in-stock default. PDP starts with
  /// nothing chosen so the price can show a range until the shopper picks.
  final bool selectFirstInStock;

  Map<String, dynamic> _product;
  List<ProductVariantOption> variants = const [];
  int _selectedIndex = -1;
  int _quantity = 1;

  /// Stepper cap reported by the quantity block. Null until that block builds.
  int? appliedCeiling;
  bool _ceilingNotifyScheduled = false;

  Map<String, dynamic> get product => _product;

  String get variantGroupLabel => productVariantGroupLabel(_product);

  ProductVariantOption? get selectedVariant {
    if (!hasSelection) return null;
    return variants[_selectedIndex];
  }

  /// `-1` until the shopper picks a variant. A product with one variant is
  /// selected immediately because there is nothing to choose.
  int get selectedIndex => _selectedIndex;

  bool get hasSelection =>
      _selectedIndex >= 0 && _selectedIndex < variants.length;

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
    if (variants.length <= 1) {
      _selectedIndex = variants.isEmpty ? -1 : 0;
      return;
    }
    if (keepId != null && keepId.isNotEmpty) {
      final idx = variants.indexWhere((v) => v.id == keepId);
      if (idx >= 0 && !variants[idx].isOutOfStock) {
        _selectedIndex = idx;
        return;
      }
    }
    if (_selectedIndex >= 0 &&
        _selectedIndex < variants.length &&
        !variants[_selectedIndex].isOutOfStock) {
      return;
    }
    _selectedIndex = selectFirstInStock ? _firstInStockIndex() : -1;
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
    _quantity = 1;
    notifyListeners();
  }

  /// Units chosen on the PDP stepper. Clamped by [appliedCeiling] when set.
  int get quantity {
    final cap = appliedCeiling;
    if (cap != null && cap <= 0) return 0;
    final stored = _quantity < 1 ? 1 : _quantity;
    if (cap != null && stored > cap) return cap;
    return stored;
  }

  void setQuantity(int value) {
    var next = value < 1 ? 1 : value;
    final cap = appliedCeiling;
    if (cap != null && cap > 0 && next > cap) next = cap;
    if (cap != null && cap <= 0) next = 1;
    if (_quantity == next) return;
    _quantity = next;
    notifyListeners();
  }

  /// Records the stepper cap. Safe to call during build; listeners update after the frame.
  void syncCeiling(int ceiling) {
    final clamped = ceiling > 0 && _quantity > ceiling;
    final changed = appliedCeiling != ceiling || clamped;
    appliedCeiling = ceiling;
    if (clamped) _quantity = ceiling;
    if (!changed || _ceilingNotifyScheduled) return;
    _ceilingNotifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ceilingNotifyScheduled = false;
      notifyListeners();
    });
  }

  void resetQuantity() {
    if (_quantity == 1) return;
    _quantity = 1;
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

  String formattedPriceLine({
    String prefix = '₹',
    String suffix = 'default',
  }) {
    final selling = sellingPrice;
    if (selling <= 0) return '';
    final retail = retailPrice;
    if (retail > selling && retail > 0) {
      return '${formatProductMoney(selling, prefix, suffix: suffix)}  ·  was ${formatProductMoney(retail, prefix, suffix: suffix)}';
    }
    return formatProductMoney(selling, prefix, suffix: suffix);
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

/// Highest quantity the PDP stepper can select. `0` means the selection is sold out.
int pdpQuantityCeiling({
  required Map<String, dynamic> product,
  ProductVariantOption? variant,
  required int configuredMax,
}) {
  final max = configuredMax < 1 ? 1 : configuredMax;
  if (variant != null) {
    if (variant.isOutOfStock) return 0;
    final stock = variant.inventoryQuantity;
    if (stock == null) return max;
    if (stock <= 0) return 0;
    return stock < max ? stock : max;
  }
  if (!catalogProductIsInStock(product)) return 0;
  final stock = parseVariantInventoryQuantity(product);
  if (stock == null) return max;
  if (stock <= 0) return 0;
  return stock < max ? stock : max;
}

bool pdpSelectionIsSoldOut({
  required Map<String, dynamic> product,
  ProductVariantOption? variant,
}) {
  return pdpQuantityCeiling(
        product: product,
        variant: variant,
        configuredMax: 1,
      ) ==
      0;
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
