import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_version/new_version.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/config.dart';
import '../common/constants.dart';
import '../common/tools/in_app_update_for_android.dart';
import '../generated/l10n.dart';
import '../main_layout/layout_left_menu.dart';
import '../models/index.dart';
import '../modules/dynamic_layout/config/tab_bar_config.dart';
import '../modules/dynamic_layout/helper/helper.dart';
import '../modules/dynamic_layout/index.dart';
import '../routes/flux_navigate.dart';
import '../routes/route.dart';
import '../screens/index.dart' show NotificationScreen;
import '../screens/users/age_restriction_screen.dart';
import '../services/dependency_injection.dart';
import '../widgets/overlay/custom_overlay_state.dart';
import 'maintab_delegate.dart';
import 'side_menu.dart';
import 'sidebar.dart';

const int turnsToRotateRight = 1;
const int turnsToRotateLeft = 3;

/// Include the setting fore main TabBar menu and Side menu
class MainTabs extends StatefulWidget {
  const MainTabs({Key? key}) : super(key: key);

  @override
  MainTabsState createState() => MainTabsState();
}

class MainTabsState extends CustomOverlayState<MainTabs>
    with WidgetsBindingObserver {
  /// check Desktop screen and app Setting variable
  bool get isDesktopDisplay => Layout.isDisplayDesktop(context);

  AppSetting get appSetting =>
      Provider.of<AppModel>(context, listen: false).appConfig!.settings;

  final navigators = <int, GlobalKey<NavigatorState>>{};

  /// TabBar variable
  late TabController tabController;
  var isInitialized = false;

  final List<Widget> _tabView = [];
  Map saveIndexTab = {};
  Map<String, String?> childTabName = {};
  int currentTabIndex = 0;

  List<TabBarMenuConfig> get tabData =>
      Provider.of<AppModel>(context, listen: false).appConfig!.tabBar;

  @override
  bool get hasLabelInBottomBar =>
      tabData.any((tab) => tab.label?.isNotEmpty ?? false);

  /// Drawer variable
  bool isShowCustomDrawer = false;

  bool get shouldHideTabBar =>
      isDesktopDisplay ||
      (isShowCustomDrawer && Layout.isDisplayTablet(context));

  StreamSubscription? _subOpenCustomDrawer;
  StreamSubscription? _subCloseCustomDrawer;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    _initListenEvent();
    _initTabDelegate();
    _initTabData(context);

    // In App Update For Android will have higher priority than Enable Version Check
    if (isAndroid && kAdvanceConfig.inAppUpdateForAndroid.enable) {
      unawaited(InAppUpdateForAndroid().checkForUpdate());
    } else if (kAdvanceConfig.enableVersionCheck) {
      NewVersion().showAlertIfNecessary(context: context);
    }

    final hasAskedAge = injector<SharedPreferences>()
            .getBool(LocalStorageKey.askedAgeRestriction) ??
        false;
    if (appSetting.ageRestrictionConfig.enable &&
        (appSetting.ageRestrictionConfig.alwaysShowUponOpen || !hasAskedAge)) {
      await FluxNavigate.push(
        MaterialPageRoute(
          builder: (context) => AgeRestrictionScreen(
            config: appSetting.ageRestrictionConfig,
          ),
          fullscreenDialog: true,
        ),
        forceRootNavigator: true,
      );
    }
  }

  /// init the Event Bus listening
  void _initListenEvent() {
    _subOpenCustomDrawer = eventBus.on<EventOpenCustomDrawer>().listen((event) {
      setState(() {
        isShowCustomDrawer = true;
      });
    });
    _subCloseCustomDrawer =
        eventBus.on<EventCloseCustomDrawer>().listen((event) {
      setState(() {
        isShowCustomDrawer = false;
      });
    });
  }

  /// Check pop navigator on the Current tab, and show Confirm Exit App
  Future<bool> _handleWillPopScopeRoot() async {
    final currentNavigator = navigators[tabController.index]!;
    if (currentNavigator.currentState!.canPop()) {
      currentNavigator.currentState!.pop();
      return Future.value(false);
    }

    /// Check pop root navigator
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return Future.value(false);
    }

    if (tabController.index != 0) {
      tabController.animateTo(0);
      _emitChildTabName();
      return Future.value(false);
    } else {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).areYouSure),
          content: Text(S.of(context).doYouWantToExitApp),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).no),
            ),
            TextButton(
              onPressed: () {
                if (isIos) {
                  Navigator.of(context).pop(true);
                } else {
                  SystemNavigator.pop();
                }
              },
              child: Text(S.of(context).yes),
            ),
          ],
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    isShowCustomDrawer = isDesktopDisplay;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (isInitialized) {
      tabController.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _subOpenCustomDrawer?.cancel();
    _subCloseCustomDrawer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// Handle the DeepLink notification
    if (state == AppLifecycleState.paused) {
      // went to Background
    }
    if (state == AppLifecycleState.resumed) {
      // came back to Foreground
      final appModel = Provider.of<AppModel>(context, listen: false);
      if (appModel.deeplink?.isNotEmpty ?? false) {
        if (appModel.deeplink!['screen'] == 'NotificationScreen') {
          appModel.deeplink = null;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationScreen()),
          );
        }
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    //customTabBar();
    printLog('[TabBar] ============== tabbar.dart ==============');

    var appConfig = Provider.of<AppModel>(context, listen: false).appConfig;

    if (_tabView.isEmpty || appConfig == null) {
      return Container(
        color: Colors.white,
      );
    }

    final media = MediaQuery.of(context);
    final isTabBarEnabled = appSetting.tabBarConfig.enable;
    final showFloating = appSetting.tabBarConfig.showFloating;
    final isClip = appSetting.tabBarConfig.showFloatingClip;
    final floatingActionButtonLocation =
        appSetting.tabBarConfig.tabBarFloating.location ??
            FloatingActionButtonLocation.centerDocked;

    printLog('[ScreenSize]: ${media.size.width} x ${media.size.height}');

    return SideMenu(
      backgroundColor: showFloating ? null : Theme.of(context).backgroundColor,
      bottomNavigationBar: isTabBarEnabled
          ? (showFloating
              ? BottomAppBar(
                  shape: isClip ? const CircularNotchedRectangle() : null,
                  child: tabBarMenu(),
                )
              : tabBarMenu())
          : null,
      tabBarOnTop: appConfig.settings.tabBarConfig.enableOnTop,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButton: showFloating ? getTabBarMenuAction() : null,
      zoomConfig: appConfig.drawer?.zoomConfig,
      sideMenuBackground: appConfig.drawer?.backgroundColor,
      sideMenuBackgroundImage: appConfig.drawer?.backgroundImage,
      colorFilter: appConfig.drawer?.colorFilter,
      filter: appConfig.drawer?.filter,
      drawer: (appConfig.drawer?.enable ?? true) ? const SideBarMenu() : null,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          primaryColor: Theme.of(context).colorScheme.secondary,
          barBackgroundColor: Theme.of(context).backgroundColor,
          textTheme: CupertinoTextThemeData(
            navActionTextStyle: Theme.of(context).primaryTextTheme.button,
            navTitleTextStyle: Theme.of(context).textTheme.headline5,
            navLargeTitleTextStyle:
                Theme.of(context).textTheme.headline4!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
          ),
        ),
        child: WillPopScope(
          onWillPop: _handleWillPopScopeRoot,
          child: LayoutLeftMenu(
            menu:
                (appConfig.drawer?.enable ?? true) ? const SideBarMenu() : null,
            content: MediaQuery(
              data: isDesktopDisplay
                  ? media.copyWith(
                      size: Size(
                      media.size.width - kSizeLeftMenu,
                      media.size.height,
                    ))
                  : media,
              child: ChangeNotifierProvider.value(
                value: tabController,
                child: Consumer<TabController>(
                    builder: (context, controller, child) {
                  /// use for responsive web/mobile
                  return Stack(
                    fit: StackFit.expand,
                    children: List.generate(
                      _tabView.length,
                      (index) {
                        final active = controller.index == index;
                        return Offstage(
                          offstage: !active,
                          child: TickerMode(
                            enabled: active,
                            child: _tabView[index],
                          ),
                        );
                      },
                    ).toList(),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension TabBarMenuExtention on MainTabsState {
  /// on change tabBar name
  void _onChangeTab(String? nameTab, {bool allowPush = true}) {
    if (saveIndexTab[nameTab] != null) {
      tabController.animateTo(saveIndexTab[nameTab]);
      _emitChildTabName();
    } else if (allowPush) {
      FluxNavigate.pushNamed(nameTab.toString(), forceRootNavigator: true);
    }
  }

  /// init Tab Delegate to use for SmartChat & Ads feature
  void _initTabDelegate() {
    var tabDelegate = MainTabControlDelegate.getInstance();
    tabDelegate.changeTab = _onChangeTab;
    tabDelegate.tabKey = () => navigators[tabController.index];
    tabDelegate.currentTabName = _getCurrentTabName;
    tabDelegate.tabAnimateTo = (int index) {
      if (index < tabController.length) {
        tabController.animateTo(index);
      }
    };
    WidgetsBinding.instance.addObserver(this);
  }

  Navigator tabViewItem({key, initialRoute, args}) {
    return Navigator(
      key: key,
      initialRoute: initialRoute,
      observers: [
        MyRouteObserver(
          action: (screenName) {
            childTabName[initialRoute!] = screenName;
            OverlayControlDelegate().emitTab?.call(screenName);
          },
        ),
      ],
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == initialRoute) {
          return Routes.getRouteGenerate(RouteSettings(
            name: initialRoute,
            arguments: args,
          ));
        }
        return Routes.getRouteGenerate(settings);
      },
    );
  }

  /// init the tabView data and tabController
  void _initTabData(context) async {
    var appModel = Provider.of<AppModel>(context, listen: false);

    /// Fix the empty loading appConfig on Web
    // if (appModel.appConfig == null && kIsWeb) {
    //   await appModel.loadAppConfig();
    // }

    var tabData = appModel.appConfig!.tabBar;
    var enableOnTop =
        appModel.appConfig?.settings.tabBarConfig.enableOnTop ?? false;
    for (var i = 0; i < tabData.length; i++) {
      var dataOfTab = tabData[i];
      saveIndexTab[dataOfTab.layout] = i;
      navigators[i] = GlobalKey<NavigatorState>();
      final initialRoute = dataOfTab.layout;
      if (enableOnTop) {
        _tabView.add(
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: tabViewItem(
              key: navigators[i],
              initialRoute: initialRoute,
              args: dataOfTab,
            ),
          ),
        );
      } else {
        _tabView.add(
          tabViewItem(
            key: navigators[i],
            initialRoute: initialRoute,
            args: dataOfTab,
          ),
        );
      }
    }
    // ignore: invalid_use_of_protected_member
    setState(() {
      tabController = TabController(length: _tabView.length, vsync: this);
    });
    if (MainTabControlDelegate.getInstance().index != null) {
      tabController.animateTo(MainTabControlDelegate.getInstance().index!);
    } else {
      MainTabControlDelegate.getInstance().index = 0;
    }
    isInitialized = true;

    /// Load the Design from FluxBuilder
    tabController.addListener(() {
      if (tabController.index == currentTabIndex) {
        eventBus.fire(EventNavigatorTabbar(tabController.index));
        MainTabControlDelegate.getInstance().index = tabController.index;
      }
    });
  }

  void _emitChildTabName() {
    final tabName = _getCurrentTabName();
    OverlayControlDelegate().emitTab?.call(childTabName[tabName]);
  }

  String _getCurrentTabName() {
    if (saveIndexTab.isEmpty) {
      return '';
    }
    return saveIndexTab.entries
            .firstWhereOrNull((element) => element.value == tabController.index)
            ?.key ??
        '';
  }

  /// on tap on the TabBar icon
  void _onTapTabBar(index) {
    if (currentTabIndex == index) {
      navigators[tabController.index]!.currentState!.popUntil((r) => r.isFirst);
    }
    currentTabIndex = index;

    _emitChildTabName();

    // if (!kIsWeb && !isDesktop) {
    //   if ('cart' == tabData[index].layout) {
    //     FlutterWebviewPlugin().show();
    //   } else {
    //     FlutterWebviewPlugin().hide();
    //   }
    // }
  }

  /// return the tabBar widget
  Widget tabBarMenu() {
    return Selector<CartModel, int>(
      selector: (_, cartModel) => cartModel.totalCartQuantity,
      builder: (context, totalCart, child) {
        return TabBarCustom(
          onTap: _onTapTabBar,
          tabData: tabData,
          tabController: tabController,
          config: appSetting,
          shouldHideTabBar: shouldHideTabBar,
          totalCart: totalCart,
        );
      },
    );
  }

  /// Return the Tabbar Floating
  Widget getTabBarMenuAction() {
    var position = appSetting.tabBarConfig.tabBarFloating.position;
    var itemIndex = (position != null && position < tabData.length)
        ? position
        : (tabData.length / 2).floor();

    return Selector<CartModel, int>(
      selector: (_, cartModel) => cartModel.totalCartQuantity,
      builder: (context, totalCart, child) {
        return IconFloatingAction(
          config: appSetting.tabBarConfig.tabBarFloating,
          item: tabData[itemIndex].jsonData,
          onTap: () {
            tabController.animateTo(itemIndex);
            _onTapTabBar(itemIndex);
          },
          totalCart: totalCart,
        );
      },
    );
  }

  void customTabBar() {
    /// Design TabBar style
    appSetting.tabBarConfig
      ..colorIcon = HexColor('7A7B7F')
      ..colorActiveIcon = HexColor('FF672D')
      ..indicatorStyle = IndicatorStyle.none
      ..showFloating = true
      ..showFloatingClip = false
      ..tabBarFloating = TabBarFloatingConfig(
        color: HexColor('FF672D'),
        // width: 65,
        // height: 40,
      );
  }

  /// custom the TabBar Style
  void customTabBar3() {
    /// Design TabBar style
    appSetting.tabBarConfig
      ..colorIcon = HexColor('7A7B7F')
      ..colorActiveIcon = HexColor('FF672D')
      ..indicatorStyle = IndicatorStyle.none
      ..showFloating = true
      ..showFloatingClip = false
      ..tabBarFloating = TabBarFloatingConfig(
        color: HexColor('FF672D'),
        width: 70,
        height: 70,
        elevation: 10.0,
        floatingType: FloatingType.diamond,
        // width: 65,
        // height: 40,
      );
  }

  void customTabBar2() {
    /// Design TabBar style
    appSetting.tabBarConfig
      ..colorCart = HexColor('FE2060')
      ..colorIcon = HexColor('7A7B7F')
      ..colorActiveIcon = HexColor('1D34C5')
      ..indicatorStyle = IndicatorStyle.material
      ..showFloating = true
      ..showFloatingClip = true
      ..tabBarFloating = TabBarFloatingConfig(
        color: HexColor('1D34C5'),
        elevation: 2.0,
      )
      ..tabBarIndicator = TabBarIndicatorConfig(
        color: HexColor('1D34C5'),
        verticalPadding: 10,
        tabPosition: TabPosition.top,
        topLeftRadius: 0,
        topRightRadius: 0,
        bottomLeftRadius: 10,
        bottomRightRadius: 10,
      );
  }

  void customTabBar1() {
    /// Design TabBar style 1
    appSetting.tabBarConfig
      ..color = HexColor('1C1D21')
      ..colorCart = HexColor('FE2060')
      ..isSafeArea = false
      ..marginBottom = 15.0
      ..marginLeft = 15.0
      ..marginRight = 15.0
      ..paddingTop = 12.0
      ..paddingBottom = 12.0
      ..radiusTopRight = 15.0
      ..radiusTopLeft = 15.0
      ..radiusBottomRight = 15.0
      ..radiusBottomLeft = 15.0
      ..paddingRight = 10.0
      ..indicatorStyle = IndicatorStyle.rectangular
      ..tabBarIndicator = TabBarIndicatorConfig(
        color: HexColor('22262C'),
        topRightRadius: 9.0,
        topLeftRadius: 9.0,
        bottomLeftRadius: 9.0,
        bottomRightRadius: 9.0,
        distanceFromCenter: 10.0,
        horizontalPadding: 10.0,
      );
  }
}
