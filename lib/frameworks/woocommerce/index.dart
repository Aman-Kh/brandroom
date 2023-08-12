import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart'
    show
        AddonsOption,
        AppModel,
        CartModel,
        Country,
        CountryState,
        Coupons,
        Discount,
        ListCountry,
        Order,
        PaymentMethod,
        Product,
        ProductVariation,
        ShippingMethodModel,
        User,
        UserModel;
import '../../models/order/index.dart';
import '../../models/tera_wallet/index.dart';
import '../../modules/product_reviews/product_reviews_index.dart';
import '../../modules/re_order/re_order_index.dart';
import '../../modules/subscription/views/detail_price.dart';
import '../../modules/subscription/views/recurring_totals.dart';
import '../../routes/flux_navigate.dart';
import '../../screens/index.dart'
    show PaymentWebview, WebviewCheckoutSuccessScreen;
import '../../services/index.dart';
import '../frameworks.dart';
import '../product_variant_mixin.dart';
import 'product_addons_mixin.dart';
import 'woo_variant_mixin.dart';

class WooWidget extends BaseFrameworks
    with ProductVariantMixin, WooVariantMixin, ProductAddonsMixin {
  @override
  bool get enableProductReview => true;

  @override
  bool get enableMembershipUltimate => kAdvanceConfig.enableMembershipUltimate;

  @override
  bool enableShoppingCart(Product? product) =>
      kAdvanceConfig.enableMembershipUltimate
          ? kAdvanceConfig.enableCart && !(product?.isRestricted ?? true)
          : kAdvanceConfig.enableCart;

  bool isBookingProduct(CartModel cartModel) {
    var isBooking = false;
    for (var key in cartModel.productsInCart.keys) {
      var productId = Product.cleanProductID(key);
      var product = cartModel.item[productId]!;
      if (product.bookingInfo != null) {
        isBooking = true;
      }
    }
    return isBooking;
  }

  Discount _makeDiscount(
      Coupons? coupons, String couponCode, CartModel cartModel) {
    var coupon =
        coupons!.coupons.firstWhere((element) => element.code == couponCode);
    final discountValue = coupon.discountType == 'percent'
        ? cartModel.getSubTotal()! * coupon.amount! / 100.0
        : coupon.amount!;
    return Discount(coupon: coupon, discountValue: discountValue);
  }

  Future<Discount?> checkValidCoupon(
      BuildContext context, String couponCode, Coupons? coupons) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final isBooking = isBookingProduct(cartModel);
    Discount? discount;
    if (isBooking) {
      discount = _makeDiscount(coupons, couponCode, cartModel);
    } else {
      discount = await Coupons.getDiscount(
        cartModel: cartModel,
        couponCode: couponCode,
      );
      discount ??= _makeDiscount(coupons, couponCode, cartModel);
    }

    if (discount.discountValue != null) {
      await cartModel.updateDiscount(discount: discount);
      return discount;
    }

    return null;
  }

  @override
  Future<void> applyCoupon(context,
      {Coupons? coupons,
      String? code,
      Function? success,
      Function? error}) async {
    try {
      final discount =
          await checkValidCoupon(context, code!.toLowerCase(), coupons);
      if (discount != null) {
        success!(discount);
        return;
      }
    } catch (err) {
      error!(err.toString());
      return;
    }
    error!(S.of(context).couponInvalid);
  }

  @override
  Future<void> doCheckout(BuildContext context,
      {Function? success, Function? error, Function? loading}) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);

    if (kPaymentConfig.enableOnePageCheckout) {
      loading!(true);
      var params = Order().toJson(
          cartModel, userModel.user != null ? userModel.user!.id : null, true);
      params['token'] = userModel.user != null ? userModel.user!.cookie : null;
      var url = await Services().api.getCheckoutUrl(
          params, Provider.of<AppModel>(context, listen: false).langCode)!;
      loading(false);

      /// Navigate to Webview payment
      String? orderNum;
      await FluxNavigate.push(
        MaterialPageRoute(
            builder: (context) => PaymentWebview(
                  url: url,
                  onFinish: (number) async {
                    orderNum = number;
                  },
                )),
        forceRootNavigator: true,
      );
      if (orderNum != null) {
        cartModel.clearCart();
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WebviewCheckoutSuccessScreen(
                    order: Order(number: orderNum),
                  )),
        );
      }
      return;
    }

    /// return success to navigate to Native payment
    success!();
  }

  @override
  Future<void> createOrder(BuildContext context,
      {Function? onLoading,
      Function? success,
      Function? error,
      bool paid = false,
      bool cod = false,
      bool bacs = false,
      String transactionId = ''}) async {
    var listOrder = [];
    var isLoggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    final storage = LocalStorage(LocalStorageKey.dataOrder);
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);

    try {
      final order = await Services().api.createOrder(
          cartModel: cartModel,
          user: userModel,
          paid: paid,
          transactionId: transactionId)!;

      if (bacs) {
        await Services().api.updateOrder(order.id,
            status: 'on-hold',
            token: userModel.user != null ? userModel.user!.cookie : null);
      }
      if ((cod && kPaymentConfig.updateOrderStatus)) {
        await Services().api.updateOrder(order.id,
            status: 'processing',
            token: userModel.user != null ? userModel.user!.cookie : null);
      }
      if (!isLoggedIn) {
        var items = storage.getItem('orders');
        if (items != null) {
          listOrder = items;
        }
        listOrder.add(order.toOrderJson(cartModel, null));
        await storage.setItem('orders', listOrder);
      }
      success!(order);
    } catch (e, trace) {
      printLog(e.toString());
      printLog(trace.toString());
      if (error != null) {
        error(e.toString());
      }
    }
  }

  @override
  void placeOrder(context,
      {CartModel? cartModel,
      PaymentMethod? paymentMethod,
      Function? onLoading,
      Function? success,
      Function? error}) {
    Provider.of<CartModel>(context, listen: false)
        .setPaymentMethod(paymentMethod);

    final user = Provider.of<UserModel>(context, listen: false).user;

    if (paymentMethod!.id == 'cod' || paymentMethod.id == 'wallet') {
      createOrder(context, cod: true, onLoading: onLoading,
          success: (Order order) {
        success!(order);
        if (paymentMethod.id == 'wallet' &&
            user != null &&
            user.cookie != null) {
          Provider.of<WalletModel>(context, listen: false)
              .processPayment(order.id!, user.cookie!);
        }
      }, error: error);
      return;
    }

    if (paymentMethod.id == 'bacs') {
      createOrder(context,
          bacs: true, onLoading: onLoading, success: success, error: error);
      return;
    }

    var params = Order().toJson(cartModel!, user?.id, true);
    params['token'] = user?.cookie;
    makePaymentWebview(context, params, onLoading, success, error);
  }

  Future<void> makePaymentWebview(context, Map<String, dynamic> params,
      Function? onLoading, Function? success, Function? error) async {
    try {
      onLoading!(true);

      var url = await Services().api.getCheckoutUrl(
          params, Provider.of<AppModel>(context, listen: false).langCode)!;
      onLoading(false);
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PaymentWebview(
                url: url,
                onFinish: (number) {
                  success!(number != null ? Order(number: number) : null);
                })),
      );
    } catch (e, trace) {
      error!(e.toString());
      printLog(trace.toString());
    }
  }

  @override
  Map<String, dynamic>? getPaymentUrl(context) {
    return null;
  }

  @override
  void updateUserInfo(
      {User? loggedInUser,
      context,
      required onError,
      onSuccess,
      required currentPassword,
      required userDisplayName,
      userEmail,
      userNiceName,
      userUrl,
      userPassword,
      userFirstname,
      userLastname}) {
    var params = {
      'user_id': loggedInUser!.id,
      'display_name': userDisplayName,
      'user_email': userEmail,
      'user_nicename': userNiceName,
      'user_url': userUrl,
    };
    if (!loggedInUser.isSocial! && userPassword!.isNotEmpty) {
      params['user_pass'] = userPassword;
    }
    if (!loggedInUser.isSocial! && currentPassword.isNotEmpty) {
      params['current_pass'] = currentPassword;
    }
    Services().api.updateUserInfo(params, loggedInUser.cookie)!.then((value) {
      var param = value!['data'] ?? value;
      param['password'] = userPassword;
      onSuccess!(User.fromJson(param));
    }).catchError((e) {
      onError(e.toString());
    });
  }

  void getListCountries() {
    /// Get List Countries
    Services().api.getCountries()?.then(
      (countries) async {
        final storage = injector<LocalStorage>();
        try {
          // save the user Info as local storage
          final ready = await storage.ready;
          if (ready) {
            await storage.setItem(kLocalKey['countries']!, countries);
          }
        } catch (err) {
          printLog(err);
        }
      },
    );
  }

  @override
  Future<void> onLoadedAppConfig(String? lang, Function callback) async {
    /// Get the config from Caching
    if (kAdvanceConfig.isCaching) {
      final configCache = await Services().api.getHomeCache(lang);
      if (configCache != null) {
        callback(configCache);
      }
    }

    /// get list countries
    getListCountries();
  }

  Widget renderVariantItem(BuildContext context, String name, String? option) {
    return Row(
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50.0, maxWidth: 200),
          child: Text(
            // ignore: prefer_single_quotes
            "${name[0].toUpperCase()}${name.substring(1)} ",
          ),
        ),
        name == 'color'
            ? Expanded(
                child: Align(
                  alignment: Tools.isRTL(context)
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: HexColor(
                        kNameToHex[option!.toLowerCase()]!,
                      ),
                    ),
                  ),
                ),
              )
            : Expanded(
                child: Text(
                  option!,
                  textAlign: TextAlign.end,
                ),
              ),
      ],
    );
  }

  @override
  Widget renderVariantCartItem(
      BuildContext context, variation, Map<String, dynamic>? options) {
    var list = <Widget>[];
    if (options != null && options.isNotEmpty) {
      for (var key in options.keys) {
        list.add(renderVariantItem(context, key, '${options[key]}'));
        list.add(const SizedBox(
          height: 5.0,
        ));
      }
    } else {
      for (var att in variation.attributes) {
        list.add(renderVariantItem(context, att.name!, att.option));
        list.add(const SizedBox(
          height: 5.0,
        ));
      }
    }
    return Column(children: list);
  }

  @override
  Widget renderAddonsOptionsCartItem(
      context, List<AddonsOption>? selectedOptions) {
    if (selectedOptions?.isEmpty ?? true) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Text(
        selectedOptions!
            .map((e) => e.isFileUploadType ? e.label!.split('/').last : e.label)
            .join(', '),
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  @override
  void loadShippingMethods(context, CartModel cartModel, bool beforehand) {
//    if (!beforehand) return;
//    final cartModel = Provider.of<CartModel>(context, listen: false);
    Future.delayed(Duration.zero, () {
      final token = Provider.of<UserModel>(context, listen: false).user != null
          ? Provider.of<UserModel>(context, listen: false).user!.cookie
          : null;
      var langCode = Provider.of<AppModel>(context, listen: false).langCode;
      Provider.of<ShippingMethodModel>(context, listen: false)
          .getShippingMethods(
              cartModel: cartModel, token: token, langCode: langCode);
    });
  }

  @override
  Widget renderButtons(
      BuildContext context, Order order, cancelOrder, createRefund) {
    var isOrderRefundable = false;
    if (kPaymentConfig.refundPeriod != null) {
      if (order.createdAt!
          .add(Duration(days: kPaymentConfig.refundPeriod!.toInt()))
          .isAfter(DateTime.now())) {
        isOrderRefundable = true;
      }
    }
    return Row(
      children: <Widget>[
        if ([OrderStatus.processing, OrderStatus.onHold, OrderStatus.pending]
            .contains(order.status))
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: cancelOrder,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (order.status!.isCancelled)
                          ? Colors.blueGrey
                          : Colors.red),
                  child: Text(
                    S.of(context).cancel.toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        if (![
              OrderStatus.canceled,
              OrderStatus.cancelled,
              OrderStatus.refunded,
              OrderStatus.refundRequested,
              OrderStatus.failed,
              OrderStatus.onHold,
              OrderStatus.pending
            ].contains(order.status) &&
            isOrderRefundable)
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: createRefund,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: order.status == OrderStatus.refunded
                          ? Colors.blueGrey
                          : Colors.lightBlue),
                  child: Text(
                    S.of(context).refunds.toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }

  @override
  String? getPriceItemInCart(Product product, ProductVariation? variation,
      Map<String, dynamic> currencyRate, String? currency,
      {List<AddonsOption>? selectedOptions}) {
    if (product.isTopUpProduct()) {
      final defaultCurrency = kAdvanceConfig.defaultCurrency;
      return PriceTools.getPriceProduct(
          product, currencyRate, defaultCurrency?.currencyCode,
          onSale: false);
    }

    final hasAddons = selectedOptions?.isNotEmpty ?? false;
    final isVariableProduct = variation != null && variation.id != null;

    if (hasAddons && !isVariableProduct) {
      return PriceTools.getAddsOnPriceProductValue(
          product, selectedOptions!, currencyRate, currency,
          onSale: true);
    }

    if (isVariableProduct) {
      return PriceTools.getVariantPriceProductValue(
        variation,
        currencyRate,
        currency,
        selectedOptions: selectedOptions ?? <AddonsOption>[],
        onSale: true,
      );
    }

    return PriceTools.getPriceProduct(product, currencyRate, currency,
        onSale: true);
  }

  @override
  Future<List<Country>?> loadCountries() async {
    final storage = injector<LocalStorage>();
    List<Country>? countries = <Country>[];
    if (kDefaultCountry.isNotEmpty) {
      for (var item in kDefaultCountry) {
        countries.add(Country.fromConfig(
            item['iosCode'], item['name'], item['icon'], []));
      }
    } else {
      try {
        // save the user Info as local storage
        final ready = await storage.ready;
        if (ready) {
          final items = await storage.getItem(kLocalKey['countries']!);
          countries = ListCountry.fromOpencartJson(items).list;
        }
      } catch (err) {
        printLog(err);
      }
    }
    return countries;
  }

  @override
  Future<List<CountryState>> loadStates(Country country) async {
    final items = await Tools.loadStatesByCountry(country.id!);
    var states = <CountryState>[];
    if (items.isNotEmpty) {
      for (var item in items) {
        states.add(CountryState.fromConfig(item));
      }
    } else {
      try {
        final items = await Services().api.getStatesByCountryId(country.id);
        if (items != null && items.isNotEmpty) {
          for (var item in items) {
            states.add(CountryState.fromWooJson(item));
          }
        }
      } catch (e) {
        printLog(e.toString());
      }
    }
    return states;
  }

  @override
  Future<void> resetPassword(BuildContext context, String username) async {
    try {
      final val = await (Provider.of<UserModel>(context, listen: false)
          .submitForgotPassword(
              forgotPwLink: '', data: {'user_login': username}));
      if (val?.isEmpty ?? false) {
        Tools.showSnackBar(
            ScaffoldMessenger.of(context), S.of(context).checkConfirmLink);
        Future.delayed(
            const Duration(seconds: 1), () => Navigator.of(context).pop());
      } else {
        Tools.showSnackBar(ScaffoldMessenger.of(context), val);
      }
      return;
    } catch (e) {
      printLog('Unknown Error: $e');
    }
  }

  @override
  Future<void> syncCartFromWebsite(
      String? token, CartModel cartModel, BuildContext context) async {
    try {
      var items =
          await (Services().api.getCartInfo(token) as Future<List<dynamic>?>);
      if (items != null && items.isNotEmpty) {
        cartModel.clearCart();
        for (var item in List<Map<String, dynamic>>.from(items)) {
          cartModel.addProductToCart(
              context: context,
              product: Product.fromJson(item['product']),
              quantity: item['quantity'],
              variation: item['variation'] != null
                  ? ProductVariation.fromJson(item['variation'])
                  : null);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void>? syncCartToWebsite(CartModel cartModel) {
    if (kAdvanceConfig.enableSyncCartToWebsite && cartModel.user != null) {
      return Services().api.syncCartToWebsite(cartModel, cartModel.user);
    }
    return null;
  }

  @override
  Future<Product?>? getProductDetail(BuildContext context, Product? product) {
    return Services().api.getProduct(product!.id);
  }

  @override
  Widget renderDetailPrice(
      BuildContext context, Product product, String? price) {
    if (product.type == 'variable-subscription' ||
        product.type == 'subscription') {
      return DetailPrice(product: product, price: price);
    } else {
      return super.renderDetailPrice(context, product, price);
    }
  }

  @override
  Widget renderRecurringTotals(BuildContext context) {
    return const RecurringTotal();
  }

  @override
  Widget renderPayByWallet(BuildContext context) {
    return Services().renderWalletPayPartialPayment();
  }

  @override
  Widget renderCheckoutWalletInfo(BuildContext context) {
    return Services().renderCheckoutWalletInfo();
  }

  @override
  Future updateOrderAfterCheckout(BuildContext context, Order order) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    final walletModel = Provider.of<WalletModel>(context, listen: false);
    if (cartModel.walletAmount > 0 &&
        userModel.user != null &&
        userModel.user!.cookie != null) {
      await walletModel.partialPayment(order.id!, userModel.user!.cookie!);
    }
  }

  @override
  Widget getDeliveryScreen(context, dynamic user) {
    if (kVendorConfig['DisableDeliveryManagement'] == null ||
        !kVendorConfig['DisableDeliveryManagement']) {
      return Services().getDeliveryApp(
        user: user,
        isFromMV: true,
      );
    }
    return const SizedBox();
  }

  @override
  Widget renderPaymentMethodItem(
      BuildContext context,
      PaymentMethod paymentMethod,
      Function(String? p1) onSelected,
      String? selectedId) {
    if (paymentMethod.id == 'wallet') {
      return Services()
          .renderWalletPaymentMethodItem(paymentMethod, onSelected, selectedId);
    } else {
      return super.renderPaymentMethodItem(
          context, paymentMethod, onSelected, selectedId);
    }
  }

  @override
  Widget reOrderButton(Order order) {
    return ReOrderIndex(
      order: order,
    );
  }

  @override
  Widget productReviewWidget(String productId) {
    return ProductReviewsIndex(productId: productId);
  }
}
