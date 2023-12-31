import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/constants.dart';
import '../../../common/tools/flash.dart';
import '../../../generated/l10n.dart';
import '../../../models/app_model.dart';
import '../../../models/cart/cart_base.dart';
import '../../../models/tera_wallet/index.dart';
import '../../../widgets/common/loading_body.dart';
import '../../../widgets/html/index.dart';
import '../helpers/currency_text_input_formatter.dart';
import '../helpers/wallet_helpers.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  NumberFormat get _numberFormat => WalletHelpers.numberFormat;

  WalletModel get _walletModel => context.read<WalletModel>();

  final _textController = TextEditingController();
  late final TextInputFormatter _textFormat;

  @override
  void initState() {
    super.initState();
    _textFormat = CurrencyTextInputFormatter(
      decimalDigits: 0,
      name: _numberFormat.currencyName,
      locale: _numberFormat.locale,
      symbol: _numberFormat.currencySymbol,
    );
  }

  @override
  void dispose() {
    FlashHelper.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlashHelper.init(context);

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0.0,
        title: Text(
          S.of(context).topUp,
          style: Theme.of(context)
              .textTheme
              .headline6!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: LoadingBody(
        isLoading:
            context.select<WalletModel, bool>((value) => value.isLoading),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<WalletModel>(
            builder: (context, value, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (value.errMessage != null)
                    HtmlWidget(
                      value.errMessage!,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodyText2!
                          .copyWith(
                            color: Theme.of(context).colorScheme.error,
                            height: 1.5,
                          )
                          .apply(
                            fontSizeFactor: 1.1,
                          ),
                    ),
                  Expanded(
                    child: Center(
                      child: TextField(
                        style: Theme.of(context).textTheme.headline4,
                        textAlign: TextAlign.center,
                        controller: _textController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        inputFormatters: [_textFormat],
                        autofocus: true,
                        maxLength: 11 + _numberFormat.currencySymbol.length,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: ChangeNotifierProvider.value(
                      value: _textController,
                      child: Consumer<TextEditingController>(
                        builder: (context, controller, child) {
                          final onTap = _isValidAmount(controller.text)
                              ? () => _onTapTopUp(controller.text)
                              : null;

                          return Column(
                            children: [
                              if (!_isValidAmount(controller.text))
                                const Text('أقل مبلغ للطلب هو 10,000 ليرة'),
                              ElevatedButton(
                                onPressed: onTap,
                                child: child!,
                              ),
                            ],
                          );
                        },
                        child: Text(
                          S.of(context).topUp.toUpperCase(),
                          style: Theme.of(context).textTheme.button!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isValidAmount(String text) =>
      text.isNotEmpty && WalletHelpers.parseSymbolNumberToNumber(text) >= 10000;

  double getPriceValueByCurrency(
      price, String currency, Map<String, dynamic> rates) {
    final currencyVal = currency.toUpperCase();
    double rate = rates[currencyVal] ?? 1.0;

    if (price == '' || price == null) {
      return 0;
    }
    return double.parse(price.toString()) * rate;
  }

  void _onTapTopUp(String priceText) async {
    final currency = Provider.of<AppModel>(context, listen: false).currency;
    final currencyRate =
        Provider.of<AppModel>(context, listen: false).currencyRate;

    final price = WalletHelpers.parseSymbolNumberToNumber(priceText) /
        getPriceValueByCurrency(1, currency!, currencyRate);
    final product = await _walletModel.topUp(price.toInt());
    if (product != null) {
      final cartModel = Provider.of<CartModel>(context, listen: false);
      if (cartModel.item.keys.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S.of(context).areYouSure),
            content: Text(S.of(context).confirmClearCartWhenTopUp),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).no),
              ),
              TextButton(
                onPressed: () {
                  cartModel.clearCart();
                  cartModel.addWalletProductToCart(
                      product: product, quantity: 1);
                  Navigator.of(context).pushReplacementNamed(RouteList.cart);
                },
                child: Text(S.of(context).yes),
              ),
            ],
          ),
        );
      } else {
        cartModel.clearCart();
        cartModel.addWalletProductToCart(product: product, quantity: 1);
        await Navigator.of(context).pushReplacementNamed(RouteList.cart);
      }
    }
  }
}
