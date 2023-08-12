import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../../../models/category/list_category_model.dart';
import '../../../widgets/common/refresh_scroll_physics.dart';
import '../../categories/widgets/category_column_item.dart';
import '../models/subcategory_model.dart';

const _crossAxisCount = 3;

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: _crossAxisCount,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
);

class SubcategoryArguments {
  final String parentId;
  final String? categoryName;

  const SubcategoryArguments({
    required this.parentId,
    this.categoryName,
  });
}

class SubcategoryScreen extends StatefulWidget {
  final String? categoryName;
  const SubcategoryScreen({Key? key, this.categoryName}) : super(key: key);

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final _scrollController = ScrollController();

  ListCategoryModel get _listSubcategoryModel =>
      Provider.of<ListCategoryModel>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentBefore > 200 &&
          _scrollController.position.extentAfter < 500) {
        _listSubcategoryModel.getData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListCategoryModel>(
      builder: (context, listSubcategoryModel, child) {
        final showLoadingWidget = _scrollController.hasClients
            ? listSubcategoryModel.isLoading &&
                _scrollController.position.extentBefore > 200
            : false;

        return Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            physics: const RefreshScrollPhysics(),
            slivers: [
              Consumer<SubcategoryModel>(
                builder: (context, subcategoryModel, child) {
                  Widget title = const Align(
                    alignment: Alignment.centerLeft,
                    child: Skeleton(width: 120, height: 38),
                  );

                  final categoryName = widget.categoryName ??
                      subcategoryModel.parentCategory?.name;
                  if (categoryName != null) {
                    title = Text(categoryName);
                  }

                  return CupertinoSliverNavigationBar(largeTitle: title);
                },
              ),
              CupertinoSliverRefreshControl(
                onRefresh: _listSubcategoryModel.refresh,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: Consumer<ListCategoryModel>(
                  builder: (context, listSubcategoryModel, child) {
                    final listSubcategory = listSubcategoryModel.data;
                    if (listSubcategory == null) {
                      return _buildLoading();
                    }

                    if (listSubcategory.isEmpty) {
                      return _buildEmptyData();
                    }

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return CategoryColumnItem(listSubcategory[index]);
                        },
                        childCount: listSubcategory.length,
                      ),
                      gridDelegate: _gridDelegate,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: const Offset(0.0, 0.0),
                    ).animate(animation);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  duration: const Duration(milliseconds: 300),
                  child: showLoadingWidget
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: CircularProgressIndicator(),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading({int length = 6}) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return const Skeleton();
        },
        childCount: length,
      ),
      gridDelegate: _gridDelegate,
    );
  }

  Widget _buildEmptyData() {
    return SliverFillRemaining(
      child: Center(
        child: Text(S.of(context).noData),
      ),
    );
  }
}
