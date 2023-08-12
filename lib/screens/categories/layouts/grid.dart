import 'package:flutter/material.dart';
import 'package:inspireui/icons/icon_picker.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/entities/index.dart';
import '../../../models/index.dart' show Category, AppModel;
import '../../../routes/flux_navigate.dart';
import '../../../widgets/common/flux_image.dart';

class GridCategory extends StatefulWidget {
  static const String type = 'grid';

  final List<Category>? categories;

  const GridCategory(this.categories);

  @override
  State<GridCategory> createState() => _StateGridCategory();
}

class _StateGridCategory extends State<GridCategory> {
  Widget renderIcon(String categoryId, Map icons) {
    var icon = icons[categoryId];
    if (icon is Map) {
      return Icon(iconPicker(icon['name'], icon['fontFamily']), size: 30);
    }
    if (icon is String) {
      return FluxImage(
        imageUrl: icon,
        width: 35,
        height: 35,
      );
    }
    return const Icon(Icons.category, size: 30);
  }

  @override
  Widget build(BuildContext context) {
    var categories = widget.categories;
    var categoriesIcons =
        Provider.of<AppModel>(context, listen: true).categoriesIcons;
    var icons = categoriesIcons ?? kGridIconsCategories;

    if (categories == null) {
      return Container(
        child: kLoadingWidget(context),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              for (int i = 0; i < categories.length; i++)
                GestureDetector(
                  onTap: () => FluxNavigate.pushNamed(
                    RouteList.backdrop,
                    arguments: BackDropArguments(
                      cateId: categories[i].id,
                      cateName: categories[i].name,
                    ),
                  ),
                  child: Container(
                    width: constraints.maxWidth / kAdvanceConfig.gridCount -
                        8 * kAdvanceConfig.gridCount,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 20,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: <Widget>[
                          renderIcon(categories[i].id!, icons),
                          const SizedBox(height: 8.0),
                          Text(
                            categories[i].name!,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
