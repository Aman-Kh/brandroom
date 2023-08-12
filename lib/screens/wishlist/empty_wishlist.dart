import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart' show AppModel, CartModel, Product;
import '../../services/service_config.dart';
import '../../services/services.dart';
import '../../widgets/product/dialog_add_to_cart.dart';

class EmptyWishlist extends StatelessWidget {
  final VoidCallback onShowHome;
  final VoidCallback onSearchForItem;

  const EmptyWishlist({
    required this.onShowHome,
    required this.onSearchForItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 80),
          Image.asset(
            'assets/images/empty_wishlist.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 20),
          Text(
            S.of(context).noFavoritesYet,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(S.of(context).emptyWishlistSubtitle,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ButtonTheme(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                    ),
                    onPressed: onShowHome,
                    child: Text(
                      S.of(context).startShopping.toUpperCase(),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ButtonTheme(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: kGrey400,
                      backgroundColor: kGrey200,
                    ),
                    onPressed: onSearchForItem,
                    child: Text(S.of(context).searchForItems.toUpperCase()),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class WishlistItem extends StatelessWidget {
  const WishlistItem({required this.product, this.onAddToCart, this.onRemove});

  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final localTheme = Theme.of(context);
    final currency = Provider.of<CartModel>(context).currencyCode;
    final currencyRate = Provider.of<AppModel>(context).currencyRate;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                RouteList.productDetail,
                arguments: product,
              );
            },
            child: Row(
              key: ValueKey(product.id),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: onRemove,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              width: constraints.maxWidth * 0.25,
                              height: constraints.maxWidth * 0.3,
                              child: ImageTools.image(
                                  url: product.imageFeature,
                                  size: kSize.medium),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name ?? '',
                                    style: localTheme.textTheme.caption,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                      PriceTools.getPriceProduct(
                                          product, currencyRate, currency)!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: kGrey400, fontSize: 14)),
                                  const SizedBox(height: 10),
                                  if (Services()
                                          .widget
                                          .enableShoppingCart(product) &&
                                      !ServerConfig().isListingType)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            localTheme.primaryColor,
                                      ),
                                      onPressed: () => DialogAddToCart.show(
                                          context,
                                          product: product),
                                      child: (product.isPurchased &&
                                              product.isDownloadable!)
                                          ? Text(S
                                              .of(context)
                                              .download
                                              .toUpperCase())
                                          : Text(S
                                              .of(context)
                                              .addToCart
                                              .toUpperCase()),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          const Divider(color: kGrey200, height: 1),
          const SizedBox(height: 10.0),
        ]);
      },
    );
  }
}
