import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart' show S;
import '../../models/paging_data_provider.dart';
import 'loading_widget.dart';
import 'refresh_scroll_physics.dart';

typedef PagingWidgetBuilder<T> = Widget Function(
    BuildContext, T entity, int index);

class PagingList<M extends PagingDataProvider, T> extends StatefulWidget {
  final PagingWidgetBuilder<T> itemBuilder;
  final Widget? loadingWidget;
  final int? lengthLoadingWidget;
  final Function? onRefresh;
  final Widget? header;
  final bool autoInitData;

  const PagingList({
    required this.itemBuilder,
    this.loadingWidget,
    this.lengthLoadingWidget,
    this.onRefresh,
    this.header,
    this.autoInitData = true,
  });

  @override
  State<PagingList<M, T>> createState() => _PagingListState();
}

class _PagingListState<M extends PagingDataProvider, T>
    extends State<PagingList<M, T>> {
  Widget get loadingWidget => widget.loadingWidget ?? const LoadingWidget();

  M get model => Provider.of<M>(context, listen: false);

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        if (widget.autoInitData) {
          Provider.of<M>(context, listen: false).getData();
        }
        scrollController.addListener(() {
          if (scrollController.position.extentBefore > 200 &&
              scrollController.position.extentAfter < 500) {
            model.getData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<M>(
      builder: (context, model, _) {
        return Scrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            physics: const RefreshScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await model.refresh();
                  widget.onRefresh?.call();
                },
              ),
              if (widget.header != null)
                SliverToBoxAdapter(
                  child: widget.header,
                ),
              model.data == null
                  ? _buildInitBody()
                  : (model.data?.isEmpty ?? false)
                      ? _buildEmptyData(context)
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index != model.data!.length) {
                                return widget.itemBuilder(
                                  context,
                                  model.data![index],
                                  index,
                                );
                              }
                              var showLoadingWidget = false;
                              if (scrollController.hasClients) {
                                showLoadingWidget = model.isLoading &&
                                    scrollController.position.extentBefore >
                                        200;
                              }

                              return AnimatedSwitcher(
                                transitionBuilder: (child, animation) {
                                  final offsetAnimation = Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: const Offset(0.0, 0.0),
                                  ).animate(animation);
                                  return SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  );
                                },
                                duration: const Duration(milliseconds: 300),
                                child: showLoadingWidget
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: loadingWidget,
                                      )
                                    : const SizedBox(),
                              );
                            },
                            childCount: model.data!.length + 1,
                          ),
                        ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitBody() {
    return widget.loadingWidget != null
        ? SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => loadingWidget,
              childCount: widget.lengthLoadingWidget ?? 1,
            ),
          )
        : const SliverFillRemaining(
            child: LoadingWidget(),
          );
  }

  Widget _buildEmptyData(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Text(S.of(context).noData),
      ),
    );
  }
}
