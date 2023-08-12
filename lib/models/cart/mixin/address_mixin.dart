import 'dart:async';

import 'package:localstorage/localstorage.dart';
import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../services/index.dart';
import '../../entities/address.dart';
import '../../entities/shipping_method.dart';
import '../../entities/user.dart';
import 'cart_mixin.dart';

mixin AddressMixin on CartMixin {
  Address? address;
  ShippingMethod? shippingMethod;

  void saveShippingAddress(Address? address) {
    final storage = injector<LocalStorage>();
    try {
      storage.setItem(kLocalKey['shippingAddress']!, address);
    } catch (_) {}
  }

  Future<Address?> getShippingAddress() async {
    if (ServerConfig().isVendorManagerType()) {
      return null;
    }
    final storage = injector<LocalStorage>();
    try {
      final json = storage.getItem(kLocalKey['shippingAddress']!);
      if (json != null) {
        return Address.fromLocalJson(json);
      } else {
        final userJson = storage.getItem(kLocalKey['userInfo']!);

        if (userJson != null) {
          var user = await Services().api.getUserInfo(userJson['cookie']);
          if (user != null) {
            user.isSocial = userJson['isSocial'] ?? false;
          } else {
            user = User.fromLocalJson(userJson);
          }

          if (user.billing == null) {
            final info = await Services().api.getCustomerInfo(user.id)!;
            if (info['billing'] != null) {
              return info['billing'];
            }
          }

          return Address(
            firstName:
                user.billing != null && user.billing!.firstName!.isNotEmpty
                    ? user.billing!.firstName
                    : user.firstName,
            lastName: user.billing != null && user.billing!.lastName!.isNotEmpty
                ? user.billing!.lastName
                : user.lastName,
            email: user.billing != null && user.billing!.email!.isNotEmpty
                ? user.billing!.email
                : user.email,
            street: user.billing != null && user.billing!.address1!.isNotEmpty
                ? user.billing!.address1
                : '',
            country: user.billing != null && isNotBlank(user.billing!.country)
                ? user.billing!.country
                : kPaymentConfig.defaultCountryISOCode,
            state: user.billing != null && user.billing!.state!.isNotEmpty
                ? user.billing!.state
                : kPaymentConfig.defaultStateISOCode,
            phoneNumber: user.billing != null && user.billing!.phone!.isNotEmpty
                ? user.billing!.phone
                : '',
            // city: user.billing != null && user.billing!.city!.isNotEmpty
            //     ? user.billing!.city
            //     : '',
            // zipCode:
            //     user.billing != null && user.billing!.postCode!.isNotEmpty
            //         ? user.billing!.postCode
            //         : '');
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void clearAddress() {
    address = null;
  }

  void setAddress(data) {
    address = data;
    saveShippingAddress(data);
  }

  Future<Address?> getAddress() async {
    address ??= await getShippingAddress();
    return address;
  }

  double? getShippingCost() {
    if (shippingMethod != null && shippingMethod!.cost! > 0) {
      return shippingMethod!.cost;
    }
    if (shippingMethod != null && isNotBlank(shippingMethod!.classCost)) {
      List items = shippingMethod!.classCost!.split('*');
      String cost = items[0] != '[qty]' ? items[0] : items[1];
      var shippingCost = double.parse(cost);
      var count = 0;

      for (var key in productsInCart.keys) {
        count += productsInCart[key]!;
      }

      return shippingCost * count;
    }
    return 0.0;
  }

  void setShippingMethod(data) {
    shippingMethod = data;
  }
}
