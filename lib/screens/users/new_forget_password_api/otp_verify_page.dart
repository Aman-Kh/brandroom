import 'package:flutter/material.dart';
import 'package:inspireui/utils.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:snippet_coder_utils/FormHelper.dart';
import 'package:snippet_coder_utils/ProgressHUD.dart';

import 'api_service.dart';
import 'new_password_page.dart';
import 'otp_login_page.dart';

class FogetOTPVerifyPage extends StatefulWidget {
  final String? email;
  final String? password;

  const FogetOTPVerifyPage({this.email, this.password});

  @override
  FogetOTPVerifyPageState createState() => FogetOTPVerifyPageState();
}

class FogetOTPVerifyPageState extends State<FogetOTPVerifyPage> {
  bool enableResendBtn = false;
  String _otpCode = '';
  final int _otpCodeLength = 4;
  bool _enableButton = false;
  //var autoFill;
  late FocusNode myFocusNode;
  bool isAPIcallProcess = false;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
    myFocusNode.requestFocus();

    // autoFill = PinFieldAutoFill(
    //   decoration: UnderlineDecoration(
    //     textStyle: const TextStyle(fontSize: 20, color: Colors.black),
    //     colorBuilder: FixedColorBuilder(Colors.black.withOpacity(0.3)),
    //   ),
    //   currentCode: _otpCode,
    //   codeLength: _otpCodeLength,
    //   onCodeSubmitted: (code) {},
    //   onCodeChanged: (code) {
    //     printLog(code);
    //     if (code!.length == _otpCodeLength) {
    //       _otpCode = code;
    //       _enableButton = true;
    //       FocusScope.of(context).requestFocus(FocusNode());
    //     }
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressHUD(
        inAsyncCall: isAPIcallProcess,
        opacity: 0.3,
        key: UniqueKey(),
        child: _otpVerify(),
      ),
    );
  }

  Widget _otpVerify() {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image.network(
          //   "https://i.imgur.com/6aiRpKT.png",
          //   height: 180,
          //   fit: BoxFit.contain,
          // ),
          Center(
            child: Text(
              'تعبئة الكود السري',
              style: Theme.of(context)
                  .textTheme
                  .headline6
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'قم بإدخال الكود المرسل إلى \n ${widget.email}',
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyText1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 10, 50, 5),
            child: TextFieldPinAutoFill(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(6),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              currentCode: _otpCode,
              codeLength: _otpCodeLength,
              onCodeSubmitted: (code) {},
              onCodeChanged: (code) {
                if (code.length == _otpCodeLength) {
                  _otpCode = code;
                  _enableButton = true;
                  FocusScope.of(context).requestFocus(FocusNode());
                }
              },
            ),
          ),

          Center(
            child: FormHelper.submitButton(
              'Continue',
              () {
                if (_enableButton) {
                  setState(() {
                    isAPIcallProcess = true;
                  });

                  ForgetAPIService.forgetVerifyOtp(
                          email: widget.email!, code: _otpCode)
                      .then((response) async {
                    setState(() {
                      isAPIcallProcess = false;
                    });

                    if (response.data?.status == 200) {
                      //REDIRECT TO HOME SCREEN
                      const snackBar = SnackBar(
                        content: Text(
                          'الكود صحيح',
                          textAlign: TextAlign.center,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NewPasswordOTPVerifyPage(
                                email: widget.email!, code: _otpCode)),
                      );
                    } else {
                      final snackBar = SnackBar(
                        content: Text(response.message!),
                        action: SnackBarAction(
                          label: 'رجوع',
                          textColor: Colors.white,
                          onPressed: () async {
                            await Navigator.pushAndRemoveUntil(
                              context,
                              // MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgetLoginPage()),
                              (route) => false,
                            );
                            // Some code to undo the change.
                          },
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  });
                }
              },
              btnColor: HexColor('#78D0B1'),
              borderColor: HexColor('#78D0B1'),
              txtColor: HexColor(
                '#000000',
              ),
              borderRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    myFocusNode.dispose();
    super.dispose();
  }
}

class CodeAutoFillTestPage extends StatefulWidget {
  @override
  CodeAutoFillTestPageState createState() => CodeAutoFillTestPageState();
}

class CodeAutoFillTestPageState extends State<CodeAutoFillTestPage>
    with CodeAutoFill {
  String? appSignature;
  String? otpCode;

  @override
  void codeUpdated() {
    setState(() {
      otpCode = code!;
    });
  }

  @override
  void initState() {
    super.initState();
    listenForCode();

    SmsAutoFill().getAppSignature.then((signature) {
      setState(() {
        appSignature = signature;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancel();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening for code'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Text(
              'This is the current app signature: $appSignature',
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Builder(
              builder: (_) {
                if (otpCode == null) {
                  return const Text('Listening for code...', style: textStyle);
                }
                return Text('Code Received: $otpCode', style: textStyle);
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
