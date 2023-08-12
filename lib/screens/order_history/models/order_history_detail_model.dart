import 'package:flutter/cupertino.dart';

import '../../../models/entities/index.dart';
import '../../../services/index.dart';

class OrderHistoryDetailModel extends ChangeNotifier {
  Order _order;
  List<OrderNote>? _listOrderNote;
  final User user;
  final _services = Services();

  Order get order => _order;

  List<OrderNote>? get listOrderNote => _listOrderNote;

  OrderHistoryDetailModel({
    required Order order,
    required this.user,
  }) : _order = order {
    fetchImageOfOrder();
  }

  Future<void> fetchImageOfOrder() async {
    await fetchProductItems();
    await fetchImage();
  }

  Future<void> fetchProductItems() async {
    final listProductItem =
        await _services.api.getListProductItemByOrderId(order.id ?? '');
    if (listProductItem.isNotEmpty) {
      _order.lineItems = listProductItem;
      notifyListeners();
    }
  }

  Future<void> fetchImage() async {
    final firstProduct = _order.lineItems.first;
    if (firstProduct.featuredImage?.isEmpty ?? true) {
      final listImage =
          await _services.api.getImagesByProductId(firstProduct.productId!);
      if (listImage.isNotEmpty) {
        firstProduct.featuredImage = listImage.first;
      }
      notifyListeners();
    }
  }

  Future<void> cancelOrder() async {
    if (order.status!.isCancelled) return;
    final newOrder =
        await _services.api.cancelOrder(order: order, userCookie: user.cookie);
    if (newOrder != null) {
      _order = newOrder;
      await fetchImageOfOrder();
      notifyListeners();
    }
  }

  Future<void> createRefund() async {
    if (order.status == OrderStatus.refunded) return;
    await _services.api
        .updateOrder(order.id, status: 'refund-req', token: user.cookie)!
        .then((onValue) {
      _order = onValue;
      notifyListeners();
    });
  }

  void getOrderNote() async {
    _listOrderNote =
        await _services.api.getOrderNote(userId: user.id, orderId: order.id);
    notifyListeners();
  }

// void getTracking() {
//   _services.api.getTracking()?.then((onValue) {
//     for (var track in onValue.trackings) {
//       if (track.orderId == order.number) {
//         tracking = track.trackingNumber;
//         notifyListeners();
//         return;
//       }
//     }
//   });
// }
}
