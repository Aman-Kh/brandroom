import 'package:flutter/material.dart';

import '../../../services/index.dart';
import '../config/product_config.dart';
import '../helper/custom_physic.dart';
import '../helper/helper.dart';

class ProductGrid extends StatelessWidget {
  final products;
  final maxWidth;
  final ProductConfig config;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.maxWidth,
    required this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productList = products;
    if (productList == null || productList is! List || productList.isEmpty) {
      return const SizedBox();
    }
    const padding = 12.0;
    final ratioProductImage = config.imageRatio;
    final gridWidth = maxWidth - padding;
    final columns = getColumnCount();

    var rows = config.rows;
    var productHeight = Layout.buildProductHeight(
      layout: config.layout,
      defaultHeight: maxWidth,
    );

    if (ratioProductImage < 1) {
      productHeight = productHeight * (ratioProductImage * 1.2);
    }

    /// Not create a new row until the item is out of the screen.
    if (products.length <= columns) {
      rows = 1;
    }

    return Container(
      padding: const EdgeInsets.only(left: padding, top: padding),
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(2),
      ),
      height: rows * productHeight * getHeightRatio(),
      child: GridView.count(
        childAspectRatio:
            (ratioProductImage * (ratioProductImage < 1 ? 1.5 : 1)) *
                getGridRatio(),
        scrollDirection: Axis.horizontal,
        physics: config.isSnapping ?? false
            ? CustomScrollPhysic(
                width: Layout.buildProductWidth(
                  screenWidth: gridWidth / ratioProductImage,
                  layout: config.layout,
                ),
              )
            : const ScrollPhysics(),
        crossAxisCount: rows,
        children: List.generate(productList.length, (i) {
          return Services().widget.renderProductCardView(
                item: productList[i],
                width: Layout.buildProductWidth(
                    screenWidth: gridWidth, layout: config.layout),
                maxWidth: Layout.buildProductMaxWidth(layout: config.layout),
                height: productHeight,
                ratioProductImage: ratioProductImage,
                config: config,
              );
        }),
      ),
    );
  }

  double getColumnCount() {
    switch (config.layout) {
      case Layout.twoColumn:
        return 2;
      case Layout.threeColumn:
      default:
        return 3;
    }
  }

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
}
