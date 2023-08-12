import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../models/index.dart' show Product, ProductModel;
import '../product_detail_screen.dart';
import '../widgets/index.dart';

class FullSizeLayout extends StatefulWidget {
  final Product? product;
  final bool isLoading;

  const FullSizeLayout({this.product, this.isLoading = false});

  @override
  State<FullSizeLayout> createState() => _FullSizeLayoutState();
}

class _FullSizeLayoutState extends State<FullSizeLayout>
    with SingleTickerProviderStateMixin {
  Map<String, String> mapAttribute = HashMap();
  late final PageController _pageController = PageController();

  Widget _getLowerLayer({width, height}) {
    final heightVal = height ?? MediaQuery.of(context).size.height;
    final widthVal = width ?? MediaQuery.of(context).size.width;
    return Material(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            child: SizedBox(
              width: widthVal,
              height: heightVal,
              child: PageView(
                allowImplicitScrolling: true,
                controller: _pageController,
                children: [
                  Image.network(
                    widget.product?.imageFeature ?? '',
                    fit: BoxFit.fitHeight,
                  ),
                  for (var i = 1; i < (widget.product?.images.length ?? 0); i++)
                    Image.network(
                      widget.product?.images[i] ?? '',
                      fit: BoxFit.fitHeight,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.product?.images.length ?? 0,
                  effect: const ScrollingDotsEffect(
                    dotWidth: 5.0,
                    dotHeight: 5.0,
                    spacing: 15.0,
                    fixedCenter: true,
                    dotColor: Colors.black45,
                    activeDotColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                ),
                onPressed: () {
                  context.read<ProductModel>().clearProductVariations();
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => ProductDetailScreen.showMenu(
                  context, widget.product,
                  isLoading: widget.isLoading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getUpperLayer({width, height}) {
    final sizeVal = MediaQuery.of(context).size;
    final heightVal = height ?? sizeVal.height;
    final widthVal = width ?? sizeVal.width;
    const maxHeightTitleWidget = 200.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: widthVal * 0.85,
        height: heightVal * 0.55,
        margin: EdgeInsets.only(left: widthVal * 0.2),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                  color: Theme.of(context).backgroundColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10.0)),
              child: ChangeNotifierProvider(
                create: (_) => ProductModel(),
                child: LayoutBuilder(builder: (context, constraints) {
                  double? heightTitle;
                  if (constraints.maxHeight < maxHeightTitleWidget) {
                    heightTitle = constraints.maxHeight;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: heightTitle,
                        padding: const EdgeInsets.only(bottom: 5),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: ProductTitle(widget.product),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: ProductVariant(widget.product),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _getLowerLayer(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            SizedBox.expand(
              child: DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                builder:
                    (BuildContext context, ScrollController scrollController) =>
                        SingleChildScrollView(
                  controller: scrollController,
                  child: _getUpperLayer(
                    width: constraints.maxWidth,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
