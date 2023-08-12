import '../../../services/index.dart';
import '../../../services/service_config.dart';
import '../../../services/wallet/tera_wallet_service_locator.dart'
    show TeraWalletServiceLocator;
import '../index.dart';
import 'woo_commerce.dart';

mixin WooMixin on ConfigMixin {
  @override
  void configWoo(appConfig) {
    final wooService = WooCommerceService(
      domain: appConfig['url'],
      blogDomain: appConfig['blog'],
      consumerSecret: appConfig['consumerSecret'],
      consumerKey: appConfig['consumerKey'],
    );
    TeraWalletServiceLocator.setup(appConfig['url']);
    api = wooService;
    widget = WooWidget();
  }
}
