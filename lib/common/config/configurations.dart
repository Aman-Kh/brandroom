part of '../config.dart';

class Configurations {
  static String _environment = DefaultConfig.environment;
  static String _baseUrl = DefaultConfig.baseUrl;
  static String _appName = DefaultConfig.appName;
  static bool _enableCrashAnalytics = DefaultConfig.enableCrashAnalytics;
  static bool _enableRemoteConfigFirebase =
      DefaultConfig.enableRemoteConfigFirebase;
  static String _defaultLanguage = DefaultConfig.defaultLanguage;
  static Map _serverConfig = DefaultConfig.serverConfig;
  static String _appConfig = DefaultConfig.appConfig;
  static bool _defaultDarkTheme = DefaultConfig.defaultDarkTheme;
  static String _countryCodeDefault = DefaultConfig.countryCodeDefault;
  static String _dialCodeDefault = DefaultConfig.dialCodeDefault;
  static String _nameDefault = DefaultConfig.nameDefault;
  static Map _advanceConfig = DefaultConfig.advanceConfig;
  static Map _storeIdentifier = DefaultConfig.storeIdentifier;
  static List _defaultSettings = DefaultConfig.defaultSettings;
  static Map _loginSetting = DefaultConfig.loginSetting;
  static Map _defaultDrawer = DefaultConfig.defaultDrawer;
  static Map _oneSignalKey = DefaultConfig.oneSignalKey;
  static List _onBoardingData = DefaultConfig.onBoardingData;
  static List _vendorOnBoardingData = DefaultConfig.vendorOnBoardingData;
  static Map _productDetail = DefaultConfig.productDetail;
  static Map _blogDetail = DefaultConfig.blogDetail;
  static Map _productVariantLayout = DefaultConfig.productVariantLayout;
  static Map _adConfig = DefaultConfig.adConfig;
  static Map _firebaseDynamicLinkConfig =
      DefaultConfig.firebaseDynamicLinkConfig;
  static List<Map> _languagesInfo = DefaultConfig.languagesInfo;
  static Map _paymentConfig = DefaultConfig.paymentConfig;
  static Map _payments = DefaultConfig.payments;
  static Map _stripeConfig = DefaultConfig.stripeConfig;
  static Map _paypalConfig = DefaultConfig.paypalConfig;
  static Map _razorpayConfig = DefaultConfig.razorpayConfig;
  static Map _tapConfig = DefaultConfig.tapConfig;
  static Map _payTmConfig = DefaultConfig.payTmConfig;
  static Map _payStackConfig = DefaultConfig.payStackConfig;
  static Map _flutterwaveConfig = DefaultConfig.flutterwaveConfig;
  static Map _myFatoorahConfig = DefaultConfig.myFatoorahConfig;
  static Map _mercadoPagoConfig = DefaultConfig.mercadoPagoConfig;
  static Map _afterShip = DefaultConfig.afterShip;
  static Map _productAddons = DefaultConfig.productAddons;
  static Map _cartDetail = DefaultConfig.cartDetail;
  static Map _productVariantLanguage = DefaultConfig.productVariantLanguage;
  static Map _saleOffProduct = DefaultConfig.saleOffProduct;
  static int _excludedCategory = DefaultConfig.excludedCategory;
  static bool _notStrictVisibleVariant = DefaultConfig.notStrictVisibleVariant;
  static Map _configChat = DefaultConfig.configChat;
  static List<Map> _smartChat = DefaultConfig.smartChat;
  static String _adminEmail = DefaultConfig.adminEmail;
  static String _adminName = DefaultConfig.adminName;
  static Map _vendorConfig = DefaultConfig.vendorConfig;
  static List<AddressFieldConfig> _addressFields = DefaultConfig.addressFields;
  static List _defaultCountryShipping = DefaultConfig.defaultCountryShipping;
  static Map? _loadingIcon = DefaultConfig.loadingIcon;
  static Map _productCard = DefaultConfig.productCard;
  static Map _loginSMSConstants = DefaultConfig.loginSMSConstants;
  static Map _darkConfig = DefaultConfig.darkConfig;
  static Map _lightConfig = DefaultConfig.lightConfig;
  static String _version = DefaultConfig.version;
  static Map _subGeneralSetting = DefaultConfig.subGeneralSetting;
  static Map _splashScreen = DefaultConfig.splashScreen;
  static Map _colorOverrideConfig = DefaultConfig.colorOverrideConfig;
  static GoogleApiKeyConfig _googleApiKey = DefaultConfig.googleApiKey;
  static bool _enableOnBoarding = DefaultConfig.enableOnBoarding;
  static Map? _managerConfig;
  static Map? _deliveryConfig;

  /// only support firebase remote config
  static Map<String, dynamic>? _layoutDesign;

  static String get environments => _environment;

  static String get version => _version;

  static String get baseUrl => _baseUrl;

  static String get appName => _appName;

  static bool get enableCrashAnalytics => _enableCrashAnalytics;

  static bool get enableRemoteConfigFirebase => _enableRemoteConfigFirebase;

  static String get defaultLanguage => _defaultLanguage;

  static Map get serverConfig => _serverConfig;

  static String get appConfig => _appConfig;

  static bool get defaultDarkTheme => _defaultDarkTheme;

  static String get countryCodeDefault => _countryCodeDefault;

  static String get dialCodeDefault => _dialCodeDefault;

  static String get nameDefault => _nameDefault;

  static Map get advanceConfig => _advanceConfig;

  static Map get storeIdentifier => _storeIdentifier;

  static List get defaultSettings => _defaultSettings;

  static Map get loginSetting => _loginSetting;

  static Map get defaultDrawer => _defaultDrawer;

  static Map get oneSignalKey => _oneSignalKey;

  static List get onBoardingData => _onBoardingData;

  static List get vendorOnBoardingData => _vendorOnBoardingData;

  static Map get productDetail => _productDetail;

  static Map get blogDetail => _blogDetail;

  static Map get productVariantLayout => _productVariantLayout;

  static Map get adConfig => _adConfig;

  static Map get firebaseDynamicLinkConfig => _firebaseDynamicLinkConfig;

  static List<Map> get languagesInfo => _languagesInfo;

  static Map get paymentConfig => _paymentConfig;

  static Map get payments => _payments;

  static Map get stripeConfig => _stripeConfig;

  static Map get paypalConfig => _paypalConfig;

  static Map get razorpayConfig => _razorpayConfig;

  static Map get tapConfig => _tapConfig;

  static Map get payTmConfig => _payTmConfig;

  static Map get payStackConfig => _payStackConfig;

  static Map get flutterwaveConfig => _flutterwaveConfig;

  static Map get myFatoorahConfig => _myFatoorahConfig;

  static Map get mercadoPagoConfig => _mercadoPagoConfig;

  static Map get afterShip => _afterShip;

  static Map get productAddons => _productAddons;

  static Map get cartDetail => _cartDetail;

  static Map get productVariantLanguage => _productVariantLanguage;

  static Map get saleOffProduct => _saleOffProduct;

  static int get excludedCategory => _excludedCategory;

  static bool get notStrictVisibleVariant => _notStrictVisibleVariant;

  static Map get configChat => _configChat;

  static List<Map> get smartChat => _smartChat;

  static String get adminEmail => _adminEmail;

  static String get adminName => _adminName;

  static Map get vendorConfig => _vendorConfig;

  static List<AddressFieldConfig> get addressFields => _addressFields;

  static List get defaultCountryShipping => _defaultCountryShipping;

  static Map? get loadingIcon => _loadingIcon;

  static Map get productCard => _productCard;

  static Map get loginSMSConstants => _loginSMSConstants;

  static Map get darkConfig => _darkConfig;

  static Map get lightConfig => _lightConfig;

  static Map get subGeneralSetting => _subGeneralSetting;

  static Map get splashScreen => _splashScreen;

  static Map get colorOverrideConfig => _colorOverrideConfig;

  static GoogleApiKeyConfig get googleApiKey => _googleApiKey;

  static Map<String, dynamic>? get layoutDesign => _layoutDesign;

  static bool get enableOnBoarding => _enableOnBoarding;

  static Map? get managerConfig => _managerConfig;

  static Map? get deliveryConfig => _deliveryConfig;

  void setConfigurationValues(Map<String, dynamic> value) {
    _environment = value['environment'] ?? DefaultConfig.environment;
    _baseUrl = value['baseUrl'] ?? DefaultConfig.baseUrl;
    _appName = value['app_name'] ?? DefaultConfig.appName;
    _enableCrashAnalytics =
        value['enableCrashAnalytics'] ?? DefaultConfig.enableCrashAnalytics;
    _enableRemoteConfigFirebase = value['enableRemoteConfigFirebase'] ??
        DefaultConfig.enableRemoteConfigFirebase;
    _defaultLanguage =
        value['defaultLanguage'] ?? DefaultConfig.defaultLanguage;
    _appConfig = value['appConfig'] ?? DefaultConfig.appConfig;
    _serverConfig = value['serverConfig'] ?? DefaultConfig.serverConfig;
    _defaultDarkTheme =
        value['defaultDarkTheme'] ?? DefaultConfig.defaultDarkTheme;
    _storeIdentifier =
        value['storeIdentifier'] ?? DefaultConfig.storeIdentifier;
    _advanceConfig = value['advanceConfig'] != null
        ? Map.from(value['advanceConfig'])
        : DefaultConfig.advanceConfig;
    _countryCodeDefault = DefaultConfig.countryCodeDefault;
    _dialCodeDefault = DefaultConfig.dialCodeDefault;
    _nameDefault = DefaultConfig.nameDefault;
    _defaultSettings =
        value['defaultSettings'] ?? DefaultConfig.defaultSettings;
    _loginSetting = value['loginSetting'] ?? DefaultConfig.loginSetting;
    _defaultDrawer = value['defaultDrawer'] ?? DefaultConfig.defaultDrawer;
    _oneSignalKey = value['oneSignalKey'] ?? DefaultConfig.oneSignalKey;
    _onBoardingData = value['onBoardingData'] ?? DefaultConfig.onBoardingData;
    _vendorOnBoardingData =
        value['vendorOnBoardingData'] ?? DefaultConfig.vendorOnBoardingData;
    _productDetail = value['productDetail'] ?? DefaultConfig.productDetail;
    _blogDetail = value['blogDetail'] ?? DefaultConfig.blogDetail;
    _productVariantLayout =
        value['productVariantLayout'] ?? DefaultConfig.productVariantLayout;
    _adConfig = value['adConfig'] ?? DefaultConfig.adConfig;
    _firebaseDynamicLinkConfig = value['firebaseDynamicLinkConfig'] ??
        DefaultConfig.firebaseDynamicLinkConfig;
    _languagesInfo =
        List<Map>.from(value['languagesInfo'] ?? DefaultConfig.languagesInfo);
    _paymentConfig = value['paymentConfig'] ?? DefaultConfig.paymentConfig;
    _payments = value['payments'] ?? DefaultConfig.payments;
    _stripeConfig = value['stripeConfig'] ?? DefaultConfig.stripeConfig;
    _paypalConfig = value['paypalConfig'] ?? DefaultConfig.paypalConfig;
    _razorpayConfig = value['razorpayConfig'] ?? DefaultConfig.razorpayConfig;
    _tapConfig = value['tapConfig'] ?? DefaultConfig.tapConfig;
    _payTmConfig = value['payTmConfig'] ?? DefaultConfig.payTmConfig;
    _payStackConfig = value['payStackConfig'] ?? DefaultConfig.payStackConfig;
    _flutterwaveConfig =
        value['flutterwaveConfig'] ?? DefaultConfig.flutterwaveConfig;
    _myFatoorahConfig =
        value['myFatoorahConfig'] ?? DefaultConfig.myFatoorahConfig;
    _mercadoPagoConfig =
        value['mercadoPagoConfig'] ?? DefaultConfig.mercadoPagoConfig;
    _afterShip = value['afterShip'] ?? DefaultConfig.afterShip;
    _productAddons = value['productAddons'] ?? DefaultConfig.productAddons;
    _cartDetail = value['cartDetail'] ?? DefaultConfig.cartDetail;
    _productVariantLanguage =
        value['productVariantLanguage'] ?? DefaultConfig.productVariantLanguage;
    _saleOffProduct = value['saleOffProduct'] ?? DefaultConfig.saleOffProduct;
    _excludedCategory =
        value['excludedCategory'] ?? DefaultConfig.excludedCategory;
    _notStrictVisibleVariant = value['notStrictVisibleVariant'] ??
        DefaultConfig.notStrictVisibleVariant;
    _configChat = value['configChat'] ?? DefaultConfig.configChat;
    _smartChat = ConfigurationUtils.loadSmartChat(
        List<Map>.from(value['smartChat'] ?? DefaultConfig.smartChat));
    _adminEmail = value['adminEmail'] ?? DefaultConfig.adminEmail;
    _adminName = value['adminName'] ?? DefaultConfig.adminName;
    _vendorConfig = value['vendorConfig'] ?? DefaultConfig.vendorConfig;
    final addressFieldsData = value['addressFields'];
    if (addressFieldsData is List && addressFieldsData.isNotEmpty) {
      _addressFields = [];
      for (var item in addressFieldsData) {
        final addressFieldConfig = AddressFieldConfig.fromMap(item);
        if (addressFieldConfig.type == AddressFieldType.unknown) {
          continue;
        }
        _addressFields.add(addressFieldConfig);
      }
      _addressFields.sort((a, b) => a.position.compareTo(b.position));
    } else {
      _addressFields = List.from(
        DefaultConfig.addressFields,
      );
    }
    _defaultCountryShipping =
        value['defaultCountryShipping'] ?? DefaultConfig.defaultCountryShipping;

    _loadingIcon = value['loadingIcon'] ?? DefaultConfig.loadingIcon;
    _productCard = value['productCard'] ?? DefaultConfig.productCard;
    _loginSMSConstants =
        value['loginSMSConstants'] ?? DefaultConfig.loginSMSConstants;
    _darkConfig = value['darkConfig'] ?? DefaultConfig.darkConfig;
    _lightConfig = value['lightConfig'] ?? DefaultConfig.lightConfig;
    _version = value['version'] ?? DefaultConfig.version;
    _subGeneralSetting = ConfigurationUtils.loadSubGeneralSetting(
        value['subGeneralSetting'] ?? DefaultConfig.subGeneralSetting);
    _splashScreen = value['splashScreen'] ?? DefaultConfig.splashScreen;
    _colorOverrideConfig =
        value['colorOverrideConfig'] ?? DefaultConfig.colorOverrideConfig;

    _googleApiKey = value['googleApiKey'] == null
        ? DefaultConfig.googleApiKey
        : GoogleApiKeyConfig.fromMap(value['googleApiKey']);

    _enableOnBoarding =
        value['enableOnBoarding'] ?? DefaultConfig.enableOnBoarding;
    _managerConfig = value['managerConfig'];
    _deliveryConfig = value['deliveryConfig'];
  }

  void setAlwaysShowTabBar(bool value) {
    _advanceConfig['AlwaysShowTabBar'] = value;
  }

  void _loadConfig(String key) {
    switch (key) {
      case 'appConfig':
        final data = Services().firebase.getRemoteConfigString('appConfig');
        if (data.isNotEmpty) {
          _appConfig = data;
        }
        break;
      case 'serverConfig':
        final data = Services().firebase.getRemoteConfigString('serverConfig');
        if (data.isNotEmpty) {
          _serverConfig = jsonDecode(data) ?? _serverConfig;
        }
        break;
      case 'advanceConfig':
        final data = Services().firebase.getRemoteConfigString('advanceConfig');
        if (data.isNotEmpty) {
          _advanceConfig = Map.from(jsonDecode(data));
        }
        break;
      case 'productDetail':
        final data = Services().firebase.getRemoteConfigString('productDetail');
        if (data.isNotEmpty) {
          _productDetail = jsonDecode(data) ?? _productDetail;
        }
        break;
      case 'onBoardingData':
        final data =
            Services().firebase.getRemoteConfigString('onBoardingData');
        if (data.isNotEmpty) {
          _onBoardingData = jsonDecode(data) ?? _onBoardingData;
        }
        break;
      case 'vendorOnBoardingData':
        final data =
            Services().firebase.getRemoteConfigString('vendorOnBoardingData');
        if (data.isNotEmpty) {
          _vendorOnBoardingData = jsonDecode(data) ?? _vendorOnBoardingData;
        }
        break;
      case 'blogDetail':
        final data = Services().firebase.getRemoteConfigString('blogDetail');
        if (data.isNotEmpty) {
          _blogDetail = jsonDecode(data) ?? _blogDetail;
        }
        break;
      case 'smartChat':
        final data = Services().firebase.getRemoteConfigString('smartChat');
        if (data.isNotEmpty) {
          _smartChat = ConfigurationUtils.loadSmartChat(
              List<Map>.from(jsonDecode(data) ?? DefaultConfig.smartChat));
        }
        break;
      case 'splashScreen':
        final data = Services().firebase.getRemoteConfigString('splashScreen');
        if (data.isNotEmpty) {
          _splashScreen = jsonDecode(data) ?? _splashScreen;
        }
        break;
      case 'googleApiKey':
        final data = Services().firebase.getRemoteConfigString('googleApiKey');
        if (data.isNotEmpty) {
          try {
            _googleApiKey = GoogleApiKeyConfig.fromMap(jsonDecode(data));
          } catch (_) {}
        }
        break;
      case 'layout_design':
        final data = Services().firebase.getRemoteConfigString('layout_design');
        if (data.isNotEmpty) {
          _layoutDesign = Map<String, dynamic>.from(jsonDecode(data));
        }
        break;
      default:
    }
  }

  final _listConfigRemoteKey = [
    'appConfig',
    'serverConfig',
    'defaultDarkTheme',
    'storeIdentifier',
    'advanceConfig',
    'defaultDrawer',
    'defaultSettings',
    'loginSetting',
    'oneSignalKey',
    'onBoardingData',
    'vendorOnBoardingData',
    'adConfig',
    'firebaseDynamicLinkConfig',
    'languagesInfo',
    'paymentConfig',
    'payments',
    'stripeConfig',
    'paypalConfig',
    'razorpayConfig',
    'tapConfig',
    'mercadoPagoConfig',
    'afterShip',
    'productDetail',
    'productVariantLayout',
    'productAddons',
    'cartDetail',
    'productVariantLanguage',
    'excludedCategory',
    'saleOffProduct',
    'notStrictVisibleVariant',
    'configChat',
    'smartChat',
    'adminEmail',
    'adminName',
    'vendorConfig',
    'loadingIcon',
    'blogDetail',
    'splashScreen',
    'googleApiKey',
    'layout_design',
  ];
}

extension ConfigurationsFireBaseRemoteConfig on Configurations {
  Future<void> loadRemoteConfig() async {
    if (Configurations.enableRemoteConfigFirebase) {
      final isAvailable = await Services().firebase.loadRemoteConfig();
      if (isAvailable) {
        for (var item in _listConfigRemoteKey) {
          _loadConfig(item);
        }
      }
    }
  }
}
