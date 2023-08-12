import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../menu/index.dart' show FluxAppBar;
import '../../models/index.dart' show AppModel;
import '../../modules/dynamic_layout/index.dart' show AppBarConfig;

mixin AppBarMixin<T extends StatefulWidget> on State<T> {
  AppBarConfig? get appBar => context.read<AppModel>().appConfig?.appBar;

  bool showAppBar(String routeName) {
    if (appBar?.enable ?? false) {
      return appBar?.shouldShowOn(routeName) ?? false;
    }
    return false;
  }

  AppBar get appBarWidget => AppBar(
        titleSpacing: 0,
        elevation: appBar?.elevation.toDouble() ?? 0,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).backgroundColor,
        title: const FluxAppBar(),
      );

  /// [snap] is always false if [float] is false.
  SliverAppBar get sliverAppBarWidget => SliverAppBar(
        snap: (appBar?.floating ?? true) ? appBar?.snap ?? true : false,
        pinned: appBar?.pinned ?? true,
        floating: appBar?.floating ?? true,
        titleSpacing: 0,
        elevation: appBar?.elevation.toDouble() ?? 0,
        forceElevated: true,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).backgroundColor,
        title: const FluxAppBar(),
      );

  Widget renderScaffold({
    required String routeName,
    required Widget body,
    bool? resizeToAvoidBottomInset,
    Color? backgroundColor,
    bool hideNewAppBar = false,
    Widget? floatingActionButton,
  }) {
    if (showAppBar(routeName) && !hideNewAppBar) {
      return Scaffold(
        appBar: appBarWidget,
        body: body,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor,
        floatingActionButton: floatingActionButton,
      );
    }
    if (resizeToAvoidBottomInset != null ||
        backgroundColor != null ||
        floatingActionButton != null) {
      return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }
    return body;
  }
}
