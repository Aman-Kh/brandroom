import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../common/config.dart' show kProductCard, kProductDetail, kSaleOffProduct;
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart' show Product;
import '../../modules/dynamic_layout/config/product_config.dart';
import '../../modules/dynamic_layout/helper/helper.dart';
import '../../modules/dynamic_layout/vertical/pinterest_card.dart';
import '../../services/index.dart';
import '../backdrop/backdrop_constants.dart';
import '../common/no_internet_connection.dart';
import 'product_simple_view.dart';

class ProductList extends StatefulWidget {
  final List<Product>? products;
  final bool isFetching;
  final bool? isEnd;
  final String? errMsg;
  final double? width;
  final double padding;
  final String? layout;
  final Function onRefresh;
  final Function onLoadMore;
  final double? ratioProductImage;
  final num? productListItemHeight;
  final ScrollController? scrollController;
  final List<Widget>? header;

  const ProductList({
    this.isFetching = false,
    this.isEnd = true,
    this.errMsg,
    this.products,
    this.width,
    this.padding = 8.0,
    required this.onRefresh,
    required this.onLoadMore,
    this.layout = 'list',
    this.ratioProductImage,
    this.productListItemHeight,
    this.scrollController,
    this.header,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late RefreshController _refreshController;

  List<Product> emptyList = [
    Product.empty('1'),
    Product.empty('2'),
    Product.empty('3'),
    Product.empty('4'),
    Product.empty('5'),
    Product.empty('6')
  ];

  @override
  void initState() {
    super.initState();

    /// if there are existing product from previous navigate we don't need to enable the refresh
    _refreshController = RefreshController(initialRefresh: false);
  }

  void _onRefresh() async {
    if (!widget.isFetching) {
      widget.onRefresh();
    }
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    if (!widget.isFetching && !widget.isEnd!) {
      await widget.onLoadMore();
    }
    _refreshController.loadComplete();
  }

  @override
  void didUpdateWidget(ProductList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFetching == false && oldWidget.isFetching == true) {
      _refreshController.refreshCompleted();
      _refreshController.loadComplete();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = Tools.isTablet(MediaQuery.of(context));

    var widthScreen = widget.width ?? screenSize.width;
    var widthContent = screenSize.width;
    var crossAxisCount = 1;
    var childAspectRatio = 0.8;

    if (Layout.isDisplayDesktop(context)) {
      widthScreen -= BackdropConstants.drawerWidth;
    }
    if (widget.layout == 'card') {
      crossAxisCount = isTablet ? 2 : 1;
      widthContent = isTablet ? widthScreen / 2 : widthScreen; //one column
    } else if (widget.layout == 'columns') {
      crossAxisCount = isTablet ? 4 : 3;
      widthContent =
          isTablet ? widthScreen / 4 : (widthScreen / 3); //three columns
    } else if (widget.layout == 'listTile') {
      crossAxisCount = isTablet ? 2 : 1;
      widthContent = widthScreen; // one column
    } else {
      /// 2 columns on mobile, 3 columns on ipad
      crossAxisCount = isTablet ? 3 : 2;
      //layout is list
      widthContent =
          isTablet ? widthScreen / 3 : (widthScreen / 2); //two columns
    }
    var itemHeight = widget.productListItemHeight ?? 125.0;
    if (kProductDetail.showQuantityInList) {
      itemHeight += 30;
    }
    if (kProductCard.showCartButton) {
      itemHeight += 30;
    }

    childAspectRatio = (isTablet ? 0.94 : 1) *
        widthContent /
        (widthContent * (widget.ratioProductImage ?? 1.2) + itemHeight);

    final hasNoProduct = widget.products == null || widget.products!.isEmpty;

    final productsList =
        hasNoProduct && widget.isFetching ? emptyList : widget.products;

    if (hasNoProduct &&
        widget.errMsg != null &&
        widget.errMsg!.isNoInternetError) {
      return NoInternetConnection(onRefresh: _onRefresh);
    }

    if (productsList == null || productsList.isEmpty) {
      return Center(
        child: Text(
          S.of(context).noProduct,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      );
    }

    Widget typeList = const SizedBox();

    if (widget.layout != Layout.pinterest) {
      if (widget.layout == Layout.listTile ||
          widget.layout == Layout.simpleList) {
        typeList = buildListView(products: productsList);
      } else {
        typeList = buildGridViewProduct(
          childAspectRatio: childAspectRatio,
          crossAxisCount: crossAxisCount,
          products: productsList,
          widthContent: widthContent,
        );
      }
    } else {
      typeList = buildStaggeredGridView(
        products: productsList,
        widthContent: widthScreen,
      );
    }

    return SmartRefresher(
      header: MaterialClassicHeader(
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      enablePullDown: true,
      enablePullUp: !widget.isEnd!,
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      footer: kCustomFooter(context),
      child: ListView(
        controller: widget.scrollController,
        children: [
          ...?widget.header,
          typeList,
        ],
      ),
    );
  }

  Widget buildGridViewProduct({
    required int crossAxisCount,
    required double childAspectRatio,
    double? widthContent,
    required List<Product> products,
  }) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      cacheExtent: 500.0,
      itemCount: products.length,
      itemBuilder: (context, i) {
        return Services().widget.renderProductCardView(
              item: products[i],
              width: widthContent,
              ratioProductImage: widget.ratioProductImage ?? 1.2,
              config: ProductConfig.empty()
                ..showHeart = true
                ..imageRatio = widget.ratioProductImage ?? 1.2
                ..showCountDown = kSaleOffProduct['ShowCountDown'] &&
                    widget.layout == Layout.saleOff
                ..showCartIcon = ProductConfig.empty().showCartIcon &&
                    (widget.layout != Layout.columns &&
                        products[i].canBeAddedToCartFromList()),
            );
      },
    );
  }

  Widget buildStaggeredGridView({
    required List<Product>? products,
    double? widthContent,
  }) {
    return MasonryGridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 4.0,
      shrinkWrap: true,
      primary: false,
      crossAxisSpacing: 8.0,
      padding: const EdgeInsets.only(
        bottom: 32,
        left: 8,
        right: 8,
      ),
      itemCount: products!.length,
      itemBuilder: (context, index) => PinterestCard(
        item: products[index],
        width: MediaQuery.of(context).size.width / 2,
        config: ProductConfig.empty()
          ..showCartIcon = ProductConfig.empty().showCartIcon &&
              widget.layout != 'columns' &&
              products[index].canBeAddedToCartFromList(),
      ),
      // staggeredTileBuilder: (index) => const StaggeredTile.fit(2),
    );
  }

  Widget buildListView({
    required List<Product>? products,
  }) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products!.length,
        itemBuilder: (_, index) {
          if (widget.layout == Layout.simpleList) {
            return ProductSimpleView(
              item: products[index],
              isFromSearchScreen: true,
            );
          }
          return Services().widget.renderProductItemTileView(
                item: products[index],
                padding: const EdgeInsets.only(bottom: 10),
                config: ProductConfig.empty(),
              );
        });
  }
}
