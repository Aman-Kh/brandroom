import 'dart:async';
import 'dart:convert' as convert;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/config.dart';
import '../common/config/models/index.dart';
import '../common/constants.dart';
import '../modules/dynamic_layout/config/app_config.dart';
import '../services/index.dart';
import 'advertisement/index.dart' show AdvertisementConfig;
import 'cart/cart_model.dart';
import 'category/category_model.dart';

class AppModel with ChangeNotifier {
  AppConfig? appConfig;
  AdvertisementConfig advertisement = const AdvertisementConfig();
  Map? deeplink;
  late bool isMultivendor;

  /// Loading State setting
  bool isLoading = true;
  bool isInit = false;

  /// Current and Payment settings
  String? currency;
  String? currencyCode;
  Map<String, dynamic> currencyRate = <String, dynamic>{};
  int? smallestUnitRate;

  /// Language Code
  String _langCode = kAdvanceConfig.defaultLanguage;

  String get langCode => _langCode;

  /// Theming values for light or dark theme mode
  ThemeMode? themeMode;

  bool get darkTheme => themeMode == ThemeMode.dark;

  set darkTheme(bool value) =>
      themeMode = value ? ThemeMode.dark : ThemeMode.light;

  ThemeConfig get themeConfig => darkTheme ? kDarkConfig : kLightConfig;

  /// The app will use mainColor from env.dart,
  /// or override it with mainColor from config JSON if found.
  String get mainColor {
    final configJsonMainColor = appConfig?.settings.mainColor;
    if (configJsonMainColor != null && configJsonMainColor.isNotEmpty) {
      return configJsonMainColor;
    }
    return themeConfig.mainColor;
  }

  /// Product and Category Layout setting
  List<String>? categories;
  List<Map>? remapCategories;
  Map? categoriesIcons;
  String categoryLayout = '';

  String get productListLayout => appConfig!.settings.productListLayout;

  double get ratioProductImage =>
      appConfig!.settings.ratioProductImage ??
      (kAdvanceConfig.ratioProductImage * 1.0);

  String get productDetailLayout =>
      appConfig!.settings.productDetail ?? kProductDetail.layout;

  kBlogLayout get blogDetailLayout => appConfig!.settings.blogDetail != null
      ? kBlogLayout.values.byName(appConfig!.settings.blogDetail!)
      : kAdvanceConfig.detailedBlogLayout;

  /// App Model Constructor
  AppModel([String? lang]) {
    _langCode = lang ?? kAdvanceConfig.defaultLanguage;

    advertisement = AdvertisementConfig.fromJson(adConfig: kAdConfig);
    isMultivendor = ServerConfig().typeName.isMultiVendor;
  }

  void _updateAndSaveDefaultLanguage(String? lang) async {
    var prefs = injector<SharedPreferences>();
    final prefLang = prefs.getString('language');
    _langCode = prefLang != null && prefLang.isNotEmpty
        ? prefLang
        : lang ?? kAdvanceConfig.defaultLanguage;
    await prefs.setString('language', _langCode.split('-').first.toLowerCase());
  }

  /// Get persist config from Share Preference
  Future<bool> getPrefConfig({String? lang}) async {
    try {
      _updateAndSaveDefaultLanguage(lang);

      var prefs = injector<SharedPreferences>();
      var defaultCurrency = kAdvanceConfig.defaultCurrency;

      darkTheme = prefs.getBool('darkTheme') ?? kDefaultDarkTheme;
      currency =
          prefs.getString('currency') ?? defaultCurrency?.currencyDisplay;
      currencyCode =
          prefs.getString('currencyCode') ?? defaultCurrency?.currencyCode;
      smallestUnitRate = defaultCurrency?.smallestUnitRate;
      isInit = true;
      await updateTheme(darkTheme);

      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> changeLanguage(String languageCode, BuildContext context) async {
    try {
      _langCode = languageCode;
      var prefs = injector<SharedPreferences>();
      await prefs.setString('language', _langCode);

      await loadAppConfig(isSwitched: true);
      await loadCurrency();
      eventBus.fire(const EventChangeLanguage());

      await Provider.of<CategoryModel>(context, listen: false).getCategories(
        lang: languageCode,
        sortingList: categories,
        remapCategories: remapCategories,
      );

      return true;
    } catch (err) {
      return false;
    }
  }

  Future<void> changeCurrency(String? item, BuildContext context,
      {String? code}) async {
    try {
      Provider.of<CartModel>(context, listen: false)
          .changeCurrency(code ?? item);
      var prefs = injector<SharedPreferences>();
      currency = item;
      currencyCode = code;
      await prefs.setString('currencyCode', currencyCode!);
      await prefs.setString('currency', currency!);
      notifyListeners();
    } catch (error) {
      printLog('[changeCurrency] error: ${error.toString()}');
    }
  }

  Future<void> updateTheme(bool theme) async {
    try {
      var prefs = injector<SharedPreferences>();
      darkTheme = theme;
      await prefs.setBool('darkTheme', theme);
      notifyListeners();
    } catch (error) {
      printLog('[updateTheme] error: ${error.toString()}');
    }
  }

  void loadStreamConfig(config) {
    appConfig = AppConfig.fromJson(config);
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCloudAppConfig(String url) async {
    final appJson = await httpGet(Uri.encodeFull(url).toUri()!,
        headers: {'Accept': 'application/json'});
    appConfig = AppConfig.fromJson(
        convert.jsonDecode(convert.utf8.decode(appJson.bodyBytes)));
  }

  Future<AppConfig?> loadAppConfig(
      {isSwitched = false, Map<String, dynamic>? config}) async {
    var startTime = DateTime.now();

    if (_langCode == '') {
      _langCode = kAdvanceConfig.defaultLanguage;
    }

    try {
      if (!isInit || _langCode.isEmpty) {
        await getPrefConfig();
      }

      if (config != null) {
        appConfig = AppConfig.fromJson(config);
      } else {
        var loadAppConfigDone = false;

        // // new fix
        // await loadCurrency();

        /// load config from Notion
        if (ServerConfig().type == ConfigType.notion) {
          final appCfg = await Services().widget.onGetAppConfig(langCode);

          if (appCfg != null) {
            appConfig = appCfg;
            loadAppConfigDone = true;
          }
        }

        if (loadAppConfigDone == false) {
          /// we only apply the http config if isUpdated = false, not using switching language
          // ignore: prefer_contains
          if (kAppConfig.indexOf('http') != -1) {
            // load on cloud config and update on air
            var path = kAppConfig;
            if (path.contains('.json')) {
              path = path.substring(0, path.lastIndexOf('/'));
              path += '/config_$langCode.json';
            }
            try {
              await fetchCloudAppConfig(path);
            } catch (_) {
              /// In case config_$langCode.json is not found,
              /// load user's original config URL.
              printLog(
                  '🚑 Config at $path not found. Loading from $kAppConfig instead.');
              await fetchCloudAppConfig(kAppConfig);
            }
          } else {
            // load local config
            var path = 'lib/config/config_$langCode.json';
            try {
              final appJson = await rootBundle.loadString(path);
              appConfig = AppConfig.fromJson(convert.jsonDecode(appJson));
            } catch (e) {
              final appJson = await rootBundle.loadString(kAppConfig);
              appConfig = AppConfig.fromJson(convert.jsonDecode(appJson));
            }
          }
        }
      }

      /// apply App Caching if isCaching is enable
      /// not use for Fluxbuilder
      if (!ServerConfig().isBuilder) {
        await Services().widget.onLoadedAppConfig(langCode, (configCache) {
          appConfig = AppConfig.fromJson(configCache);
        });
      }

      /// Load categories config for the Tabbar menu
      /// User to sort the category Setting
      final categoryTab = appConfig!.tabBar.toList().firstWhereOrNull(
          (e) => e.layout == 'category' || e.layout == 'vendors');
      if (categoryTab != null) {
        if (categoryTab.categories != null) {
          categories = List<String>.from(categoryTab.categories ?? []);
        }
        if (categoryTab.images != null) {
          categoriesIcons =
              categoryTab.images is Map ? Map.from(categoryTab.images) : null;
        }
        if (categoryTab.remapCategories != null) {
          remapCategories = categoryTab.remapCategories;
        }
        categoryLayout = categoryTab.categoryLayout;
      }

      if (appConfig?.settings.tabBarConfig.alwaysShowTabBar != null) {
        Configurations().setAlwaysShowTabBar(
            appConfig?.settings.tabBarConfig.alwaysShowTabBar ?? false);
      }
      isLoading = false;

      notifyListeners();
      printLog('[Debug] Finish Load AppConfig', startTime);
      return appConfig;
    } catch (err, trace) {
      printLog('🔴 AppConfig JSON loading error');
      printLog(err);
      printLog(trace);
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadCurrency({Function(Map<String, dynamic>)? callback}) async {
    /// Load the Rate for Product Currency
    final rates = await Services().api.getCurrencyRate();
    if (rates != null) {
      currencyRate = rates;
      callback?.call(rates);
    }
  }

  void updateProductListLayout(layout) {
    appConfig!.settings =
        appConfig!.settings.copyWith(productListLayout: layout);
    notifyListeners();
  }

  void raiseNotify() {
    notifyListeners();
  }
}
