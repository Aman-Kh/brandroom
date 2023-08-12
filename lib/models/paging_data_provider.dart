import 'dart:collection';

import 'package:flutter/cupertino.dart';

import '../services/paging/base_page_repository.dart';

abstract class PagingDataProvider<T> extends ChangeNotifier {
  UnmodifiableListView<T>? get data =>
      _data == null ? null : UnmodifiableListView(_data!);

  bool get isLoading => _isLoading;

  bool get hasNext => _dataRepo.hasNext;

  final BasePageRepository _dataRepo;

  PagingDataProvider({required BasePageRepository dataRepo})
      : _dataRepo = dataRepo;

  List<T>? _data;

  bool _isLoading = false;
  bool _isDisposed = false;

  Future<void> getData() async {
    try {
      if (_isLoading) return;
      if (!hasNext) {
        _isLoading = true;
        _updateState();
        await Future.delayed(const Duration(milliseconds: 500), () {
          _isLoading = false;
        });
        _updateState();
        return;
      }
      _isLoading = true;
      _updateState();

      final apiData = await _dataRepo.getData();

      _data = [..._data ?? [], ...apiData as Iterable<T>? ?? []];
      await Future.delayed(const Duration(milliseconds: 300), () {
        _isLoading = false;
      });
      _updateState();
    } catch (e) {
      _isLoading = false;
    }
  }

  Future<void> refresh({bool autoGetData = true}) async {
    _dataRepo.refresh();
    _data = null;
    _updateState();
    if (autoGetData) {
      Future.delayed(const Duration(milliseconds: 300), getData);
    }
  }

  void _updateState() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
