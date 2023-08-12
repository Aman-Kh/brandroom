import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../generated/l10n.dart';
import '../../models/category/category_model.dart';
import '../../models/category/detail_category_model.dart';
import 'widgets/list_category.dart';
import 'widgets/list_product.dart';

const _numberOfTabPreload = 3;

class MainCategoryScreen extends StatefulWidget {
  const MainCategoryScreen({Key? key}) : super(key: key);

  @override
  State<MainCategoryScreen> createState() => _MainCategoryScreenState();
}

class _MainCategoryScreenState extends State<MainCategoryScreen>
    with SingleTickerProviderStateMixin {
  CategoryModel get model => Provider.of<CategoryModel>(context, listen: false);

  TabController? _tabController;

  void _onChanged([int? index]) {
    final data = model.categories;
    if (data == null) return;
    final selectedIndex = index ?? _tabController?.index;
    if (selectedIndex == null) return;
    final element = data[selectedIndex];
    model.getDetailCategoryModel(element.id!)?.initData();
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Theme.of(context).backgroundColor,
        title: Text(
          S.of(context).category,
          style: Theme.of(context)
              .textTheme
              .headline5
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Consumer<CategoryModel>(
        builder: (context, model, child) {
          if (model.categories == null) {
            if (model.isLoading) {
              return Center(child: kLoadingWidget(context));
            } else {
              return const Center(child: Text('No data'));
            }
          }
          final data = model.categories!;
          for (var i = 0; i < data.length; i++) {
            final element = data[i];
            model.initSubcategory(element,
                fetchData: i <
                    math.min(
                      data.length,
                      _numberOfTabPreload,
                    ));
          }
          _tabController ??= TabController(
            length: data.length,
            vsync: this,
          )..addListener(_onChanged);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    onTap: _onChanged,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    indicatorColor: Theme.of(context).primaryColor,
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: data
                        .map((e) => Tab(
                              text: e.displayName.toUpperCase(),
                            ))
                        .toList()),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: data.map(
                    (e) {
                      final detailCategoryModel =
                          model.getDetailCategoryModel(e.id!);
                      if (detailCategoryModel == null) {
                        return const SizedBox();
                      }
                      return ChangeNotifierProvider.value(
                        value: detailCategoryModel,
                        child: Selector<DetailCategoryModel, bool?>(
                          shouldRebuild: (previous, next) {
                            return previous != next;
                          },
                          selector: (context, provider) => provider.hasChildren,
                          builder: (context, hasChildren, child) {
                            if (hasChildren == null) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (hasChildren) {
                              return ChangeNotifierProvider.value(
                                value: detailCategoryModel.subcategoryModel,
                                child: ListCategory(category: e),
                              );
                            }
                            return ChangeNotifierProvider.value(
                              value: detailCategoryModel.listProductModel,
                              child: const ListProduct(),
                            );
                          },
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
