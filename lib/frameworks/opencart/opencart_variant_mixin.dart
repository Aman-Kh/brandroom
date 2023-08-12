import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/tools/flash.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart'
    show CartModel, Product, ProductAttribute, ProductVariation;
import '../../screens/index.dart' show CartScreen;
import '../product_variant_mixin.dart';
import 'opencart_product_option.dart';

mixin OpencartVariantMixin on ProductVariantMixin {
  Map<String, dynamic> selectedOptions = <String, dynamic>{};
  Map<String, double> productExtraPrice = <String, double>{};

  void clearData() {
    selectedOptions = <String, dynamic>{};
    productExtraPrice = <String, double>{};
  }

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
    clearData();
    updateVariation([], {});
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
    final productVariantion = updateVariation(variations, mapAttribute);
    onFinish(mapAttribute, productVariantion);
  }

  List<Widget> getProductAttributeWidget(
    String lang,
    Product product,
    Map<String?, String?>? mapAttribute,
    Function onSelectProductVariant,
    List<ProductVariation> variations,
  ) {
    var listWidget = <Widget>[];
    if (product.options != null && product.options!.isNotEmpty) {
      for (var option in product.options!) {
        listWidget.add(OpencartOptionInput(
          value: selectedOptions[option['product_option_id']],
          option: option,
          onChanged: (selected) {
            selectedOptions.addAll(Map<String, dynamic>.from(selected));
          },
          onRemoved: (key) {
            selectedOptions.remove(key);
          },
          onPriceChanged: (extraPrice) {
            productExtraPrice.addAll(Map<String, double>.from(extraPrice));
          },
        ));
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

  @override
  void addToCart(BuildContext context, Product product, int quantity,
      ProductVariation? productVariation, Map<String?, String?> mapAttribute,
      [bool buyNow = false, bool inStock = false]) {
    if (!inStock) {
      return;
    }

    final cartModel = Provider.of<CartModel>(context, listen: false);
    if (product.type == 'external') {
      openWebView(context, product);
      return;
    }

    var extraPrice = productExtraPrice.keys.fold(0.0, (dynamic sum, key) {
      return sum + productExtraPrice[key];
    });
    var p = Product.cloneFrom(product);
    p.price = (double.parse(product.price!) + extraPrice).toString();

    var message = cartModel.addProductToCart(
        product: p,
        quantity: quantity,
        variation: productVariation,
        options: selectedOptions);

    if (message.isNotEmpty) {
      FlashHelper.errorMessage(context, message: message);
    } else {
      if (buyNow) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => Scaffold(
              backgroundColor: Theme.of(context).backgroundColor,
              body: const CartScreen(isModal: true, isBuyNow: true),
            ),
            fullscreenDialog: true,
          ),
        );
      }
      FlashHelper.message(
        context,
        title: product.name,
        message: S.of(context).addToCartSucessfully,
      );
    }
  }
}
