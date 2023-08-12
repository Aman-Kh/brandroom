import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../models/index.dart' show AppModel, Category, Product, UserModel;
import '../../../services/index.dart';
import '../../../widgets/product/product_list.dart';
import '../../base_screen.dart';

class SubCategories extends StatelessWidget {
  static const String type = 'subCategories';

  final List<Category>? categories;

  const SubCategories(this.categories);

  @override
  Widget build(BuildContext context) {
    var key = (categories != null && categories!.isNotEmpty)
        ? categories.toString()
        : SubCategories.type;

    return SubCategoriesLayout(categories, key: Key(key));
  }
}

class SubCategoriesLayout extends StatefulWidget {
  final List<Category>? categories;

  const SubCategoriesLayout(this.categories, {Key? key}) : super(key: key);

  @override
  BaseScreen<SubCategoriesLayout> createState() => _StateSubCategoriesLayout();
}

class _StateSubCategoriesLayout extends BaseScreen<SubCategoriesLayout> {
  int selectedIndex = 0;
  int page = 1;
  bool isFetching = true;
  bool isEnd = false;
  List<Product>? products = [];
  CancelableCompleter completer = CancelableCompleter();
  final Services _service = Services();

  @override
  void afterFirstLayout(BuildContext context) {
    onRefresh();
  }

  void onLoadMore() async {
    setState(() {
      isFetching = true;
      completer = CancelableCompleter();
    });
    List<Product>? newProducts;
    final userId = Provider.of<UserModel>(context, listen: false).user?.id;
    completer.complete(_service.api.fetchProductsByCategory(
        lang: Provider.of<AppModel>(context, listen: false).langCode,
        categoryId: widget.categories![selectedIndex].id,
        page: page + 1,
        userId: userId));
    completer.operation.then((value) {
      newProducts = value;
      if (newProducts!.length < 2) {
        setState(() {
          isEnd = true;
        });
      }
      setState(() {
        isFetching = false;
        products = [...products!, ...newProducts!];
        page = page + 1;
      });
    });
  }

  void onRefresh() async {
    setState(() {
      isFetching = true;
      completer = CancelableCompleter();
    });
    try {
      final userId = Provider.of<UserModel>(context, listen: false).user?.id;
      completer.complete(_service.api.fetchProductsByCategory(
          lang: Provider.of<AppModel>(context, listen: false).langCode,
          categoryId: widget.categories![selectedIndex].id,
          page: 1,
          userId: userId));
      completer.operation.then((value) {
        setState(() {
          isFetching = false;
          products = value;
          isEnd = false;
          page = 1;
        });
      });
    } catch (e) {
      setState(() {
        isFetching = false;
        products = [];
        isEnd = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.categories!.isEmpty) {
      return const SizedBox();
    }

    if ((products == null) && !isFetching) {
      return const SizedBox();
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories!.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                    page = 1;
                    isFetching = true;
                    isEnd = false;
                    products = [];
                    completer.operation.cancel();
                  });
                  onRefresh();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Center(
                    child: Text(widget.categories![index].name!,
                        style: TextStyle(
                            fontSize: 18,
                            color: selectedIndex == index
                                ? theme.primaryColor
                                : theme.hintColor)),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ProductList(
                width: constraints.maxWidth,
                products: products,
                isEnd: isEnd,
                isFetching: isFetching,
                onLoadMore: onLoadMore,
                onRefresh: onRefresh,
                layout: Provider.of<AppModel>(context, listen: false)
                    .productListLayout,
                ratioProductImage: Provider.of<AppModel>(context, listen: false)
                    .ratioProductImage,
                productListItemHeight: kProductDetail.productListItemHeight,
              );
            },
          ),
        )
      ],
    );
  }
}
