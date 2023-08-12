import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:inspireui/widgets/coupon_card.dart' show Coupon;
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

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
import '../../screens/index.dart' show PaymentWebview;
import '../../services/index.dart';
import '../../widgets/html/index.dart';
import '../frameworks.dart';
import '../product_variant_mixin.dart';
import 'opencart_variant_mixin.dart';
import 'services/opencart_service.dart';

class OpencartWidget extends BaseFrameworks
    with ProductVariantMixin, OpencartVariantMixin {
  final OpencartService api;

  OpencartWidget(this.api);

  @override
  bool get enableProductReview => true;

  Future<Discount?> checkValidCoupon(
      BuildContext context, Coupon coupon, String couponCode) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    Discount? discount;
    if (coupon.code!.toLowerCase() == couponCode) {
      discount = Discount(coupon: coupon, discountValue: coupon.amount);
    }
    if (discount?.discountValue != null) {
      await cartModel.updateDiscount(discount: discount);
    }

    return discount;
  }

  @override
  Future<void> applyCoupon(
    context, {
    Coupons? coupons,
    String? code,
    Function? success,
    Function? error,
  }) async {
    var isExisted = false;
    for (var coupon in coupons!.coupons) {
      var discount =
          await checkValidCoupon(context, coupon, code!.toLowerCase());
      if (discount != null) {
        success!(discount);
        isExisted = true;
        break;
      }
    }
    if (!isExisted) {
      error!(S.of(context).couponInvalid);
    }
  }

  @override
  Future<void> doCheckout(context,
      {Function? success, Function? error, Function? loading}) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    try {
      await api.addItemsToCart(
          cartModel, userModel.user != null ? userModel.user!.cookie : null);
      success!();
    } catch (e, trace) {
      error!(e.toString());
      printLog(trace.toString());
    }
  }

  @override
  Future<void> createOrder(context,
      {Function? onLoading,
      Function? success,
      Function? error,
      paid = false,
      cod = false,
      bacs = false,
      transactionId = ''}) async {
    var listOrder = [];
    var isLoggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    final storage = LocalStorage(LocalStorageKey.dataOrder);
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);

    try {
      onLoading!(true);
      final order = await Services()
          .api
          .createOrder(cartModel: cartModel, user: userModel, paid: paid)!;

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
      error!(e.toString());
      printLog(trace.toString());
    }
  }

  @override
  void placeOrder(context,
      {CartModel? cartModel,
      PaymentMethod? paymentMethod,
      Function? onLoading,
      Function? success,
      Function? error}) {
    if (paymentMethod!.id == 'cod') {
      createOrder(context,
          cod: true, onLoading: onLoading, success: success, error: error);
    } else {
      onLoading!(false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebview(onFinish: (number) {
            success!(number != null ? Order(number: number) : null);
          }),
        ),
      );
    }
  }

  @override
  Map<String, dynamic> getPaymentUrl(context) {
    var sessionId = api.cookie!.split(';')[0].replaceAll('OCSESSID=', '');
    return {
      'url':
          '${ServerConfig().url}/index.php?route=extension/mstore/payment/paymentWebview&mySessionId=$sessionId'
    };
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
      onSuccess!(User.fromOpencartJson(value!, loggedInUser.cookie));
    }).catchError((e) {
      onError(e.toString());
    });
  }

  void getListCountries() {
    /// Get List Countries
    api.getCountries().then(
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
    getListCountries();
  }

  @override
  Widget renderVariantCartItem(
      BuildContext context, variation, Map<String, dynamic>? options) {
    return Container();
  }

  @override
  void loadShippingMethods(context, CartModel cartModel, bool beforehand) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    Future.delayed(Duration.zero, () {
      final token = Provider.of<UserModel>(context, listen: false).user != null
          ? Provider.of<UserModel>(context, listen: false).user!.cookie
          : null;
      var langCode = Provider.of<AppModel>(context, listen: false).langCode;
      Provider.of<ShippingMethodModel>(context, listen: false)
          .getShippingMethods(
              cartModel: cartModel,
              token: token,
              checkoutId: cartModel.getCheckoutId(),
              langCode: langCode);
    });
  }

  @override
  String? getPriceItemInCart(Product product, ProductVariation? variation,
      Map<String, dynamic> currencyRate, String? currency,
      {List<AddonsOption>? selectedOptions}) {
    return PriceTools.getCurrencyFormatted(
        variation != null ? variation.price : product.price, currencyRate,
        currency: currency);
  }

  @override
  Future<List<Country>?> loadCountries() async {
    final storage = injector<LocalStorage>();
    List<Country>? countries = <Country>[];
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
    return countries;
  }

  @override
  Future<List<CountryState>> loadStates(Country country) async {
    final items = await api.getStatesByCountryId(country.id);
    var states = <CountryState>[];
    if (items != null && items.isNotEmpty) {
      for (var item in items) {
        states.add(CountryState.fromOpencartJson(item));
      }
    }
    return states;
  }

  @override
  Future<void> resetPassword(BuildContext context, String username) {
    throw Exception('No Support');
  }

  @override
  Widget renderShippingPaymentTitle(BuildContext context, String title) {
    return HtmlWidget(
      title,
    );
  }

  @override
  Future<String?> getCountryName(context, countryCode) async {
    try {
      var countries = await loadCountries();
      if (countries != null) {
        var country = countries.firstWhereOrNull((element) =>
            element.id == countryCode || element.code == countryCode);
        return country != null ? country.name : countryCode;
      } else {
        return 'No Name';
      }
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget renderOrderTimelineTracking(BuildContext context, Order order) {
    return Container();
  }

  Widget renderOptionItem(Product product, String optionId, optionValue) {
    Map? option = product.options!.firstWhereOrNull(
        (element) => element['product_option_id'] == optionId);
    String name = option != null ? option['name'] : optionId;
    String? value = '';
    if (option != null &&
        option['product_option_value'] != null &&
        option['product_option_value'] is List) {
      if (optionValue != null && optionValue is List) {
        for (var valueItem in List.from(optionValue)) {
          Map? pOptionValue = List.from(option['product_option_value'])
              .firstWhere(
                  (element) => element['product_option_value_id'] == valueItem,
                  orElse: () => null);
          value = pOptionValue != null ? pOptionValue['name'] : valueItem;
        }
      } else {
        Map? pOptionValue = List.from(option['product_option_value'])
            .firstWhere(
                (element) => element['product_option_value_id'] == optionValue,
                orElse: () => null);
        value = pOptionValue != null ? pOptionValue['name'] : optionValue;
      }
    } else {
      value = optionValue != null && optionValue is List
          ? List.from(optionValue).join(',')
          : optionValue;
    }
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
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: HexColor(
                        kNameToHex[value!.toLowerCase()]!,
                      ),
                    ),
                  ),
                ),
              )
            : Expanded(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                ),
              ),
      ],
    );
  }

  @override
  Widget renderOptionsCartItem(Product product, Map<String, dynamic>? options) {
    var list = <Widget>[];
    if (options != null && options.isNotEmpty) {
      for (var optionId in options.keys) {
        list.add(renderOptionItem(product, optionId, options[optionId]));
        list.add(const SizedBox(
          height: 5.0,
        ));
      }
    }
    return Column(children: list);
  }
}
