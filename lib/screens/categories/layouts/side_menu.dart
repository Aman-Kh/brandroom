import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../models/index.dart' show AppModel, Category, Product;
import '../../../modules/dynamic_layout/index.dart';
import '../../../services/index.dart';
import '../../../widgets/product/product_list.dart';
import '../../base_screen.dart';

class SideMenuCategories extends StatefulWidget {
  static const String type = 'sideMenu';

  final List<Category>? categories;

  const SideMenuCategories(this.categories);

  @override
  State<StatefulWidget> createState() => SideMenuCategoriesState();
}

class SideMenuCategoriesState extends State<SideMenuCategories> {
  int selectedIndex = 0;

  List<Category> getSubCategories(id) {
    return widget.categories!.where((o) => o.parent == id).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SideMenuCategories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories?.length != widget.categories?.length) {
      setState(() {
        selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var categories =
        widget.categories!.where((item) => item.parent == '0').toList();
    if (categories.isEmpty) {
      categories = widget.categories!;
    }

    if (categories.isEmpty) return const SizedBox();
    return Row(
      children: <Widget>[
        SizedBox(
          width: 100,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 15, bottom: 15, left: 4, right: 4),
                  child: Center(
                    child: Text(
                      categories[index].name != null
                          ? categories[index].name!.toUpperCase()
                          : '',
                      style: TextStyle(
                        fontSize: 10,
                        color: selectedIndex == index
                            ? theme.primaryColor
                            : theme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
            child: FetchProductLayout(
          key: Key(categories[selectedIndex].toString()),
          category: categories[selectedIndex],
          subCategories: getSubCategories(categories[selectedIndex].id),
        ))
      ],
    );
  }
}

class FetchProductLayout extends StatefulWidget {
  final Category? category;
  final List<Category>? subCategories;

  const FetchProductLayout({this.category, this.subCategories, Key? key})
      : super(key: key);

  @override
  BaseScreen<FetchProductLayout> createState() => _StateFetchProductLayout();
}

class _StateFetchProductLayout extends BaseScreen<FetchProductLayout> {
  int selectedIndex = 0;
  int page = 1;
  bool isEnd = false;
  bool isFetching = true;
  late CancelableCompleter completer;
  final Services _service = Services();
  List<Product> products = [];

  void onLoadMore() async {
    setState(() {
      isFetching = true;
    });
    if (widget.subCategories != null && widget.subCategories!.isNotEmpty) {
      for (var item in widget.subCategories!) {
        setState(() {
          completer = CancelableCompleter();
        });
        completer.complete(_service.api.fetchProductsByCategory(
            lang: Provider.of<AppModel>(context, listen: false).langCode,
            categoryId: item.id,
            page: page + 1));
        completer.operation.then((value) {
          setState(() {
            products = [...products, ...value];
            isFetching = false;
            page = page + 1;
          });
        });
      }
    } else {
      setState(() {
        completer = CancelableCompleter();
      });
      completer.complete(_service.api.fetchProductsByCategory(
          lang: Provider.of<AppModel>(context, listen: false).langCode,
          categoryId: widget.category!.id,
          page: page + 1));
      completer.operation.then((value) {
        if (value.length < 2) {
          setState(() {
            isEnd = true;
          });
        }
        setState(() {
          products = [...products, ...value];
          isFetching = false;
          page = page + 1;
        });
      });
    }
  }

  void onRefresh() async {
    setState(() {
      isFetching = true;
      products = [];
    });
    if (widget.subCategories!.isNotEmpty) {
      for (var item in widget.subCategories!) {
        setState(() {
          completer = CancelableCompleter();
        });
        completer.complete(_service.api.fetchProductsByCategory(
            lang: Provider.of<AppModel>(context, listen: false).langCode,
            categoryId: item.id,
            page: 1));
        completer.operation.then((value) {
          setState(() {
            products = [...products, ...value];
            isFetching = false;
            isEnd = false;
            page = 1;
          });
        });
      }
    } else {
      setState(() {
        completer = CancelableCompleter();
      });
      completer.complete(_service.api.fetchProductsByCategory(
          lang: Provider.of<AppModel>(context, listen: false).langCode,
          categoryId: widget.category!.id,
          page: 1));
      completer.operation.then((value) {
        setState(() {
          products = [...products, ...value];
          isFetching = false;
          isEnd = false;
          page = 1;
        });
      });
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {
    onRefresh();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return ProductList(
      isFetching: isFetching,
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      isEnd: isEnd,
      products: products,
      width: screenSize.width - 100,
      padding: 4.0,
      layout: 'list',
      ratioProductImage: ProductConfig.empty().imageRatio,
      productListItemHeight: kProductDetail.productListItemHeight,
    );
  }
}
