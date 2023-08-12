import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import 'product_reviews_list.dart';
import 'product_reviews_model.dart';

class ProductReviewsIndex extends StatelessWidget {
  final String productId;
  const ProductReviewsIndex({Key? key, required this.productId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kProductDetail.enableReview) {
      return const SizedBox();
    }
    return ChangeNotifierProvider<ProductReviewsModel>(
        create: (_) => ProductReviewsModel(productId),
        child: const ProductReviewsList());
  }
}
