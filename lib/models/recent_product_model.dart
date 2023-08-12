import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import '../services/dependency_injection.dart';
import 'entities/product.dart';

class RecentModel with ChangeNotifier {
  List<Product> products = [];
  final storage = injector<LocalStorage>();

  void addRecentProduct(Product? product) {
    if (product == null) {
      return;
    }
    var data = [];
    products.removeWhere((index) => index.id == product.id);
    if (products.length == 20) products.removeLast();
    products.insert(0, product);
    for (var item in products) {
      data.add(item.toJson());
    }
    storage.setItem('recent', data);
    notifyListeners();
  }

  Future<List<Product>> getRecentProduct() {
    var data = storage.getItem('recent') ?? [];
    if (data.length > 0) {
      for (var item in data) {
        final product = Product.fromLocalJson(item);
        if (products.firstWhereOrNull((o) => o.id == product.id) == null) {
          products.add(product);
        }
      }
      // notifyListeners();
    }
    return Future.delayed(const Duration(milliseconds: 1), () => products);
  }

  void removeRecentProduct(Product? product) {
    if (product == null) {
      return;
    }
    var data = [];
    products.removeWhere((index) => index.id == product.id);
    for (var item in products) {
      data.add(item.toJson());
    }
    unawaited(storage.setItem('recent', data));
    notifyListeners();
  }
}
