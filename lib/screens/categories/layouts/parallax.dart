import 'package:flutter/material.dart';

import '../../../common/constants.dart';
import '../../../models/index.dart' show BackDropArguments, Category;
import '../../../routes/flux_navigate.dart';
import '../../../widgets/common/parallax_image.dart';
import '../../base_screen.dart';
import '../../index.dart';

class ParallaxCategories extends StatefulWidget {
  static const String type = 'parallax';

  final List<Category>? categories;

  const ParallaxCategories(this.categories);

  @override
  BaseScreen<ParallaxCategories> createState() => _StateCardCategories();
}

class _StateCardCategories extends BaseScreen<ParallaxCategories> {
  void navigateToBackDrop(Category category) {
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
    var categories =
        widget.categories!.where((item) => item.parent == '0').toList();
    if (categories.isEmpty) {
      categories = widget.categories!;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: List.generate(
          categories.length,
          (index) {
            var category = categories[index];
            return GestureDetector(
              onTap: () {
                FluxNavigate.pushNamed(
                  RouteList.backdrop,
                  arguments: BackDropArguments(
                    cateId: category.id,
                    cateName: category.name,
                  ),
                );
              },
              child: ParallaxImage(
                image: category.image ?? '',
                name: category.name ?? '',
              ),
            );
          },
        ),
      ),
    );
  }
}
