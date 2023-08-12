import 'package:flutter/material.dart';

import '../../services/index.dart';
import '../../widgets/common/webview.dart';
import '../base_screen.dart';

class PaymentWebview extends StatefulWidget {
  final String? url;
  final Function? onFinish;
  final Function? onClose;
  final String? token;

  const PaymentWebview({this.onFinish, this.onClose, this.url, this.token});

  @override
  State<StatefulWidget> createState() {
    return PaymentWebviewState();
  }
}

class PaymentWebviewState extends BaseScreen<PaymentWebview> with WebviewMixin {
  int selectedIndex = 1;

  void handleUrlChanged(String url) {
    if (url.contains('/order-received/')) {
      final items = url.split('/order-received/');
      if (items.length > 1) {
        final number = items[1].split('/')[0];
        widget.onFinish!(number);
        Navigator.of(context).pop();
      }
    }
    if (url.contains('checkout/success')) {
      widget.onFinish!('0');
      Navigator.of(context).pop();
    }

    // shopify url final checkout
    if (url.contains('thank_you')) {
      widget.onFinish!('0');
      Navigator.of(context).pop();
    }

    if (url.contains('/member-login/')) {
      widget.onFinish!('0');
      Navigator.of(context).pop();
    }

    /// BigCommerce.
    if (url.contains('/checkout/order-confirmation')) {
      Navigator.of(context).pop();
    }

    /// Prestashop
    if (url.contains('/order-confirmation')) {
      var uri = Uri.parse(url);
      widget.onFinish?.call((uri.queryParameters['id_order'] ?? 0).toString());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var checkoutMap = <dynamic, dynamic>{
      'url': '',
      'headers': <String, String>{}
    };

    if (widget.url != null) {
      checkoutMap['url'] = widget.url;
    } else {
      final paymentInfo = Services().widget.getPaymentUrl(context)!;
      checkoutMap['url'] = paymentInfo['url'];
      if (paymentInfo['headers'] != null) {
        checkoutMap['headers'] =
            Map<String, String>.from(paymentInfo['headers']);
      }
    }
    if (widget.token != null) {
      checkoutMap['headers']['X-Shopify-Customer-Access-Token'] = widget.token;
    }

    // // Enable webview payment plugin
    /// make sure to import 'payment_webview_plugin.dart';
    // return PaymentWebviewPlugin(
    //   url: checkoutMap['url'],
    //   headers: checkoutMap['headers'],
    //   onClose: widget.onClose,
    //   onFinish: widget.onFinish,
    // );

    return WebView(
      url: checkoutMap['url'] ?? '',
      headers: checkoutMap['headers'],
      onPageFinished: handleUrlChanged,
      onClosed: () {
        widget.onFinish?.call(null);
        widget.onClose?.call();
      },
    );
  }
}
