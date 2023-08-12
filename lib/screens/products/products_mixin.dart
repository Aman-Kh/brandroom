import 'dart:async';

import 'package:provider/provider.dart';

import '../../common/tools/flash.dart';
import '../../generated/l10n.dart';
import '../../models/product_model.dart';
import '../../modules/firebase/dynamic_link_service.dart';
import '../../services/services.dart';

mixin ProductsMixin {
  Future<void> shareProductsLink(context) async {
    unawaited(
      FlashHelper.message(
        context,
        message: S.of(context).generatingLink,
        duration: const Duration(seconds: 2),
      ),
    );
    var productModel = Provider.of<ProductModel>(context, listen: false);
    var currentCategoryId = productModel.categoryId;
    var currentTagId = productModel.tagId;
    var url;
    if (currentCategoryId.isValid) {
      url = await DynamicLinkService()
          .generateProductCategoryUrl(currentCategoryId);
    } else if (currentTagId != null) {
      url = await DynamicLinkService().generateProductTagUrl(currentTagId);
    } else {
      await FlashHelper.errorMessage(
        context,
        message: S.of(context).failedToGenerateLink,
      );
      return;
    }
    Services().firebase.shareDynamicLinkProduct(
          itemUrl: url,
        );
  }
}

extension on String? {
  bool get isValid => this != null && this != '-1';
}
