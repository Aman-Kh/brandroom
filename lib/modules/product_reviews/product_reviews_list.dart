import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../common/config.dart';
import '../../common/tools/image_tools.dart';
import '../../generated/l10n.dart';
import '../../screens/detail/widgets/index.dart';
import '../../widgets/common/expansion_info.dart';
import '../../widgets/common/start_rating.dart';
import 'product_reviews_model.dart';

class ProductReviewsList extends StatelessWidget {
  const ProductReviewsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ProductReviewsModel>(context);
    return ExpansionInfo(
      title: S.of(context).reviews,
      children: [
        if (model.state == LoadState.loading) kLoadingWidget(context),
        if (model.state != LoadState.loading) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(0.0),
            itemCount: model.reviews.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const CircleAvatar(
                  //   radius: 20,
                  //   backgroundColor: Colors.grey,
                  // ),
                  // const SizedBox(
                  //   width: 10.0,
                  // ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.reviews[index].name ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .caption!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 2.0,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                              timeago.format(model.reviews[index].createdAt),
                              style: Theme.of(context).textTheme.bodyText1!,
                            )),
                            if (kAdvanceConfig.enableRating)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: SmoothStarRating(
                                  label: const Text(''),
                                  allowHalfRating: true,
                                  starCount: 5,
                                  rating: model.reviews[index].rating,
                                  size: 14.0,
                                  color: Theme.of(context).primaryColor,
                                  borderColor: Theme.of(context).primaryColor,
                                  spacing: 0.0,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          model.reviews[index].review ?? '',
                          style: Theme.of(context).textTheme.bodyText1!,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        if (model.reviews[index].images.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                model.reviews[index].images.length,
                                (i) => InkWell(
                                  onTap: () {
                                    showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ImageGalery(
                                              images:
                                                  model.reviews[index].images,
                                              index: i);
                                        });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: ImageTools.image(
                                        url: model.reviews[index].images[i],
                                        fit: BoxFit.cover,
                                        height: 120.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          if (model.state == LoadState.loadMore)
            const CircularProgressIndicator(),
          if (model.state == LoadState.loaded)
            Text(
              S.of(context).more,
              style: Theme.of(context)
                  .textTheme
                  .button!
                  .copyWith(color: Theme.of(context).primaryColor),
            ),
        ],
      ],
    );
  }
}
