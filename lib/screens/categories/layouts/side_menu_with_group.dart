import 'package:flutter/material.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../generated/l10n.dart';
import '../../../models/entities/index.dart';
import '../../../routes/flux_navigate.dart';
import '../../../services/services.dart';

class SideMenuGroupCategories extends StatefulWidget {
  static const String type = 'sideMenuWithGroup';

  final List<Category>? categories;
  final Map<String, dynamic>? icons;

  const SideMenuGroupCategories(this.categories, {this.icons});

  @override
  State<StatefulWidget> createState() => SideMenuGroupCategoriesState();
}

class SideMenuGroupCategoriesState extends State<SideMenuGroupCategories> {
  int selectedIndex = 0;

  @override
  void didUpdateWidget(covariant SideMenuGroupCategories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories?.length != widget.categories?.length) {
      setState(() {
        selectedIndex = 0;
      });
    }
  }

  List<Category> getSubCategories(id) {
    return widget.categories!.where((o) => o.parent == id).toList();
  }

  Map<String, dynamic> getListIcons() {
    var icons = <String?, dynamic>{};
    for (var cat in widget.categories!) {
      if (cat.image != null && cat.image!.isNotEmpty) {
        icons[cat.id] = cat.image;
      }
    }
    return Map<String, dynamic>.from(icons);
  }

  List<Category> getListCategories() {
    var categories = <Category>[];
    for (var cat in widget.categories!) {
      if (cat.parent == '0') {
        categories.add(cat);
      }
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.categories == null) {
      return Container(
        child: kLoadingWidget(context),
      );
    }

    var categories = getListCategories();
    var icons = getListIcons();

    if (categories.isEmpty) {
      return const SizedBox();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 70,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? theme.primaryColorLight
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 4.0,
                      left: 6,
                    ),
                    child: AnimatedDefaultTextStyle(
                      style: selectedIndex == index
                          ? TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            )
                          : TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.secondary,
                            ),
                      maxLines: 2,
                      softWrap: true,
                      duration: const Duration(milliseconds: 200),
                      child: Text(categories[index].name ?? ''),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: GridSubCategory(
            getSubCategories(categories[selectedIndex].id),
            key: Key('${categories[selectedIndex]}'),
            parentCategory: categories[selectedIndex],
            parentCategoryImage: kGridIconsCategories[
                    int.tryParse(categories[selectedIndex].id!) ?? -1] ??
                icons[categories[selectedIndex].id!],
            icons: icons,
          ),
        ),
      ],
    );
  }
}

class GridSubCategory extends StatefulWidget {
  final List<Category> categories;
  final Map<String, dynamic>? icons;

  final Category? parentCategory;
  final String? parentCategoryImage;

  const GridSubCategory(
    this.categories, {
    this.icons,
    this.parentCategory,
    this.parentCategoryImage,
    Key? key,
  }) : super(key: key);

  @override
  State<GridSubCategory> createState() => _StateGridSubCategory();
}

class _StateGridSubCategory extends State<GridSubCategory> {
  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;

    // ignore: unnecessary_null_comparison
    if (categories == null) {
      return Container(
        child: kLoadingWidget(context),
      );
    }

    if (categories.isEmpty && widget.parentCategory != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Theme.of(context).primaryColorLight,
        ),
        padding: const EdgeInsets.only(top: 20.0, left: 10.0),
        child: Services().widget.renderHorizontalListItem({
          'category': widget.parentCategory!.id,
          'name': widget.parentCategory!.name,
          'rows': 2,
        }),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.only(top: 10.0, left: 10.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: List<Widget>.generate(
                categories.length,
                (i) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Services().widget.renderHorizontalListItem({
                      'category': categories[i].id,
                      'name': categories[i].name,
                      'rows': 2,
                    }),
                  );
                },
              )..insertAll(
                  0,
                  [
                    if ((widget.parentCategoryImage != null &&
                            widget.parentCategoryImage!.isNotEmpty) &&
                        (categories.isEmpty))
                      Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        padding: const EdgeInsets.all(4.0),
                        alignment: Alignment.centerRight,
                        child: InkResponse(
                          onTap: _seeAllProduct,
                          child: Text(
                            S.of(context).seeAll,
                            style: TextStyle(
                              fontSize: kIsWeb ? 18 : 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    if ((widget.parentCategoryImage == null ||
                            widget.parentCategoryImage!.isEmpty) &&
                        (categories.isEmpty))
                      SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: InkResponse(
                            onTap: _seeAllProduct,
                            child: Text(
                              S.of(context).seeAll,
                              style: TextStyle(
                                fontSize: kIsWeb ? 18 : 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ),
          ),
        );
      },
    );
  }

  void _seeAllProduct() {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: widget.parentCategory!.id,
        cateName: widget.parentCategory!.name,
      ),
    );
  }
}
