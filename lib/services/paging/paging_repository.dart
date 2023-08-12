import 'dart:async';

import '../base_services.dart';
import 'base_page_repository.dart';

/// * [T] is type of the data
abstract class PagingRepository<T> extends BasePageRepository<T?> {
  Future<PagingResponse<T>>? Function(dynamic) get requestApi;

  @override
  Future<List<T?>?> getData() async {
    if (!hasNext) return <T>[];

    final response = await requestApi(cursor)!;

    // ignore: unnecessary_null_comparison
    if (response == null) return <T>[];

    var data = response.data;

    updateCursor(response.cursor);

    if (data?.isEmpty ?? true) {
      hasNext = false;
      return <T>[];
    }

    return data;
  }
}
