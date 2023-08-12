import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import '../common/constants.dart';
import '../services/index.dart';
import 'entities/blog.dart';

class BlogWishListModel extends ChangeNotifier {
  BlogWishListModel() {
    getLocalWishlist();
  }

  List<Blog> blogs = [];

  List<Blog> getWishList() => blogs;

  final keyData = LocalStorageKey.blogWishList;

  final storage = injector<LocalStorage>();

  void addToWishlist(Blog blog) {
    blogs.add(blog);
    saveWishlist(blogs);
    notifyListeners();
  }

  void removeToWishlist(Blog blog) {
    blogs.removeWhere((item) => item.id == blog.id);
    saveWishlist(blogs);
    notifyListeners();
  }

  Future<void> saveWishlist(List<Blog> blogs) async {
    try {
      await storage.setItem(
          keyData, blogs.map((item) => item.toJson()).toList());
    } catch (err) {
      printLog(err);
    }
  }

  void getLocalWishlist() async {
    try {
      final json = storage.getItem(keyData);

      if (json != null) {
        var list = <Blog>[];
        for (var item in json) {
          list.add(Blog.fromLocalJson(item));
        }

        blogs = list;
      }
    } catch (err, trace) {
      printLog(err);
      printLog(trace);
    }
  }
}
