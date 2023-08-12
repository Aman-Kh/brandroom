import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools/flash.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart'
    show AppModel, Product, ProductWishListModel, UserModel;
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../base_screen.dart';
import '../common/app_bar_mixin.dart';
import 'widgets/image_galery.dart';

export 'themes/full_size_image_type.dart';
export 'themes/half_size_image_type.dart';
export 'themes/simple_type.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? id;

  const ProductDetailScreen({this.product, this.id});

  static void showMenu(BuildContext context, Product? product,
      {bool isLoading = false}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext modalContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (Services().widget.enableShoppingCart(null) &&
                !ServerConfig().isListingType)
              ListTile(
                title: Text(
                  S.of(modalContext).myCart,
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.of(modalContext).pop();
                  FluxNavigate.pushNamed(
                    RouteList.cart,
                    forceRootNavigator: true,
                  );
                },
              ),
            ListTile(
              title: Text(
                S.of(modalContext).showGallery,
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.of(modalContext).pop();
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return ImageGalery(images: product?.images, index: 0);
                  },
                );
              },
            ),
            if (!isLoading && product != null)
              ListTile(
                title: Text(
                  S.of(modalContext).saveToWishList,
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Provider.of<ProductWishListModel>(context, listen: false)
                      .addToWishlist(product);
                  Navigator.of(modalContext).pop();
                },
              ),

            /// Share feature not supported in Strapi.
            if (!ServerConfig().isStrapi && !ServerConfig().isNotion)
              ListTile(
                title:
                    Text(S.of(modalContext).share, textAlign: TextAlign.center),
                onTap: () {
                  unawaited(
                    FlashHelper.message(
                      context,
                      message: S.of(context).generatingLink,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  Services().firebase.shareDynamicLinkProduct(
                        itemUrl: product?.permalink,
                      );
                },
              ),
            Container(
              height: 1,
              decoration: const BoxDecoration(color: kGrey200),
            ),
            ListTile(
              title: Text(
                S.of(modalContext).cancel,
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.of(modalContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  BaseScreen<ProductDetailScreen> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends BaseScreen<ProductDetailScreen>
    with AppBarMixin {
  Product? product;
  bool isLoading = true;
  bool _isChecking = Services().widget.enableMembershipUltimate;
  String? _checkingErrorMessage;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {}

  @override
  void initState() {
    WidgetsBinding.instance.endOfFrame.then((_) async {
      if (mounted) {
        if (widget.product is Product) {
          /// Get more detail info from product
          setState(() {
            product = widget.product;
          });
          final check = await _checkProductPermission(widget.product);
          if (check) {
            product =
                await Services().widget.getProductDetail(context, product);
          }
        } else {
          /// Request the product by Product ID which is using for web param
          product = await Services().api.getProduct(widget.id);
          await _checkProductPermission(product);
        }
        isLoading = false;
        if (mounted) {
          setState(() {});
        }
      }
    });
    super.initState();
  }

  Future<bool> _checkProductPermission(Product? p) async {
    if (Services().widget.enableMembershipUltimate &&
        (p?.isRestricted ?? false)) {
      setState(() {
        _isChecking = true;
      });
      final cookie =
          Provider.of<UserModel>(context, listen: false).user?.cookie;
      try {
        final check =
            await Services().api.checkProductPermission(p?.id ?? '0', cookie);
        setState(() {
          _isChecking = false;
        });
        return check == true;
      } catch (e) {
        setState(() {
          _isChecking = false;
          _checkingErrorMessage = e.toString();
        });
        return false;
      }
    } else {
      setState(() {
        _isChecking = false;
      });
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (product?.id == null) {
      return Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          body: Center(
            child: isLoading
                ? kLoadingWidget(context)
                : Text(S.of(context).notFound),
          ));
    }

    if (_isChecking || (_checkingErrorMessage?.isNotEmpty ?? false)) {
      return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        body: Center(
            child: (_checkingErrorMessage?.isNotEmpty ?? false)
                ? Text(
                    _checkingErrorMessage!,
                    style: TextStyle(color: Theme.of(context).errorColor),
                  )
                : kLoadingWidget(context)),
      );
    }
    return _renderContent();
  }

  Widget _renderContent() {
    var layoutType = Provider.of<AppModel>(context).productDetailLayout;

    var layout = Services().widget.renderDetailScreen(
          context,
          product!,
          layoutType,
          isLoading,
        );

    if (showAppBar(RouteList.productDetail)) {
      layout = Scaffold(
        appBar: appBarWidget,
        body: layout,
      );
    }

    return GestureDetector(
      onTap: () {
        var currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: layout,
    );
  }
}
