import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart' show Skeleton;
import 'package:transparent_image/transparent_image.dart';

import '../../../common/constants.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show BackDropArguments, Category;
import '../../../routes/flux_navigate.dart';
import '../../../widgets/common/parallax_image.dart';
import '../../../widgets/common/tree_view.dart';
import '../../base_screen.dart';
import '../../index.dart';

class CardCategories extends StatefulWidget {
  static const String type = 'card';
  final bool enableParallax;
  final double? parallaxImageRatio;

  final List<Category>? categories;

  const CardCategories(
      {this.categories, required this.enableParallax, this.parallaxImageRatio});

  @override
  BaseScreen<CardCategories> createState() => _StateCardCategories();
}

class _StateCardCategories extends BaseScreen<CardCategories> {
  ScrollController controller = ScrollController();
  late double page;

  @override
  void initState() {
    page = 0.0;
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    controller.addListener(() {
      setState(() {
        page = _getPage(controller.position, screenSize.width * 0.30 + 10);
      });
    });
  }

  bool hasChildren(id) {
    return widget.categories!.where((o) => o.parent == id).toList().isNotEmpty;
  }

  double _getPage(ScrollPosition position, double width) {
    return position.pixels / width;
  }

  List<Category> getSubCategories(id) {
    return widget.categories!.where((o) => o.parent == id).toList();
  }

  void navigateToBackDrop(Category category) {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: category.id,
        cateName: category.name,
      ),
    );
  }

  Widget getChildCategoryList(category) {
    return ChildList(
      children: [
        GestureDetector(
          onTap: () => navigateToBackDrop(category),
          child: SubItem(
            category,
            seeAll: S.of(context).seeAll,
          ),
        ),
        for (var category in getSubCategories(category.id))
          Parent(
            callback: (isSelected) {
              if (getSubCategories(category.id).isEmpty) {
                navigateToBackDrop(category);
              }
            },
            parent: SubItem(category),
            childList: ChildList(
              children: [
                for (var cate in getSubCategories(category.id))
                  Parent(
                    callback: (isSelected) {
                      if (getSubCategories(cate.id).isEmpty) {
                        FluxNavigate.pushNamed(
                          RouteList.backdrop,
                          arguments: BackDropArguments(
                            cateId: cate.id,
                            cateName: cate.name,
                          ),
                        );
                      }
                    },
                    parent: SubItem(cate, level: 1),
                    childList: ChildList(
                      children: [
                        for (var cate in getSubCategories(cate.id))
                          Parent(
                            callback: (isSelected) {
                              FluxNavigate.pushNamed(
                                RouteList.backdrop,
                                arguments: BackDropArguments(
                                  cateId: cate.id,
                                  cateName: cate.name,
                                ),
                              );
                            },
                            parent: SubItem(cate, level: 2),
                            childList: const ChildList(children: []),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var categories =
        widget.categories!.where((item) => item.parent == '0').toList();
    if (categories.isEmpty) {
      categories = widget.categories!;
    }

    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.vertical,
      child: TreeView(
        parentList: List.generate(
          categories.length,
          (index) {
            return Parent(
              parent: _CategoryCardItem(
                categories[index],
                hasChildren: hasChildren(categories[index].id),
                offset: page - index,
                enableParallax: widget.enableParallax,
                parallaxImageRatio: widget.parallaxImageRatio,
              ),
              childList: getChildCategoryList(categories[index]) as ChildList,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCardItem extends StatelessWidget {
  final Category category;
  final bool hasChildren;
  final bool enableParallax;
  final double? parallaxImageRatio;
  final offset;

  const _CategoryCardItem(
    this.category, {
    this.hasChildren = false,
    this.offset,
    this.enableParallax = false,
    this.parallaxImageRatio,
  });

  /// Render category Image support caching on ios/android
  /// also fix loading on Web
  Widget renderCategoryImage(maxWidth) {
    final image = category.image ?? '';
    if (image.isEmpty) return const SizedBox();

    var imageProxy = '$kImageProxy${maxWidth}x,q30/';

    if (image.contains('http') && kIsWeb) {
      return FadeInImage.memoryNetwork(
        image: '$imageProxy$image',
        fit: BoxFit.cover,
        width: maxWidth,
        height: maxWidth * 0.35,
        placeholder: kTransparentImage,
      );
    }

    return image.contains('http')
        ? CachedNetworkImage(
            imageUrl: category.image!,
            fit: BoxFit.cover,
            alignment: Alignment(
              0.0,
              (offset >= -1 && offset <= 1)
                  ? offset
                  : (offset > 0)
                      ? 1.0
                      : -1.0,
            ),
            // fadeInCurve: Curves.easeIn,
            errorWidget: (context, url, error) => const SizedBox(),
            imageBuilder:
                (BuildContext context, ImageProvider<dynamic> imageProvider) {
              return Image(
                width: maxWidth,
                image: imageProvider as ImageProvider<Object>,
                fit: BoxFit.cover,
              );
            },
            placeholder: (context, url) => Skeleton(
              width: maxWidth,
              height: maxWidth * 0.35,
            ),
          )
        : Image.asset(
            category.image!,
            fit: BoxFit.cover,
            width: maxWidth,
            height: maxWidth * 0.35,
            alignment: Alignment(
              0.0,
              (offset >= -1 && offset <= 1)
                  ? offset
                  : (offset > 0)
                      ? 1.0
                      : -1.0,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: hasChildren
          ? null
          : () {
              FluxNavigate.pushNamed(
                RouteList.backdrop,
                arguments: BackDropArguments(
                  cateId: category.id,
                  cateName: category.name,
                ),
              );
            },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (enableParallax) {
            return Container(
              height: constraints.maxWidth * 0.35,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 10, right: 10),
              margin: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ParallaxImage(
                  image: category.image ?? '',
                  name: category.name ?? '',
                  ratio: 2.2,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),
              ),
            );
          }

          return Container(
            height: constraints.maxWidth * 0.35,
            padding: const EdgeInsets.only(left: 10, right: 10),
            margin: const EdgeInsets.only(bottom: 10),
            child: Stack(
              children: <Widget>[
                ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(3.0)),
                    child: renderCategoryImage(constraints.maxWidth)),
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * 0.35,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.3),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth /
                        (2 / (screenSize.height / constraints.maxWidth)),
                    height: constraints.maxWidth * 0.35,
                    child: Center(
                      child: Text(
                        category.name?.toUpperCase() ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SubItem extends StatelessWidget {
  final Category category;
  final String seeAll;
  final int level;

  const SubItem(this.category, {this.seeAll = '', this.level = 0});

  void showProductList() {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: category.id,
        cateName: category.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      width: screenSize.width,
      child: FittedBox(
        fit: BoxFit.cover,
        child: Container(
          width:
              screenSize.width / (2 / (screenSize.height / screenSize.width)),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 0.5,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(level == 0 && seeAll == '' ? 0.2 : 0),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 15.0),
              for (int i = 1; i <= level; i++)
                Container(
                  width: 10.0,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 1.5,
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  seeAll != '' ? seeAll : category.name!,
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
              if ((category.totalProduct ?? 0) > 0)
                GestureDetector(
                  onTap: showProductList,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text(
                      S.of(context).nItems(category.totalProduct.toString()),
                      style: Theme.of(context).textTheme.caption!.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right),
                onPressed: showProductList,
              )
            ],
          ),
        ),
      ),
    );
  }
}
