import 'package:flutter/material.dart';
import '../../models/entities/index.dart';
import '../../services/index.dart';

enum LoadState { loading, loaded, loadMore, noData, noMore }

class ProductReviewsModel extends ChangeNotifier {
  bool _mounted = false;
  bool get mounted => _mounted;
  final _services = Services();
  final _perPage = 10;
  int _page = 1;
  final List<Review> _reviews = [];
  List<Review> get reviews => _reviews;
  LoadState _state = LoadState.loaded;
  LoadState get state => _state;

  final String _productId;

  ProductReviewsModel(this._productId) {
    getComments();
  }

  void _updateState(state) {
    if (!mounted) {
      _state = state;
      notifyListeners();
    }
  }

  Future<void> getComments() async {
    if (_state != LoadState.loaded) {
      return;
    }
    _page = 1;
    _updateState(LoadState.loading);
    final list = await _services.api
        .getReviews(_productId, page: _page, perPage: _perPage);
    if (list == null || list.isEmpty) {
      _updateState(LoadState.noData);
      return;
    }
    _reviews.addAll(list);
    if (list.length < _perPage) {
      _updateState(LoadState.noMore);
      return;
    }
    _updateState(LoadState.loaded);
  }

  Future<void> loadComments() async {
    if (_state != LoadState.loaded) {
      return;
    }
    _page++;
    _updateState(LoadState.loadMore);
    final list = await _services.api
        .getReviews(_productId, page: _page, perPage: _perPage);
    if (list == null || list.isEmpty) {
      _updateState(LoadState.noData);
      return;
    }
    _reviews.addAll(list);
    if (list.length < _perPage) {
      _updateState(LoadState.noMore);
      return;
    }
    _updateState(LoadState.loaded);
  }

  @override
  void dispose() {
    super.dispose();
    _mounted = true;
  }
}
