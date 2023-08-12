import 'package:flutter/material.dart';
import 'package:inspireui/widgets/coupon_card.dart' show Coupon;
import 'package:inspireui/widgets/expandable/expansion_widget.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/entities/filter_sorty_by.dart';
import '../../models/index.dart';
import '../../services/index.dart';
import '../../widgets/common/group_check_box_widget.dart';
import '../frameworks.dart';
import '../product_variant_mixin.dart';
import 'magento_payment.dart';
import 'magento_variant_mixin.dart';
import 'services/magento_service.dart';

class MagentoWidget extends BaseFrameworks
    with ProductVariantMixin, MagentoVariantMixin {
  final MagentoService api;

  MagentoWidget(this.api);

  @override
  bool get enableProductReview => false;

  @override
  Future<void> applyCoupon(context,
      {Coupons? coupons,
      String? code,
      Function? success,
      Function? error}) async {
    try {
      final cartModel = Provider.of<CartModel>(context, listen: false);
      final userModel = Provider.of<UserModel>(context, listen: false);
      await api.addItemsToCart(
          cartModel, userModel.user != null ? userModel.user!.cookie : null);
      final discountAmount = await api.applyCoupon(
          userModel.user != null ? userModel.user!.cookie : null, code);
      cartModel.discountAmount = discountAmount;
      var discount = Discount();
      discount.coupon = Coupon.fromJson({
        'amount': discountAmount,
        'code': code,
        'discount_type': 'fixed_cart'
      });
      discount.discountValue = discountAmount;
      success!(discount);
    } catch (err) {
      error!(err.toString());
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
      if (cartModel.couponObj != null) {
        final discountAmount = await api.applyCoupon(
            userModel.user != null ? userModel.user!.cookie : null,
            cartModel.couponObj!.code);
        cartModel.discountAmount = discountAmount;
      }
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
    final storage = LocalStorage(LocalStorageKey.dataOrder);
    var listOrder = [];
    var isLoggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);

    try {
      onLoading!(true);
      final order = await Services().api.createOrder(
          cartModel: cartModel,
          user: userModel,
          paid: paid,
          transactionId: transactionId)!;

      if (!isLoggedIn) {
        var items = storage.getItem('orders');
        if (items != null) {
          listOrder = items;
        }
        listOrder.add(order.toOrderJson(cartModel, null));
        await storage.setItem('orders', listOrder);
      }
      if (kMagentoPayments.contains(cartModel.paymentMethod!.id)) {
        onLoading(false);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MagentoPayment(
                    onFinish: (order) => success!(order),
                    order: order,
                  )),
        );
      } else {
        success!(order);
      }
    } catch (e, trace) {
      error!(e.toString());
      printLog(trace.toString());
    }
  }

  @override
  void placeOrder(
    context, {
    CartModel? cartModel,
    PaymentMethod? paymentMethod,
    Function? onLoading,
    Function? success,
    Function? error,
  }) {
    Provider.of<CartModel>(context, listen: false)
        .setPaymentMethod(paymentMethod);
    printLog(paymentMethod!.id);

    createOrder(context,
        cod: true, onLoading: onLoading, success: success, error: error);
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
    if (currentPassword.isEmpty && !loggedInUser!.isSocial!) {
      onError('Please enter current password');
      return;
    }

    var params = {
      'user_id': loggedInUser!.id,
      'display_name': userDisplayName,
      'user_email': userEmail,
      'user_nicename': userNiceName,
      'user_url': userUrl,
    };
    if (userEmail == loggedInUser.email && !loggedInUser.isSocial!) {
      params['user_email'] = '';
    }
    if (!loggedInUser.isSocial! && userPassword!.isNotEmpty) {
      params['user_pass'] = userPassword;
    }
    if (!loggedInUser.isSocial! && currentPassword.isNotEmpty) {
      params['current_pass'] = currentPassword;
    }
    Services().api.updateUserInfo(params, loggedInUser.cookie)!.then((value) {
      var param = {
        'firstname': loggedInUser.firstName,
        'lastname': loggedInUser.lastName,
        'id': loggedInUser.id,
        'email': userEmail == '' ? loggedInUser.email : userEmail
      };
      onSuccess!(User.fromMagentoJson(param, loggedInUser.cookie));
    }).catchError((e) {
      onError(e.toString());
    });
  }

  @override
  Widget renderCurrentPassInputforEditProfile(
      {BuildContext? context,
      TextEditingController? currentPasswordController}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(S.of(context!).currentPassword,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            )),
        const SizedBox(
          height: 5,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: Theme.of(context).primaryColorLight, width: 1.5)),
          child: TextField(
            obscureText: true,
            decoration: const InputDecoration(border: InputBorder.none),
            controller: currentPasswordController,
          ),
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }

  void getListCountries() {
    api.getCountries().then((countries) async {
      final countries = await api.getCountries();
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
    });
  }

  void getAllAttributes() {
    api.getAllAttributes().then((value) {}).catchError((err) {});
  }

  @override
  Future<void> onLoadedAppConfig(String? lang, Function callback) async {
    getAllAttributes();
    getListCountries();
  }

  @override
  Widget renderVariantCartItem(
      BuildContext context, variation, Map<String, dynamic>? options) {
    return const SizedBox();
  }

  @override
  void loadShippingMethods(context, CartModel cartModel, bool beforehand) {
//    if (!beforehand) return;
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
  Widget renderButtons(
      BuildContext context, Order order, cancelOrder, createRefund) {
    return Row(
      children: <Widget>[
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
                  'Cancel'.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  String? getPriceItemInCart(Product product, ProductVariation? variation,
      Map<String, dynamic> currencyRate, String? currency,
      {List<AddonsOption>? selectedOptions}) {
    return variation != null && variation.id != null
        ? PriceTools.getVariantPriceProductValue(
            variation,
            currencyRate,
            currency,
            onSale: true,
            selectedOptions: selectedOptions,
          )
        : PriceTools.getPriceProduct(product, currencyRate, currency,
            onSale: true);
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
        countries = ListCountry.fromMagentoJson(items).list;
      }
    } catch (err) {
      printLog(err);
    }
    return countries;
  }

  @override
  Future<List<CountryState>> loadStates(Country country) async {
    return country.states ?? [];
  }

  @override
  Future<void> resetPassword(BuildContext context, String username) async {
    try {
      var isSuccess = await api.resetPassword(username);
      if (isSuccess == true) {
        Tools.showSnackBar(
            ScaffoldMessenger.of(context), 'Success Please Check Your Email');
        Future.delayed(
            const Duration(seconds: 2), () => Navigator.of(context).pop());
      } else {
        Tools.showSnackBar(
            ScaffoldMessenger.of(context), 'Please Enter Correct Email');
      }
      return;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Product?> getProductDetail(context, Product? product) async {
    try {
      product!.inStock = await api.getStockStatus(product.sku);
      return product;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void onFinishOrder(
      BuildContext context, Function onSuccess, Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MagentoPayment(
                onFinish: (order) {
                  onSuccess(order);
                },
                order: order,
              )),
    );
  }

  @override
  Widget renderFilterSortBy(
    BuildContext context, {
    FilterSortBy? filterSortBy,
    required Function(FilterSortBy? filterSortBy) onFilterChanged,
    bool showDivider = true,
    bool isBlog = false,
  }) {
    return ExpansionWidget(
      showDivider: showDivider,
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 15,
        bottom: 10,
      ),
      title: Text(
        'Sort by',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      children: [
        GroupCheckBoxWidget<String>(
          numberOfRow: 2,
          childAspectRatio: 16 / 4,
          defaultValue: filterSortBy?.groupOrderBy,
          onChanged: (selectedItem) {
            final filterData = selectedItem?.value.split('-');
            final orderBy = filterData?[0];
            final order = filterData?[1];
            filterSortBy =
                filterSortBy?.applyOrderBy(orderBy).applyOrder(order);
            onFilterChanged(filterSortBy);
          },
          values: <GroupCheckBoxItem<String>>{
            GroupCheckBoxItem(
              title: S.of(context).dateLatest,
              value: 'date-desc',
            ),
            GroupCheckBoxItem(
              title: S.of(context).dateOldest,
              value: 'date-asc',
            ),
          },
        ),
      ],
    );
  }
}
