import 'package:flutter/material.dart';

import '../../../models/index.dart' show Product, ProductModel;
import '../../../widgets/product/product_card_view.dart';
import '../config/product_config.dart';
import '../helper/header_view.dart';
import '../helper/helper.dart';

class EmptyProductList extends StatelessWidget {
  final ProductConfig config;
  final double maxWidth;

  const EmptyProductList(
      {Key? key, required this.config, required this.maxWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultHeight =
        config.height != null ? config.height! + 40.0 : maxWidth * 1.4;

    return Column(
      children: <Widget>[
        HeaderView(
          headerText: config.name ?? '',
          showSeeAll: false,
          callback: () =>
              ProductModel.showList(context: context, config: config.jsonData),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: Layout.buildProductHeight(
              layout: config.layout,
              defaultHeight: defaultHeight,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 10.0),
                for (var i = 0; i < 4; i++)
                  ProductCard(
                    item: Product.empty(i.toString()),
                    width: Layout.buildProductWidth(
                      layout: config.layout,
                      screenWidth: maxWidth,
                    ),
                    config: ProductConfig.empty(),
                    // tablet: constraint.maxWidth / MediaQuery.of(context).size.height > 1.2,
                  )
              ],
            ),
          ),
        )
      ],
    );
  }
}

class EmptyProductTile extends StatelessWidget {
  final double maxWidth;

  const EmptyProductTile({Key? key, required this.maxWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (var i = 0; i < 4; i++)
          SizedBox(
            width: maxWidth,
            child: ListTile(
              leading: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 4.0),
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                alignment: Alignment.center,
                color: Colors.grey.withOpacity(0.2),
              ),
              title: Container(
                width: 70,
                height: 30,
                color: Colors.grey.withOpacity(0.1),
              ),
              dense: false,
            ),
          ),
      ],
    );
  }
}

class EmptyProductGrid extends StatelessWidget {
  final ProductConfig config;
  final double maxWidth;

  const EmptyProductGrid(
      {Key? key, required this.config, required this.maxWidth})
      : super(key: key);

  double getGridRatio() {
    switch (config.layout) {
      case Layout.twoColumn:
        return 1.5;
      case Layout.threeColumn:
      default:
        return 1.7;
    }
  }

  double getHeightRatio() {
    switch (config.layout) {
      case Layout.twoColumn:
        return 1.7;
      case Layout.threeColumn:
      default:
        return 1.3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultHeight =
        config.height != null ? config.height! + 40.0 : maxWidth * 1.4;
    var ratioProductImage = 1.5;
    const padding = 12.0;
    var rows = config.rows;
    var productHeight = Layout.buildProductHeight(
      layout: config.layout,
      defaultHeight: defaultHeight,
    );

    return Column(
      children: <Widget>[
        HeaderView(
          headerText: config.name ?? '',
          showSeeAll: false,
          callback: () =>
              ProductModel.showList(context: context, config: config.jsonData),
        ),
        Container(
          padding: const EdgeInsets.only(left: padding, top: padding),
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
            borderRadius: BorderRadius.circular(2),
          ),
          height: rows * productHeight * getHeightRatio(),
          child: GridView.count(
            childAspectRatio: ratioProductImage * getGridRatio(),
            scrollDirection: Axis.horizontal,
            crossAxisCount: rows,
            children: [
              for (var i = 0; i < 12; i++)
                ProductCard(
                  item: Product.empty(i.toString()),
                  width: Layout.buildProductWidth(
                    layout: config.layout,
                    screenWidth: maxWidth,
                  ),
                  config: ProductConfig.empty(),
                  // tablet: constraint.maxWidth / MediaQuery.of(context).size.height > 1.2,
                )
            ],
          ),
        ),
      ],
    );
  }
}
