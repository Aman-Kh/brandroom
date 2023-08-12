// import '../common/config.dart';
import '../common/constants.dart';
import '../frameworks/magento/services/magento_mixin.dart';
import '../frameworks/opencart/services/opencart_mixin.dart';
import '../frameworks/woocommerce/services/woo_mixin.dart';
import '../frameworks/wordpress/services/wordpress_mixin.dart';
import '../modules/advertisement/index.dart' show AdvertisementServiceImpl;
import '../modules/digits_mobile_login/services/digits_mobile_login_service_mixin.dart';
import '../modules/firebase/firebase_notification_service.dart';
import '../modules/firebase/firebase_service.dart';
// import '../modules/onesignal/one_signal_notification_service.dart';
import '../modules/tera_wallet/services/wallet_service_mixin.dart';
import 'advertisement/advertisement_service.dart';
import 'notification/notification_service.dart';
import 'notification/notification_service_impl.dart';
import 'service_config.dart';

export 'base_remote_config.dart';

class Services
    with
        ConfigMixin,
        WooMixin,
        MagentoMixin,
        OpencartMixin,
        WordPressMixin,
        WalletServiceMixin,
        DigitsMobileLoginServiceMixin {
  static final Services _instance = Services._internal();

  factory Services() => _instance;

  Services._internal();

  /// using BaseFirebaseServices when disable the Firebase
  // final firebase = BaseFirebaseServices();
  final firebase = FirebaseServices();

  /// using AdvertisementService when disable the Advertisement
  // final AdvertisementService advertisement = AdvertisementService();
  final AdvertisementService advertisement = AdvertisementServiceImpl();

  /// Get notification Service
  static NotificationService getNotificationService() {
    NotificationService notificationService = NotificationServiceImpl();
    if (isIos || isAndroid) {
      if (_instance.firebase.isEnabled) {
        notificationService = FirebaseNotificationService();
      }
      // if (kOneSignalKey['enable'] ?? false) {
      //   notificationService =
      //       OneSignalNotificationService(appID: kOneSignalKey['appID']);
      // } else {

      // }
      // }
    }
    return notificationService;
  }
}
