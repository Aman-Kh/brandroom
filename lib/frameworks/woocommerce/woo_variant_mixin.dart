import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../models/index.dart'
    show AppModel, Product, ProductAttribute, ProductVariation;
import '../../services/index.dart';
import '../../widgets/product/product_variant.dart';
import '../product_variant_mixin.dart';

mixin WooVariantMixin on ProductVariantMixin {
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
    if (product!.attributes == null) {
      return;
    }

    var mapAttribute = <String?, String?>{};
    var variations = <ProductVariation>[];
    Product? productInfo;
    ProductVariation? variation;

    final lang = Provider.of<AppModel>(context!, listen: false).langCode;
    await Services()
        .api
        .getProductVariations(product, lang: lang)!
        .then((value) {
      variations = value!.toList();
    });

    if (variations.isEmpty) {
      for (var attr in product.attributes!) {
        if (attr.options?.isNotEmpty ?? false) {
          mapAttribute.update(attr.name, (value) => attr.options![0]['name'],
              ifAbsent: () => attr.options![0]['name']);
        }
      }
    } else {
      await Services().api.getProduct(product.id, lang: lang)!.then((onValue) {
        if (onValue != null) {
          productInfo = onValue;
        }
      });

      if (productInfo!.defaultAttributes.isEmpty &&
          (kProductDetail.autoSelectFirstAttribute)) {
        /// Load default attributes from first variation.
        for (var variant in variations) {
          if (variant.price == product.price) {
            for (var attribute in variant.attributes) {
              for (var attr in product.attributes!) {
                if (attr.name == attribute.name) {
                  mapAttribute.update(
                      attr.name, (value) => attr.options![0]['name'],
                      ifAbsent: () => attr.options![0]['name']);
                }
              }
              mapAttribute.update(attribute.name, (value) => attribute.option,
                  ifAbsent: () => attribute.option);
            }
            break;
          }
          if (mapAttribute.isEmpty) {
            var firstItem = variations[0];
            for (var attribute in firstItem.attributes) {
              mapAttribute.update(attribute.name, (value) => value,
                  ifAbsent: () {
                return attribute.option;
              });
            }
          }
        }
      }

      if (productInfo!.defaultAttributes.isNotEmpty) {
        /// Load default attributes from Woo.
        for (var attribute in productInfo!.defaultAttributes) {
          /// Convert slug to name.
          final option = productInfo!.attributeSlugMap[attribute.option];
          mapAttribute[attribute.name] = option;
        }
      }

      String getDataUpdateAttribute(List options, String valueCompare) {
        for (var productOptionAttr in options) {
          if (productOptionAttr['slug'] != null &&
              productOptionAttr['slug'] == valueCompare) {
            return productOptionAttr['name'];
          }
        }
        return valueCompare;
      }

      /// Update name for attribute if its value is from slug
      if (productInfo != null &&
          (productInfo!.attributes?.isNotEmpty ?? false)) {
        /// update with product option
        for (var attr in productInfo!.attributes!) {
          if (attr.options == null) {
            break;
          }

          /// update variations
          for (var item in variations) {
            /// update attributes(1) and attributeMap(2) of variations

            /// (1) update attributes of variations
            for (var itemAttr in item.attributes) {
              if ((attr.name == itemAttr.name || attr.label == itemAttr.name) &&
                  itemAttr.option != null) {
                itemAttr.option =
                    getDataUpdateAttribute(attr.options!, itemAttr.option!);
              }
            }

            /// (2) update attributes of attributeMap
            item.attributeMap.forEach((key, value) {
              if (item.attributeMap[key] != null) {
                item.attributeMap[key]!.option = getDataUpdateAttribute(
                    attr.options!, item.attributeMap[key]!.option!);
              }
            });
          }

          /// update for product mapAttribute
          mapAttribute.forEach((key, value) {
            if (attr.options != null && value != null) {
              mapAttribute[key] = getDataUpdateAttribute(attr.options!, value);
            }
          });
        }
      }

      /// Check default attributes
      for (var item in variations) {
        if (item.hasSameAttributes(mapAttribute)) {
          variation = item;
          break;
        }
      }

      if (variation == null) {
        /// Clear default attributes if it's invalid.
        // mapAttribute.clear();
      }
    }

    // if there is any default attribute is any, we need to set first option for that attribute
    if ((productInfo?.attributes?.isNotEmpty ?? false) &&
        mapAttribute.isNotEmpty &&
        productInfo!.attributes!.length > mapAttribute.keys.length) {
      for (var attr in productInfo!.attributes!) {
        if (mapAttribute[attr.label] == null &&
            (attr.options?.isNotEmpty ?? false)) {
          mapAttribute[attr.label] = attr.options![0]['name'];
        }
      }
    }

    if (onLoad != null) {
      onLoad(
          productInfo: productInfo,
          variations: variations,
          variation: variation,
          mapAttribute: mapAttribute);
    }
    return;
  }

  bool couldBePurchased(
    List<ProductVariation>? variations,
    ProductVariation? productVariation,
    Product product,
    Map<String?, String?>? mapAttribute,
  ) {
    final isAvailable =
        productVariation != null ? productVariation.id != null : true;

    final isValidProductVariant = productVariation != null
        ? isValidProductVariation(variations!, mapAttribute)
        : true;

    return isValidProductVariant &&
        isPurchased(productVariation, product, mapAttribute ?? {}, isAvailable);
  }

  /// Return true if mapAttribute match with any of variations.
  bool isValidProductVariation(
      List<ProductVariation> variations, Map<String?, String?>? mapAttribute) {
    for (var variation in variations) {
      if (variation.hasSameAttributes(mapAttribute!)) {
        /// Hide out of stock variation
        if ((kAdvanceConfig.hideOutOfStock) &&
            !variation.inStock! &&
            !(variation.backordersAllowed ?? false)) {
          return false;
        }
        return true;
      }
    }
    return false;
  }

  void onSelectProductVariant({
    ProductAttribute? attr,
    String? val,
    List<ProductVariation>? variations,
    Map<String?, String?>? mapAttribute,
    Function? onFinish,
  }) {
    if (kProductDetail.hideInvalidAttributes) {
      final previousVal = mapAttribute![attr!.name];

      /// Unselect if option is selected.
      if (val.toString() == previousVal) {
        mapAttribute[attr.name] = null;
        final productVariation = updateVariation(variations!, mapAttribute);
        onFinish!(mapAttribute, productVariation);
        return;
      }
    }

    mapAttribute!.update(attr!.name, (value) => val.toString(),
        ifAbsent: () => val.toString());

    if (!isValidProductVariation(variations!, mapAttribute)) {
      /// Reset other choices
      mapAttribute.clear();
      mapAttribute[attr.name] = val.toString();
    }

    final productVariation = updateVariation(variations, mapAttribute);
    onFinish!(mapAttribute, productVariation);
  }

  List<Widget> getProductAttributeWidget(
    String lang,
    Product product,
    Map<String?, String?>? mapAttribute,
    Function onSelectProductVariant,
    List<ProductVariation> variations,
  ) {
    var listWidget = <Widget>[];

    final checkProductAttribute = product.attributes?.isNotEmpty ?? false;
    if (checkProductAttribute) {
      for (var attr in product.attributes!) {
        ///  - Use `attrClone` clone because there are cases where it is necessary
        /// to update the name of `attr` to identify the product variant.
        ///  - Depending on `mapAttribute` whose key is the mapAttribute's name
        /// or label, it will determine the updated value.
        var attrClone = attr.copyWith();

        for (var item in mapAttribute!.entries) {
          if (item.key == attrClone.label) {
            attrClone.name = attrClone.label;
            break;
          }
        }

        if (attrClone.name?.isNotEmpty ?? false) {
          var options =
              _getValidAttributeOptions(attrClone, mapAttribute, variations);

          /// Deselect invalid option.
          if (options.isEmpty) {
            mapAttribute[attrClone.name] = null;
            options =
                _getValidAttributeOptions(attrClone, mapAttribute, variations);
          }

          var selectedValue = mapAttribute[attrClone.name] ?? '';

          final attrType = kProductVariantLayout[attr.cleanSlug ?? attr.name] ??
              kProductVariantLayout[attr.name?.toLowerCase()] ??
              'box';

          // print('🎉 🎉 🎉 Debug the attribute layout');
          // print(attr.name);
          // print(attrType);

          /// For product variation swatches (image)
          Map<String?, String?>? imageUrls;
          if (attrType == 'image') {
            imageUrls = {};
            for (var option in attr.options!) {
              if (option['description'].toString().contains('http')) {
                imageUrls[option['name']] = option['description'];
              }
            }
          }

          listWidget.add(
            BasicSelection(
              imageUrls: imageUrls,
              options: options,
              title: kProductVariantLanguage[lang] != null
                  ? kProductVariantLanguage[lang]
                          [attr.cleanSlug ?? attr.name] ??
                      kProductVariantLanguage[lang][attr.name?.toLowerCase()] ??
                      attr.label?.toLowerCase()
                  : attr.label?.toLowerCase(),
              type: attrType,
              value: selectedValue,
              onChanged: (val) => onSelectProductVariant(
                  attr: attrClone,
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
        productVariation != null ? productVariation.id != null : true;
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
        couldBePurchased(variations, productVariation, product, mapAttribute);

    return makeBuyButtonWidget(context, productVariation, product, mapAttribute,
        maxQuantity, quantity, addToCart, onChangeQuantity, isAvailable);
  }

  List<String> _getValidAttributeOptions(ProductAttribute attr,
      Map<String?, String?> mapAttribute, List<ProductVariation> variations) {
    return List<String>.from(
      attr.options!
          .map((e) {
            var copy = Map<String?, String?>.from(mapAttribute);
            copy[attr.name] = e['name'];

            if (kProductDetail.hideInvalidAttributes) {
              if (isValidProductVariation(variations, copy)) {
                return e['name'];
              }
              return null;
            } else {
              return e['name'];
            }
          })
          .toList()

          /// To filter null value.
          .whereType<String>(),
    );
  }
}
