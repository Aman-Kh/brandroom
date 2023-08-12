import '../../../services/service_config.dart';
import '../index.dart';
import 'magento_service.dart';

mixin MagentoMixin on ConfigMixin {
  @override
  void configMagento(appConfig) {
    final magentoApi = MagentoService(
      domain: appConfig['url'],
      blogDomain: appConfig['blog'],
      accessToken: appConfig['accessToken'],
    );
    api = magentoApi;
    widget = MagentoWidget(magentoApi);
  }
}
