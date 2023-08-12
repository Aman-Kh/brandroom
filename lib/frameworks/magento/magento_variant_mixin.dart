import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../models/index.dart'
    show Product, ProductAttribute, ProductModel, ProductVariation;
import '../../services/index.dart';
import '../../widgets/product/product_variant.dart';
import '../product_variant_mixin.dart';

mixin MagentoVariantMixin on ProductVariantMixin {
  Future<void> getProductVariations({
    BuildContext? context,
    Product? product,
    void Function({
      Product? productInfo,
      List<ProductVariation>? variations,
      Map<String?, String?> mapAttribute,
      ProductVariation? variation,
    })?
        onLoad,
  }) async {
    if (product!.attributes!.isEmpty) {
      return;
    }

    Map<String?, String?> mapAttribute = HashMap();
    var variations = <ProductVariation>[];
    Product? productInfo;

    await Services().api.getProductVariations(product)!.then((value) {
      variations = value!.toList();
    });

    if (variations.isEmpty) {
      for (var attr in product.attributes!) {
        mapAttribute.update(attr.name!, (value) => attr.options![0],
            ifAbsent: () => attr.options![0]);
      }
    } else {
      for (var variant in variations) {
        if (variant.price == product.price) {
          for (var attribute in variant.attributes) {
            for (var attr in product.attributes!) {
              mapAttribute.update(attr.name!, (value) {
                final option = attr.options!.firstWhere(
                    (o) => o['label'] == attribute.name,
                    orElse: () => null);
                if (option != null) {
                  return option['value'].toString();
                }
                return attribute.name;
              }, ifAbsent: () => attribute.name);
            }
            mapAttribute.update(attribute.name, (value) => attribute.option,
                ifAbsent: () => attribute.option);
          }
          break;
        }
        if (mapAttribute.isEmpty) {
          for (var attribute in product.attributes!) {
            mapAttribute.update(attribute.name, (value) => value, ifAbsent: () {
              return (attribute.options?.isNotEmpty ?? false)
                  ? attribute.options![0]['value']
                  : null;
            });
          }
        }
      }
    }
    final productVariation = updateVariation(variations, mapAttribute);
    context?.read<ProductModel>().changeProductVariations(variations);
    if (productVariation != null) {
      context?.read<ProductModel>().changeSelectedVariation(productVariation);
    }
    onLoad!(
        productInfo: productInfo,
        variations: variations,
        mapAttribute: mapAttribute,
        variation: productVariation);
    return;
  }

  bool couldBePurchased(
    List<ProductVariation>? variations,
    ProductVariation? productVariation,
    Product product,
    Map<String?, String?>? mapAttribute,
  ) {
    final isAvailable =
        productVariation != null ? productVariation.sku != null : true;
    return isPurchased(productVariation!, product, mapAttribute!, isAvailable);
  }

  void onSelectProductVariant({
    required ProductAttribute attr,
    String? val,
    required List<ProductVariation> variations,
    required Map<String?, String?> mapAttribute,
    required Function onFinish,
  }) {
    mapAttribute.update(attr.name, (value) {
      final option = attr.options!
          .firstWhere((o) => o['label'] == val.toString(), orElse: () => null);
      if (option != null) {
        return option['value'].toString();
      }
      return val.toString();
    }, ifAbsent: () => val.toString());
    final productVariation = updateVariation(variations, mapAttribute);
    onFinish(mapAttribute, productVariation);
  }

  List<Widget> getProductAttributeWidget(
    String lang,
    Product product,
    Map<String?, String?>? mapAttribute,
    Function onSelectProductVariant,
    List<ProductVariation> variations,
  ) {
    var listWidget = <Widget>[];

    final checkProductAttribute =
        product.attributes != null && product.attributes!.isNotEmpty;
    if (checkProductAttribute) {
      for (var attr in product.attributes!) {
        if (attr.name != null && attr.name!.isNotEmpty) {
          var options = <String?>[];
          for (var i = 0; i < attr.options!.length; i++) {
            options.add(attr.options![i]['label']);
          }

          String? selectedValue = mapAttribute![attr.name!] ?? '';

          final o = attr.options!.firstWhere((f) => f['value'] == selectedValue,
              orElse: () => null);
          if (o != null) {
            selectedValue = o['label'];
          }
          listWidget.add(
            BasicSelection(
              options: options,
              title: (kProductVariantLanguage[lang] != null &&
                      kProductVariantLanguage[lang][attr.name!.toLowerCase()] !=
                          null)
                  ? kProductVariantLanguage[lang][attr.name!.toLowerCase()]
                  : attr.name!.toLowerCase(),
              type: kProductVariantLayout[attr.name!.toLowerCase()] ?? 'box',
              value: selectedValue,
              onChanged: (val) => onSelectProductVariant(
                  attr: attr,
                  val: val,
                  mapAttribute: mapAttribute,
                  variations: variations),
            ),
          );
          listWidget.add(
            const SizedBox(height: 20.0),
          );
        }
      }
    }
    return listWidget;
  }

  List<Widget> getProductTitleWidget(BuildContext context,
      ProductVariation? productVariation, Product product) {
    final isAvailable =
        // ignore: unnecessary_null_comparison
        productVariation != null ? productVariation.sku != null : true;
    return makeProductTitleWidget(
        context, productVariation, product, isAvailable);
  }

  List<Widget> getBuyButtonWidget(
    BuildContext context,
    ProductVariation? productVariation,
    Product product,
    Map<String?, String?>? mapAttribute,
    int maxQuantity,
    int quantity,
    Function addToCart,
    Function onChangeQuantity,
    List<ProductVariation>? variations,
  ) {
    final isAvailable =
        productVariation != null ? productVariation.sku != null : true;
    return makeBuyButtonWidget(context, productVariation, product, mapAttribute,
        maxQuantity, quantity, addToCart, onChangeQuantity, isAvailable);
  }
}
