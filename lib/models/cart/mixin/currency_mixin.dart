import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../services/index.dart';
import 'cart_mixin.dart';

mixin CurrencyMixin on CartMixin {
  Future getCurrency() async {
    try {
      var prefs = injector<SharedPreferences>();
      currencyCode = prefs.getString('currencyCode') ??
          kAdvanceConfig.defaultCurrency?.currencyCode;
    } catch (e) {
      currencyCode = 'SYP';
    }
  }

  void changeCurrency(value) {
    currencyCode = value;
  }

  void changeCurrencyRates(value) {
    currencyRates = value;
  }
}
