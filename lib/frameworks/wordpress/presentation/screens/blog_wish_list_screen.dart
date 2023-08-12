import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../common/tools.dart';
import '../../../../generated/l10n.dart';
import '../../../../menu/index.dart';
import '../../../../models/index.dart';
import '../../../../screens/blog/index.dart';
import '../../../../screens/common/app_bar_mixin.dart';

class BlogWishListScreen extends StatefulWidget {
  const BlogWishListScreen();

  @override
  State<BlogWishListScreen> createState() => _BlogWishListScreenState();
}

class _BlogWishListScreenState extends State<BlogWishListScreen>
    with SingleTickerProviderStateMixin, AppBarMixin {
  @override
  Widget build(BuildContext context) {
    return renderScaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      routeName: RouteList.wishlist,
      body: Column(
        children: [
          AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            elevation: 0.5,
            backgroundColor: Theme.of(context).backgroundColor,
            title: Text(
              S.of(context).myWishList,
              style: Theme.of(context)
                  .textTheme
                  .headline5
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Consumer<BlogWishListModel>(
              builder: (context, model, child) {
                if (model.blogs.isEmpty) {
                  return _EmptyWishlist();
                }
                return ListView.builder(
                  itemCount: model.blogs.length,
                  itemBuilder: (context, index) {
                    final blog = model.blogs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _BlogWishListItem(
                        blog: blog,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            RouteList.detailBlog,
                            arguments: BlogDetailArguments(
                              blog: blog,
                              listBlog: model.blogs,
                            ),
                          );
                        },
                        onRemove: () {
                          model.removeToWishlist(blog);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
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
          Text(S.of(context).noFavoritesYet,
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(S.of(context).emptyWishlistSubtitle,
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: TextAlign.center),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ButtonTheme(
                    height: 45,
                    child: ElevatedButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                          MainTabControlDelegate.getInstance()
                              .changeTab(RouteList.home);
                        } else {
                          MainTabControlDelegate.getInstance()
                              .changeTab(RouteList.home);
                        }
                      },
                      child: Text(
                        S.of(context).startExploring.toUpperCase(),
                      ),
                    )),
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
                    style: TextButton.styleFrom(
                      foregroundColor: kGrey400,
                      backgroundColor: kGrey200,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteList.homeSearch);
                    },
                    child: Text(
                      S.of(context).searchForItems.toUpperCase(),
                    ),
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

class _BlogWishListItem extends StatelessWidget {
  const _BlogWishListItem({
    required this.blog,
    required this.onRemove,
    required this.onTap,
  });

  final Blog blog;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final localTheme = Theme.of(context);

    return Column(
      children: [
        Row(
          key: ValueKey(blog.id),
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
                    GestureDetector(
                      onTap: onTap,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: screenSize.width * 0.25,
                            height: screenSize.width * 0.15,
                            child: ImageTools.image(
                              fit: BoxFit.fitWidth,
                              url: blog.imageFeature,
                              size: kSize.medium,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  blog.title,
                                  style: localTheme.textTheme.caption,
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  blog.date,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5
                                      ?.copyWith(color: kGrey400, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
