import '../../../services/service_config.dart';
import '../index.dart';
import 'opencart_service.dart';

mixin OpencartMixin on ConfigMixin {
  @override
  void configOpencart(appConfig) {
    final openCartApi = OpencartService(
      domain: appConfig['url'],
      blogDomain: appConfig['blog'],
    );
    api = openCartApi;
    widget = OpencartWidget(openCartApi);
  }
}
