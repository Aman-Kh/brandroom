import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../../../../generated/l10n.dart';
import '../../../common/tools/tools.dart';
import '../../../routes/flux_navigate.dart';
import '../../../screens/home/privacy_term_screen.dart';
import '../../../widgets/common/common_safe_area.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/index.dart';
import '../../common/config.dart';
import '../../common/tools.dart';
import '../../screens/common/select_country_mixin.dart';
import 'sms_model.dart';
import 'widgets/custom_keyboard.dart';

class SMSInputWidget extends StatefulWidget {
  final Function onCallBack;
  const SMSInputWidget({Key? key, required this.onCallBack}) : super(key: key);

  @override
  State<SMSInputWidget> createState() => _SMSInputWidgetState();
}

class _SMSInputWidgetState extends State<SMSInputWidget>
    with SelectCountryMixin {
  // bool _isPhoneValid(phoneNumber) {
  //   if (phoneNumber.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text(S.of(context).phoneEmpty),
  //       duration: const Duration(seconds: 1),
  //     ));
  //     return false;
  //   }
  //   const pattern = r'(^(?:[+0])?[0-9]{10,13}$)';
  //   final regExp = RegExp(pattern);
  //   if (!regExp.hasMatch(phoneNumber)) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text(S.of(context).invalidPhoneNumber),
  //       duration: const Duration(seconds: 3),
  //     ));
  //     return false;
  //   }
  //   return true;
  // }

  void _onUpdate(String val) {
    final model = Provider.of<SMSModel>(context, listen: false);
    model.updatePhoneNumber(val);
  }

  SMSModel get model => context.read<SMSModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      model.updateCountryCode(CountryCode(
        code: LoginSMSConstants.countryCodeDefault,
        dialCode: LoginSMSConstants.dialCodeDefault,
        name: LoginSMSConstants.nameDefault,
        flagUri: elements
            .where((element) =>
                element.code == LoginSMSConstants.countryCodeDefault)
            .first
            .flagUri,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoHideKeyboard(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    S.current.welcome,
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    S.current.enterYourPhone,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                          color: Colors.black45,
                        ),
                  ),
                  const SizedBox(height: 30.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        Consumer<SMSModel>(
                          builder: (context, model, child) {
                            return GestureDetector(
                              onTap: () async {
                                final result =
                                    await showModel(model.country.code);
                                if (result == null) return;
                                model.updateCountryCode(result);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      model.flagUri,
                                      package: 'country_code_picker',
                                      width: 24.0,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Skeleton(
                                          width: 24,
                                          height: 24,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(model.countryName),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      '(${model.countryDialCode})',
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4.0,
                          ),
                          child: CustomTextField(
                            showCancelIcon: true,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            // Only numbers can
                            keyboardType: TextInputType.number,
                            onCancel: () {
                              model.updatePhoneNumber('');
                            },
                            onChanged: (value) {
                              model.updatePhoneNumber(value);
                            },
                            decoration: InputDecoration(
                              hintText: S.current.phoneNumber,
                              hintStyle: Theme.of(context).textTheme.bodyText1,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  Center(
                    child: RichText(
                      maxLines: 2,
                      text: TextSpan(
                        text: S.current.bySignup,
                        style: Theme.of(context).textTheme.bodyText1,
                        children: <TextSpan>[
                          TextSpan(
                            text: S.of(context).agreeWithPrivacy,
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => FluxNavigate.push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyTermScreen(
                                        showAgreeButton: false,
                                      ),
                                    ),
                                    forceRootNavigator: true,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CommonSafeArea(
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Selector<SMSModel, bool>(
                selector: (context, provider) => provider.isValidPhoneNumber,
                builder: (context, isValidPhoneNumber, child) {
                  return ElevatedButton.icon(
                    onPressed: !isValidPhoneNumber
                        ? null
                        : () {
                            Tools.hideKeyboard(context);
                            widget.onCallBack();
                          },
                    label: Text(
                      S.current.continues,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    icon: Icon(
                      CupertinoIcons.arrow_right_square_fill,
                      color: Theme.of(context).backgroundColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    // Column(
    //   children: [
    //     Expanded(
    //       flex: 1,
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           const SizedBox(
    //             height: 20.0,
    //           ),
    //           Text(
    //             S.of(context).mobileVerification,
    //             style: Theme.of(context).textTheme.headline6,
    //           ),
    //           const SizedBox(
    //             height: 5.0,
    //           ),
    //           Text(
    //             S.of(context).enterYourMobile,
    //             style: Theme.of(context).textTheme.subtitle1,
    //           ),
    //           const SizedBox(
    //             height: 10.0,
    //           ),
    //           Row(
    //             children: [
    //               Expanded(
    //                 flex: 8,
    //                 child: Consumer<SMSModel>(
    //                   builder: (_, model, __) => Directionality(
    //                     textDirection: TextDirection.ltr,
    //                     child: Container(
    //                         padding: const EdgeInsets.symmetric(
    //                             horizontal: 10.0, vertical: 10.0),
    //                         decoration: BoxDecoration(
    //                           border: Border.all(
    //                             width: 2,
    //                             color: model.phoneNumber.isEmpty
    //                                 ? Colors.grey.withOpacity(0.8)
    //                                 : Theme.of(context).primaryColor,
    //                           ),
    //                           borderRadius: BorderRadius.circular(10.0),
    //                         ),
    //                         child: Text(
    //                           model.phoneNumber.isEmpty
    //                               ? S.of(context).phoneHintFormat
    //                               : model.phoneNumber,
    //                           style: Theme.of(context)
    //                               .textTheme
    //                               .headline6!
    //                               .copyWith(
    //                                   fontFamily: 'Roboto',
    //                                   color: model.phoneNumber.isEmpty
    //                                       ? Colors.grey
    //                                       : Theme.of(context)
    //                                           .colorScheme
    //                                           .secondary,
    //                                   fontWeight: FontWeight.w500),
    //                         )),
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //           const SizedBox(height: 20.0),
    //           Center(
    //             child: Consumer<SMSModel>(
    //               builder: (_, model, __) => TextButton(
    //                 onPressed: () {
    //                   if (model.state != SMSModelState.loading) {
    //                     if (_isPhoneValid(model.phoneNumber)) {
    //                       widget.onCallBack();
    //                     }
    //                   }
    //                 },
    //                 style: TextButton.styleFrom(
    //                   backgroundColor: Theme.of(context).primaryColor,
    //                 ),
    //                 child: model.state != SMSModelState.loading
    //                     ? const Icon(
    //                         Icons.arrow_forward,
    //                         color: Colors.white,
    //                       )
    //                     : const SizedBox(
    //                         height: 20,
    //                         width: 20,
    //                         child: CircularProgressIndicator(
    //                           strokeWidth: 1.0,
    //                           valueColor:
    //                               AlwaysStoppedAnimation<Color>(Colors.white),
    //                         ),
    //                       ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //     Expanded(
    //       flex: 1,
    //       child: Directionality(
    //         textDirection: TextDirection.ltr,
    //         child: CustomKeyboard(
    //           onCallBack: _onUpdate,
    //           phoneNumber:
    //               Provider.of<SMSModel>(context, listen: false).phoneNumber,
    //         ),
    //       ),
    //     ),
    //   ],
    // );
  }
}
