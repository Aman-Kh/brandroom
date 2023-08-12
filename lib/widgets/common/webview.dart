import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as flutter;
import 'package:webview_flutter/webview_flutter.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/entities/user.dart';
import '../../models/user_model.dart';
import '../../screens/common/app_bar_mixin.dart';
import '../html/index.dart';
import 'webview_inapp.dart';

mixin WebviewMixin {
  Future<NavigationDecision> getNavigationDelegate(
      NavigationRequest request) async {
    final url = request.url;
    printLog('[WebView] navigate to $url');

    /// open the normal web link
    var isHttp = 'http';
    if (url.startsWith(isHttp)) {
      return NavigationDecision.navigate;
    }

    if (url.startsWith('intent://') && url.contains('#Intent;scheme=')) {
      final intentInfo = url.substring(url.indexOf('#Intent;scheme=') + 8);
      final scheme = intentInfo.substring(
          intentInfo.indexOf('scheme=') + 7, intentInfo.indexOf(';'));
      final newUrl = url.replaceFirst('intent://', '$scheme://');
      try {
        await Tools.launchURL(
          newUrl,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {
        await Tools.launchURL(
          newUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    }

    /// open external app link
    await Tools.launchURL(
      url,
      mode: LaunchMode.externalNonBrowserApplication,
    );

    if (!request.isForMainFrame) {
      return NavigationDecision.prevent;
    }

    return NavigationDecision.prevent;
  }
}

class WebView extends StatefulWidget {
  final String? url;
  final String? title;
  final AppBar? appBar;
  final bool enableForward;
  final bool enableBackward;
  final bool enableClose;
  final PageFinishedCallback? onPageFinished;
  final Function? onClosed;
  final bool auth;
  final String script;
  final Map<String, String>? headers;
  final String? routeName;

  const WebView({
    Key? key,
    this.title,
    required this.url,
    this.appBar,
    this.onPageFinished,
    this.onClosed,
    this.auth = false,
    this.script = '',
    this.headers,
    this.enableForward = true,
    this.enableBackward = true,
    this.enableClose = true,
    this.routeName,
  }) : super(key: key);

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> with WebviewMixin, AppBarMixin {
  int selectedIndex = 1;
  bool isLoading = true;
  String html = '';

  User? get user => Provider.of<UserModel>(context, listen: true).user;

  flutter.WebViewController? _controller;

  final Set<foundation.Factory<OneSequenceGestureRecognizer>>
      gestureRecognizers = {
    const foundation.Factory(EagerGestureRecognizer.new)
  };

  @override
  void initState() {
    if (isMacOS || isWindow) {
      httpGet(widget.url.toString().toUri()!).then((response) {
        setState(() {
          html = response.body;
        });
      });
    }

    if (isAndroid) flutter.WebView.platform = flutter.SurfaceAndroidWebView();

    super.initState();
  }

  @override
  void dispose() {
    if (kAdvanceConfig.alwaysClearWebViewCache) {
      _controller?.clearCache();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var url = widget.url ?? '';

    if (kAdvanceConfig.alwaysClearWebViewCache) {
      url =
          '$url${url.paramSymbol}dummy=${DateTime.now().millisecondsSinceEpoch}';
    }

    /// override WebView URL to include Token
    if (widget.auth && (user?.cookie?.isNotEmpty ?? false)) {
      var base64Str = EncodeUtils.encodeCookie(user!.cookie!);
      url = '$url${url.paramSymbol}cookie=$base64Str';
    }

    /// Loading if the Auth cookie is active but URL not changed
    if (url.isEmpty || (widget.auth && url == widget.url!)) {
      return Center(child: kLoadingWidget(context));
    }
    return renderScaffold(
        routeName: widget.routeName ?? RouteList.webview,
        body: Builder(builder: (context) {
          if (isMacOS || isWindow) {
            return Scaffold(
              appBar: widget.appBar ??
                  AppBar(
                    backgroundColor: Theme.of(context).backgroundColor,
                    elevation: 0.0,
                    centerTitle: true,
                    title: Text(
                      widget.title ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .headline6!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    actions: [
                      if (widget.enableClose)
                        IconButton(
                          onPressed: () async {
                            widget.onClosed?.call();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      const SizedBox(width: 10),
                    ],
                    leading: Builder(
                      builder: (buildContext) {
                        return Row(
                          children: [
                            if (widget.enableBackward)
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_back_ios, size: 20),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            if (widget.enableForward)
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 20),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              body: SingleChildScrollView(
                child: HtmlWidget(html),
              ),
            );
          }

          /// is Mobile or Web
          if (!kIsWeb && kAdvanceConfig.inAppWebView) {
            return WebViewInApp(
              url: url,
              title: widget.title,
              script: widget.script.isEmptyOrNull
                  ? kAdvanceConfig.webViewScript
                  : widget.script,
              headers: widget.headers,
              enableForward: widget.enableForward,
              enableBackward: widget.enableBackward,
              onClosed: widget.onClosed,
              onUrlChanged: (String? url) {
                if (widget.onPageFinished != null) {
                  widget.onPageFinished!(url ?? '');
                }
              },
            );
          }

          return Scaffold(
            appBar: widget.appBar ??
                AppBar(
                  backgroundColor: Theme.of(context).backgroundColor,
                  elevation: 0.0,
                  centerTitle: true,
                  title: Text(
                    widget.title ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .headline6!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  leadingWidth: 150,
                  actions: [
                    if (widget.enableClose)
                      IconButton(
                        onPressed: () async {
                          widget.onClosed?.call();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    const SizedBox(width: 10),
                  ],
                  leading: Builder(
                    builder: (buildContext) {
                      return Row(
                        children: [
                          if (widget.enableBackward)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, size: 20),
                              onPressed: () async {
                                var value =
                                    await _controller?.canGoBack() ?? false;
                                if (value) {
                                  await _controller?.goBack();
                                } else if (!widget.enableClose &&
                                    Navigator.canPop(context)) {
                                  widget.onClosed?.call();
                                  Navigator.of(context).pop();
                                } else {
                                  Tools.showSnackBar(
                                      ScaffoldMessenger.of(buildContext),
                                      S.of(context).noBackHistoryItem);
                                }
                              },
                            ),
                          if (widget.enableForward)
                            IconButton(
                              onPressed: () async {
                                if (await _controller?.canGoForward() ??
                                    false) {
                                  await _controller?.goForward();
                                } else {
                                  Tools.showSnackBar(
                                      ScaffoldMessenger.of(buildContext),
                                      S.of(context).noForwardHistoryItem);
                                }
                              },
                              icon:
                                  const Icon(Icons.arrow_forward_ios, size: 20),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            body: IndexedStack(
              index: selectedIndex,
              children: [
                Builder(builder: (BuildContext context) {
                  return flutter.WebView(
                    initialUrl: url,
                    javascriptMode: flutter.JavascriptMode.unrestricted,
                    onProgress: (progress) {
                      if (progress == 100) {
                        setState(() {
                          selectedIndex = 0;
                        });
                      }
                    },
                    onPageFinished: (_) {
                      /// Demo the Javascript Style override
                      // var script = "document.querySelector('div.wd-toolbar').style.display = 'none'";

                      var script = widget.script.isEmptyOrNull
                          ? kAdvanceConfig.webViewScript
                          : widget.script;
                      if (script.isNotEmpty) {
                        _controller?.runJavascript(script);
                      }

                      /// Call back when finish loading
                      if (widget.onPageFinished != null) {
                        widget.onPageFinished!(_);
                      }
                    },
                    navigationDelegate: getNavigationDelegate,
                    onWebViewCreated: (webViewController) {
                      _controller = webViewController;
                    },
                    gestureRecognizers: gestureRecognizers,
                    gestureNavigationEnabled: true,
                  );
                }),
                Center(
                  child: kLoadingWidget(context),
                )
              ],
            ),
          );
        }));
  }
}
