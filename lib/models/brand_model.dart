import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import '../common/constants.dart';
import '../services/dependency_injection.dart';
import '../services/services.dart';
import 'entities/product.dart';

class BrandModel with ChangeNotifier {
  List<Product>? productList = [];

  final _service = Services();
  bool isFetching = false;
  bool? isEnd;
  dynamic brandId;
  String? brandName;
  String? errMsg;
  String? brandImg;

  void fetchProductsByBrand({brandId, brandName, brandImg}) {
    this.brandId = brandId;
    this.brandName = brandName;
    this.brandImg = brandImg;
  }

  Future<void> saveProducts(Map<String, dynamic> data) async {
    final storage = injector<LocalStorage>();
    try {
      final ready = await storage.ready;
      if (ready) {
        await storage.setItem(kLocalKey['home']!, data);
      }
    } catch (err, trace) {
      printLog(err);
      printLog(trace);
    }
  }

  Future<void> getProductList(
      {brandId, orderBy, order, lang, page, minPrice, maxPrice}) async {
    try {
      if (brandId != null) {
        this.brandId = brandId;
      }
      isFetching = true;
      isEnd = false;
      final products = await _service.api.fetchProductsByBrand(
        brandId: brandId,
        page: page,
        lang: lang,
      );
      if (products!.isEmpty) {
        isEnd = true;
      }

      if (page == 0 || page == 1) {
        productList = products;
      } else {
        productList = [...productList!, ...products];
      }
      isFetching = false;
      notifyListeners();
    } catch (err) {
      errMsg = err.toString();
      isFetching = false;
      notifyListeners();
    }
  }

  void setProductList(List<Product>? products) {
    productList = products;
    isFetching = false;
    isEnd = false;
    // notifyListeners();
  }
}
