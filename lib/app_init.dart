import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/config.dart';
import 'common/constants.dart';
import 'common/tools.dart';
import 'models/index.dart'
    show
        AppModel,
        CartModel,
        CategoryModel,
        FilterAttributeModel,
        FilterTagModel,
        ListingLocationModel,
        TagModel;
import 'modules/dynamic_layout/config/app_config.dart';
import 'screens/base_screen.dart';
import 'screens/blog/models/list_blog_model.dart';
import 'services/index.dart';
import 'widgets/common/splash_screen.dart';

class AppInit extends StatefulWidget {
  const AppInit();

  @override
  State<AppInit> createState() => _AppInitState();
}

class _AppInitState extends BaseScreen<AppInit> {
  /// It is true if the app is initialized
  bool isLoggedIn = false;
  bool hasLoadedData = false;
  bool hasLoadedSplash = false;

  late AppConfig? appConfig;

  /// check if the screen is already seen At the first time
  bool get seen => getStorageKey(LocalStorageKey.seen);

  bool get isApprovedPrivacy => getStorageKey(LocalStorageKey.agreePrivacy);

  bool getStorageKey(String key) =>
      injector<SharedPreferences>().getBool(key) ?? false;

  void setStorageKey(String key) =>
      injector<SharedPreferences>().setBool(key, true);

  Future<void> loadInitData() async {
    try {
      printLog('[AppState] Init Data 💫');
      isLoggedIn = getStorageKey(LocalStorageKey.loggedIn);

      /// set the server config at first loading
      /// Load App model config
      if (ServerConfig().isBuilder) {
        Services().setAppConfig(serverConfig);
      }
      // todo: need testing
      // //new fix to load the currency before any thing..

      // Future.delayed(Duration.zero, () {
      //   Provider.of<AppModel>(context, listen: false).loadCurrency(
      //       callback: (currencyRate) {
      //     // new fix to mount the changeCurrencyRates so it can work with home cache ..

      //     if (mounted) {
      //       Provider.of<CartModel>(context, listen: false)
      //           .changeCurrencyRates(currencyRate);
      //       // print('amin546 $currencyRate from init');
      //     }
      //   });
      // });
      appConfig = await Provider.of<AppModel>(context, listen: false)
          .loadAppConfig(config: Configurations.layoutDesign);

      Future.delayed(Duration.zero, () {
        /// Load more Category/Blog/Attribute Model beforehand
        final lang = Provider.of<AppModel>(context, listen: false).langCode;

        /// Request Categories
        final appModel = Provider.of<AppModel>(context, listen: false);
        Provider.of<CategoryModel>(context, listen: false).getCategories(
          lang: lang,
          sortingList: appModel.categories,
          categoryLayout: appModel.categoryLayout,
          remapCategories: appModel.remapCategories,
        );
        hasLoadedData = true;
        if (hasLoadedSplash) {
          goToNextScreen();
        }
      });

      /// Request more Async data which is not use on home screen
      Future.delayed(
        Duration.zero,
        () {
          Provider.of<TagModel>(context, listen: false).getTags();

          Provider.of<ListBlogModel>(context, listen: false).getBlogs();

          Provider.of<FilterTagModel>(context, listen: false).getFilterTags();

          Provider.of<FilterAttributeModel>(context, listen: false)
              .getFilterAttributes();
//todo:
// to fix currency is doubled
          // final cartModel = Provider.of<CartModel>(context, listen: false);
          // Provider.of<AppModel>(context, listen: false).loadCurrency(
          //     callback: (currencyRate) {
          //   cartModel.changeCurrencyRates(currencyRate);
          // });

          if (ServerConfig().isListingType) {
            Provider.of<ListingLocationModel>(context, listen: false)
                .getLocations();
          }

          /// init Facebook & Google Ads
          Services()
              .advertisement
              .initAdvertise(context.read<AppModel>().advertisement);
        },
      );

      printLog('[AppState] InitData Finish');
    } catch (e, trace) {
      printLog(e.toString());
      printLog(trace.toString());
    }
  }

  void goToNextScreen() {
    if (!kIsWeb && appConfig != null) {
      if (kEnableOnBoarding &&
          (!seen || !kAdvanceConfig.onBoardOnlyShowFirstTime)) {
        Navigator.of(context).pushReplacementNamed(RouteList.onBoarding);
        return;
      }

      if (!seen) {
        if (kAdvanceConfig.showRequestNotification) {
          Navigator.of(context)
              .pushReplacementNamed(RouteList.notificationRequest)
              .then((_) {
            setStorageKey(LocalStorageKey.seen);
          });
          return;
        }

        setStorageKey(LocalStorageKey.seen);
        return;
      }
    }

    if (Services().widget.isRequiredLogin && !isLoggedIn) {
      NavigateTools.navigateToLogin(
        context,
        replacement: true,
      );
      return;
    }

    if (kAdvanceConfig.gdprConfig.showPrivacyPolicyFirstTime &&
        !isApprovedPrivacy) {
      Navigator.of(context).pushReplacementNamed(RouteList.privacyTerms);
      return;
    }

    Navigator.of(context).pushReplacementNamed(RouteList.dashboard);
  }

  void checkToShowNextScreen() {
    /// If the config was load complete then navigate to Dashboard
    hasLoadedSplash = true;
    if (hasLoadedData) {
      goToNextScreen();
      return;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    await loadInitData();
  }

  @override
  Widget build(BuildContext context) {
    var splashScreenType = kSplashScreen['type'];
    dynamic splashScreenImage = kSplashScreen['image'];
    var duration = kSplashScreen['duration'] ?? 2000;
    return SplashScreenIndex(
      imageUrl: splashScreenImage,
      splashScreenType: splashScreenType,
      actionDone: checkToShowNextScreen,
      duration: duration,
    );
  }
}
