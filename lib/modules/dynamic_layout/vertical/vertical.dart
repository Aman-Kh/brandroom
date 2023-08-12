import 'package:flutter/material.dart';

import '../../../models/product_model.dart';
import '../../../services/service_config.dart';
import '../config/product_config.dart';
import '../helper/header_view.dart';
import '../helper/helper.dart';
import 'menu_layout.dart';
import 'pinterest_layout.dart';
import 'vertical_layout.dart';
import 'vertical_layout_with_filter.dart';

class VerticalLayout extends StatelessWidget {
  final config;

  const VerticalLayout({this.config, Key? key}) : super(key: key);

  Widget renderLayout() {
    var productConfig = ProductConfig.fromJson(config ?? {});
    switch (config['layout']) {
      case Layout.menu:
        return MenuLayout(config: productConfig);
      case Layout.pinterest:
        return PinterestLayout(config: productConfig);
      case Layout.columnsWithFilter:
        return VerticalViewLayoutWithFilter(config: productConfig);
      case Layout.card:
      case Layout.listTile:
      case Layout.columns:
      default:
        return VerticalViewLayout(config: productConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        if (config['name'] != null)
          HeaderView(
            headerText: config['name'] ?? '',
            showSeeAll: !ServerConfig().isListingType,
            callback: () => ProductModel.showList(
              context: context,
              config: config,
            ),
          ),
        renderLayout()
      ],
    );
  }
}
