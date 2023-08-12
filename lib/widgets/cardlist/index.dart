import 'package:flutter/material.dart';

import '../../models/index.dart' show Category;
import '../../services/index.dart';
import 'menu_card.dart';

class HorizonMenu extends StatefulWidget {
  static const String type = 'animation';

  final List<Category>? categories;

  const HorizonMenu(this.categories);

  @override
  State<HorizonMenu> createState() => _StateHorizonMenu();
}

class _StateHorizonMenu extends State<HorizonMenu> {
  @override
  void initState() {
    Services().api.getCategoryWithCache();
    super.initState();
  }

  List<Category> getCategory() {
    final categories = widget.categories!;
    return categories.where((item) => item.parent == '0').toList();
  }

  List getChildrenOfCategory(Category category) {
    final categories = widget.categories!;
    var children = categories.where((o) => o.parent == category.id).toList();
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final categories = getCategory();

    return Column(
      children: List.generate(
        categories.length,
        (index) {
          return MenuCard(
              getChildrenOfCategory(categories[index]) as List<Category>,
              categories[index]);
        },
      ),
    );
  }
}
