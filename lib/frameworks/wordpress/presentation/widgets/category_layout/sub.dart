import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../common/config.dart';
import '../../../../../common/constants.dart';
import '../../../../../models/index.dart';
import '../../../../../routes/flux_navigate.dart';
import '../../../../../screens/index.dart';
import '../../../../../services/index.dart';
import '../../../../../widgets/blog/blog_card_view.dart';

class SubCategories extends StatefulWidget {
  static const String type = 'subCategories';

  final List<Category>? categories;
  const SubCategories(this.categories);

  @override
  State<StatefulWidget> createState() {
    return SubCategoriesState();
  }
}

class SubCategoriesState extends State<SubCategories> {
  int selectedIndex = 0;
  final Services _service = Services();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.categories == null || widget.categories!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories!.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Center(
                    child: Text(widget.categories![index].name!,
                        style: TextStyle(
                            fontSize: 18,
                            color: selectedIndex == index
                                ? theme.primaryColor
                                : theme.hintColor)),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FutureBuilder<List<Blog>>(
                future: _service.api.fetchBlogsByCategory(
                  lang: Provider.of<AppModel>(context, listen: false).langCode,
                  categoryId: widget.categories![selectedIndex].id,
                  page: 1,
                ),
                builder:
                    (BuildContext context, AsyncSnapshot<List<Blog>> snapshot) {
                  if (!snapshot.hasData) {
                    return kLoadingWidget(context);
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: List.generate(
                        snapshot.data!.length,
                        (index) {
                          return BlogCard(
                            item: snapshot.data![index],
                            width: constraints.maxWidth,
                            onTap: () => FluxNavigate.pushNamed(
                              RouteList.detailBlog,
                              arguments: BlogDetailArguments(
                                blog: snapshot.data![index],
                                listBlog: snapshot.data,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
