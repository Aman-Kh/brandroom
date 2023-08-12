import 'package:flutter/material.dart';

import '../../../models/entities/index.dart';
import '../../../models/index.dart' show Category;
import '../widgets/category_column_item.dart';

class ColumnCategories extends StatefulWidget {
  static const String type = 'column';

  final List<Category>? categories;

  const ColumnCategories(this.categories);

  @override
  State<ColumnCategories> createState() {
    return _ColumnCategoriesState();
  }
}

class _ColumnCategoriesState extends State<ColumnCategories> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: widget.categories!.length,
      // physics: const NeverScrollableScrollPhysics(),
      // shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return CategoryColumnItem(widget.categories![index]);
      },
    );
  }

  // EdgeInsets _edgeInsetsForIndex(int index) {
  //   if (index % 2 == 0) {
  //     return const EdgeInsets.only(
  //         top: 4.0, left: 8.0, right: 4.0, bottom: 4.0);
  //   } else {
  //     return const EdgeInsets.only(
  //         top: 4.0, left: 4.0, right: 8.0, bottom: 4.0);
  //   }
  // }
}
