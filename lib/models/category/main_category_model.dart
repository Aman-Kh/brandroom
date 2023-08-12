import '../entities/category.dart';
import 'category_model.dart';
import 'detail_category_model.dart';
import 'list_category_model.dart';

class MainCategoryModel extends ListCategoryModel implements CategoryModel {
  MainCategoryModel() : super(parentId: null, limit: 10);

  final Map<String, DetailCategoryModel> _subCategories = {};

  @override
  void initSubcategory(Category category, {bool fetchData = false}) {
    if (_subCategories[category.id] != null) {
      return;
    }
    final model = DetailCategoryModel(category: category);
    if (fetchData) {
      model.initData();
    }
    _subCategories[category.id!] = model;
  }

  @override
  DetailCategoryModel? getDetailCategoryModel(String id) {
    if (_subCategories.containsKey(id)) {
      return _subCategories[id];
    }
    return null;
  }

  /// All methods below support the BaseCategoryModel interface

  @override
  Future<void> getCategories({
    lang,
    sortingList,
    categoryLayout,
    List<Map>? remapCategories,
  }) =>
      getData();

  @override
  List<Category>? getCategory({
    required String parentId,
  }) =>
      null;

  @override
  void mapCategories(
    List<Category> categories,
    List<Map> remapCategories,
  ) {}

  @override
  void sortCategoryList({
    List<Category>? categoryList,
    sortingList,
    String? categoryLayout,
  }) {}

  @override
  List<Category>? get categories => data;

  @override
  Map<String?, Category> get categoryList => const <String?, Category>{};
}
