import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../models/index.dart' show Category;
import 'container_filter.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final bool isParent;
  final bool isSelected;
  final bool? hasChild;
  final Function()? onTap;
  final int level;

  const CategoryItem(
    this.category, {
    this.isParent = false,
    this.isSelected = true,
    this.hasChild = false,
    this.onTap,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasChild!
          ? null
          : () {
              onTap!();
            },
      child: ContainerFilter(
        isSelected: isSelected,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10.0),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.check,
              color: isSelected && !isParent
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.transparent,
              size: 20,
            ),
            SizedBox(width: 10.0 * level),
            Expanded(
              child: Text(
                '${isParent ? S.of(context).seeAll : category.name}  '
                '${category.totalProduct != null && !isParent ? '(${category.totalProduct})' : ''}',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            if (hasChild!)
              Icon(
                Icons.keyboard_arrow_right,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
            const SizedBox(width: 5)
          ],
        ),
      ),
    );
  }
}
