import 'package:flutter/material.dart';
import '../../../../../../models/index.dart';

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
    super.initState();
  }

  List<Category>? getCategory() {
    final categories = widget.categories;
    return categories?.where((item) => item.parent.toString() == '0').toList();
  }

  List<Category>? getChildrenOfCategory(Category category) {
    final categories = widget.categories;
    var children = categories
        ?.where((o) => o.parent.toString() == category.id.toString())
        .toList();
    return children;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories == null || widget.categories!.isEmpty) {
      return const SizedBox();
    }
    final categories = getCategory()!;
    return Column(
      children: List.generate(
        categories.length,
        (index) {
          return MenuCard(
              getChildrenOfCategory(categories[index])!, categories[index]);
        },
      ),
    );
  }
}
