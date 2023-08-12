import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/tools/flash.dart';
import '../../generated/l10n.dart';
import '../../models/app_model.dart';
import '../../models/brand_model.dart';
import '../../models/entities/filter_sorty_by.dart';
import '../../models/entities/product.dart';
import '../../modules/firebase/dynamic_link_service.dart';
import '../../services/services.dart';
import '../../widgets/backdrop/backdrop.dart';
import '../../widgets/backdrop/backdrop_menu.dart';
import '../../widgets/common/flux_image.dart';
import '../../widgets/product/product_list.dart';

class BrandPage extends StatefulWidget {
  final dynamic brandId;
  final config;

  const BrandPage({this.brandId, this.config});

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage>
    with SingleTickerProviderStateMixin {
  dynamic newBrandId = -1;
  String? orderBy;
  String? order;
  String? errMsg;
  double? minPrice;
  double? maxPrice;
  int page = 1;
  bool isFiltering = false;
  List<Product> products = [];

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    setState(() {
      newBrandId = widget.brandId;
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );

    if (widget.config != null) {
      onRefresh();
    }
  }

  void onFilter({
    dynamic minPrice,
    dynamic maxPrice,
    String? categoryId,
    String? categoryName,
    String? tagId,
    String? brandId,
    dynamic attribute,
    dynamic currentSelectedTerms,
    dynamic listingLocationId,
    String? orderBy,
    String? order,
    FilterSortBy? sortBy,
  }) {
    _controller.forward();
    final brandModel = Provider.of<BrandModel>(context, listen: false);
    newBrandId = brandId;
    this.minPrice = minPrice;
    this.maxPrice = maxPrice;
    page = 1;
    brandModel.setProductList(null);
    brandModel.getProductList(
      brandId: brandId,
      page: page,
      lang: Provider.of<AppModel>(context, listen: false).langCode,
      orderBy: orderBy,
      order: order,
    );
  }

  void onSort(order) {
    orderBy = 'date';
    this.order = order;
    page = 1;
    Provider.of<BrandModel>(context, listen: false).getProductList(
      brandId: newBrandId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      lang: Provider.of<AppModel>(context, listen: false).langCode,
      page: page,
      orderBy: orderBy,
      order: order,
    );
  }

  Future<void> onRefresh() async {
    if (widget.config == null) {
      page = 1;
      await Provider.of<BrandModel>(context, listen: false).getProductList(
          brandId: newBrandId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          lang: Provider.of<AppModel>(context, listen: false).langCode,
          page: page,
          orderBy: orderBy,
          order: order);
    }
  }

  void onLoadMore() {
    page += 1;
    Provider.of<BrandModel>(context, listen: false).getProductList(
        brandId: newBrandId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        lang: Provider.of<AppModel>(context, listen: false).langCode,
        page: page,
        orderBy: orderBy,
        order: order);
  }

  @override
  Widget build(BuildContext context) {
    final brandModel = Provider.of<BrandModel>(context);
    final title = brandModel.brandName;
    final img = brandModel.brandImg;

    _PostBackdrop backdrop({products, isFetching, errMsg, isEnd}) =>
        _PostBackdrop(
          backdrop: Backdrop(
            frontLayer: ProductList(
              products: products,
              onRefresh: onRefresh,
              onLoadMore: onLoadMore,
              isFetching: isFetching,
              errMsg: errMsg,
              isEnd: isEnd,
              productListItemHeight: kProductDetail.productListItemHeight,
            ),
            backLayer: BackdropMenu(
              onFilter: onFilter,
              showCategory: false,
              showPrice: false,
              showSort: false,
            ),
            frontTitle: Row(
              children: [
                if (img != null)
                  Container(
                      width: 53.0,
                      height: 43.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3.0)),
                      child: FluxImage(
                          imageUrl: img,
                          width: 50.0,
                          height: 40.0,
                          fit: BoxFit.cover)),
                const SizedBox(
                  width: 15.0,
                ),
                Text(title!)
              ],
            ),
            backTitle: Text(S.of(context).filter),
            controller: _controller,
            showFilter: false,
            onTapShareButton: () async {
              unawaited(
                FlashHelper.message(
                  context,
                  message: S.of(context).generatingLink,
                  duration: const Duration(seconds: 2),
                ),
              );
              var currentCateId =
                  Provider.of<BrandModel>(context, listen: false).brandId;
              var cateUrl = await DynamicLinkService()
                  .generateProductBrandUrl(currentCateId);
              Services().firebase.shareDynamicLinkProduct(
                    itemUrl: cateUrl,
                  );
            },
          ),
        );

    return ListenableProvider.value(
      value: brandModel,
      child: Consumer<BrandModel>(builder: (context, value, child) {
        return backdrop(
            products: brandModel.productList,
            isFetching: value.isFetching,
            errMsg: value.errMsg,
            isEnd: value.isEnd);
      }),
    );
  }
}

class _PostBackdrop extends StatelessWidget {
//  final ExpandingBottomSheet expandingBottomSheet;
  final Backdrop backdrop;

  const _PostBackdrop({Key? key, required this.backdrop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        backdrop,
      ],
    );
  }
}
