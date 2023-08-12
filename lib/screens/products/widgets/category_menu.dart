import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart';
import 'item_category.dart';

class ProductCategoryMenu extends StatelessWidget {
  final bool enableSearchHistory;
  final bool imageLayout;
  final String? newCategoryId;
  final Function(String?)? onTap;

  const ProductCategoryMenu({
    super.key,
    this.enableSearchHistory = false,
    this.imageLayout = false,
    this.newCategoryId,
    this.onTap,
  });

  bool get categoryImageMenu => kAdvanceConfig.categoryImageMenu;

  @override
  Widget build(BuildContext context) {
    if (enableSearchHistory) {
      return const SizedBox();
    }

    final categoryModel = Provider.of<CategoryModel>(context);

    var parentCategoryId = newCategoryId;
    if (categoryModel.categories != null &&
        categoryModel.categories!.isNotEmpty) {
      parentCategoryId =
          getParentCategories(categoryModel.categories, parentCategoryId) ??
              parentCategoryId;

      var parentImage =
          categoryModel.categoryList[parentCategoryId.toString()]?.image ?? '';
      final listSubCategory =
          getSubCategories(categoryModel.categories, parentCategoryId)!;

      if (listSubCategory.length < 2) {
        return const SizedBox();
      }

      return ListenableProvider.value(
        value: categoryModel,
        child: Consumer<CategoryModel>(builder: (context, value, child) {
          final listSubCategory =
              getSubCategories(categoryModel.categories, parentCategoryId)!;

          if (value.isLoading) {
            return Center(child: kLoadingWidget(context));
          }

          if (value.categories != null) {
            var renderListCategory = <Widget>[];
            var categoryMenu = categoryImageMenu;

            renderListCategory.add(
              ItemCategory(
                categoryId: parentCategoryId,
                categoryName: S.of(context).seeAll,
                categoryImage:
                    categoryMenu && parentImage.isNotEmpty && imageLayout
                        ? parentImage
                        : null,
                newCategoryId: newCategoryId,
                onTap: onTap,
              ),
            );

            renderListCategory.addAll(
              [
                for (var category in listSubCategory)
                  ItemCategory(
                    categoryId: category.id,
                    categoryName: category.name!,
                    categoryImage:
                        categoryMenu && imageLayout ? category.image : null,
                    newCategoryId: newCategoryId,
                    onTap: onTap,
                  ),
              ],
            );

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: Theme.of(context).backgroundColor,
              constraints: const BoxConstraints(minHeight: 50),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: renderListCategory,
                  ),
                ),
              ),
            );
          }

          return const SizedBox();
        }),
      );
    }
    return const SizedBox();
  }

  String? getParentCategories(categories, id) {
    for (var item in categories) {
      if (item.id == id) {
        return (item.parent == null || item.parent == '0') ? null : item.parent;
      }
    }
    return '0';
  }

  List<Category>? getSubCategories(categories, id) {
    return categories.where((o) => o.parent == id).toList();
  }
}
