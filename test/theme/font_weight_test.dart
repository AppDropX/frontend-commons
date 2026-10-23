import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_commons/theme/appdrop_theme_data.dart';
import 'package:frontend_commons/utils/product_block_theme_helpers.dart';
import 'package:frontend_commons/widgets/product_price_row.dart';

void main() {
  test('lato semi bold sits between regular and bold', () {
    FontWeight face(FontWeight requested) =>
        AppDropThemeData.fontFileWeight('Lato', requested);

    final regular = face(FontWeight.w400);
    final semi = face(FontWeight.w600);
    final bold = face(FontWeight.w700);
    expect(regular, FontWeight.w400);
    expect(semi, FontWeight.w700);
    expect(bold, FontWeight.w900);
    expect(semi.value, lessThan(bold.value));
  });

  test('semi_bold is a lighter weight than bold', () {
    expect(titleFontWeightFromVariation('semi_bold'), FontWeight.w600);
    expect(titleFontWeightFromVariation('Semibold'), FontWeight.w600);
    expect(titleFontWeightFromVariation('bold'), FontWeight.w700);
    expect(titleFontWeightFromVariation('regular'), FontWeight.w400);
  });

  test('price prefix, layout, and size follow product block settings', () {
    expect(productPricePrefix('symbol'), '₹');
    expect(productPricePrefix('rs'), 'Rs.\u2009');
    expect(productPricePrefix('Rs.'), 'Rs.\u2009');
    expect(formatProductAmount(1200, 'default'), '1200');
    expect(formatProductAmount(1200, '00'), '1200.00');
    expect(formatProductAmount(1200, '.000'), '1200.000');
    expect(productCtaFontWeight('bold'), FontWeight.w800);
    expect(productCtaFontWeight('semibold'), FontWeight.w600);
    expect(productCtaFontWeight('regular'), FontWeight.w400);
    expect(productPriceLayout('row'), ProductPriceRowLayout.row);
    expect(productPriceLayout('column'), ProductPriceRowLayout.column);
    expect(productSellingFontSize('Small', null), 12);
    expect(productSellingFontSize('Medium', null), 14);
    expect(productSellingFontSize('Large', null), 18);
    expect(productRetailFontSize('Large', null), 14);

    final cfg = ProductPriceDisplayConfig.fromProductBlock({
      'config': {
        'price_currency': 'rs',
        'price_layout': 'column',
        'price_size': 'Large',
        'strike_price_color': '#112233',
        'price_suffix': '00',
      },
    });
    expect(cfg.prefix, 'Rs.\u2009');
    expect(cfg.priceSuffix, '00');
    expect(
      formatProductMoney(1200, cfg.prefix, suffix: cfg.priceSuffix),
      'Rs.\u20091200.00',
    );
    expect(cfg.layout, ProductPriceRowLayout.column);
    expect(cfg.sellingFontSize, 18);
    expect(cfg.strikeColor, const Color(0xFF112233));
  });
}
