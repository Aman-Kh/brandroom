import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/index.dart' show Product, ProductModel, UserModel;
import '../../../services/index.dart';
import '../../../widgets/product/product_bottom_sheet.dart';
import '../../../widgets/product/widgets/heart_button.dart';
import '../../chat/vendor_chat.dart';
import '../product_detail_screen.dart';
import '../widgets/index.dart';
import '../widgets/product_image_slider.dart';

class SimpleLayout extends StatefulWidget {
  final Product product;
  final bool isLoading;

  const SimpleLayout({required this.product, this.isLoading = false});

  @override
  // ignore: no_logic_in_create_state
  State<SimpleLayout> createState() => _SimpleLayoutState(product: product);
}

class _SimpleLayoutState extends State<SimpleLayout>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  int _selectIndex = 0;

  late Product product;

  _SimpleLayoutState({required this.product});

  Map<String, String> mapAttribute = HashMap();
  var _hideController;
  var top = 0.0;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(SimpleLayout oldWidget) {
    if (oldWidget.product.type != widget.product.type) {
      setState(() {
        product = widget.product;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  /// Render product default: booking, group, variant, simple, booking
  Widget renderProductInfo() {
    var body;

    if (widget.isLoading == true) {
      body = kLoadingWidget(context);
    } else {
      switch (product.type) {
        case 'appointment':
          return Services().getBookingLayout(product: product);
        case 'booking':
          body = ListingBooking(product);
          break;
        case 'grouped':
          body = GroupedProduct(product);
          break;
        default:
          body = ProductVariant(product);
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthHeight = size.height;

    final userModel = Provider.of<UserModel>(context, listen: false);
    return Container(
      color: Theme.of(context).backgroundColor,
      child: SafeArea(
        bottom: false,
        top: kProductDetail.safeArea,
        child: ChangeNotifierProvider(
          create: (_) => ProductModel(),
          child: Stack(
            children: <Widget>[
              Scaffold(
                floatingActionButton: (!ServerConfig().isVendorType() ||
                        !kConfigChat['EnableSmartChat'])
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: VendorChat(
                          user: userModel.user,
                          store: product.store,
                        ),
                      ),
                backgroundColor: Theme.of(context).backgroundColor,
                body: CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    SliverAppBar(
                      // systemOverlayStyle: SystemUiOverlayStyle.light,
                      backgroundColor: Theme.of(context).backgroundColor,
                      elevation: 1.0,
                      expandedHeight:
                          kIsWeb ? 0 : widthHeight * kProductDetail.height,
                      pinned: true,
                      floating: false,
                      leading: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .primaryColorLight
                              .withOpacity(0.7),
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              context
                                  .read<ProductModel>()
                                  .clearProductVariations();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                      actions: <Widget>[
                        if (widget.isLoading != true)
                          HeartButton(
                            product: product,
                            size: 20.0,
                            color: Theme.of(context).primaryColor,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .primaryColorLight
                                .withOpacity(0.7),
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, size: 19),
                              color: Theme.of(context).primaryColor,
                              onPressed: () => ProductDetailScreen.showMenu(
                                context,
                                widget.product,
                                isLoading: widget.isLoading,
                              ),
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: kIsWeb
                          ? const SizedBox()
                          : ProductImageSlider(
                              product: product,
                              onChange: (index) => setState(() {
                                _selectIndex = index;
                              }),
                            ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate(
                        <Widget>[
                          const SizedBox(height: 2),
                          if (kIsWeb)
                            ProductGallery(
                              product: widget.product,
                              selectIndex: _selectIndex,
                            ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 4.0,
                              left: 15,
                              right: 15,
                            ),
                            child: product.type == 'grouped'
                                ? const SizedBox()
                                : ProductTitle(product),
                          ),
                        ],
                      ),
                    ),
                    if (Services().widget.enableShoppingCart(
                        product.copyWith(isRestricted: false)))
                      renderProductInfo(),
                    if (!Services().widget.enableShoppingCart(
                            product.copyWith(isRestricted: false)) &&
                        product.shortDescription != null &&
                        product.shortDescription!.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: ProductShortDescription(product),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          // horizontal: 15.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15.0,
                              ),
                              child: Column(
                                children: [
                                  Services().widget.renderVendorInfo(product),
                                  ProductDescription(product),
                                  if (kProductDetail.showProductCategories)
                                    ProductDetailCategories(product),
                                  if (kProductDetail.showProductTags)
                                    ProductTag(product),
                                  Services()
                                      .widget
                                      .productReviewWidget(product.id!),
                                ],
                              ),
                            ),
                            if (kProductDetail
                                    .showRelatedProductFromSameStore &&
                                product.store?.id != null)
                              RelatedProductFromSameStore(product),
                            if (kProductDetail.showRelatedProduct)
                              RelatedProduct(product),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (Services().widget.enableShoppingCart(
                      product.copyWith(isRestricted: false)) &&
                  kAdvanceConfig.showBottomCornerCart)
                Align(
                  alignment: Alignment.bottomRight,
                  child: ExpandingBottomSheet(
                    hideController: _hideController,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
