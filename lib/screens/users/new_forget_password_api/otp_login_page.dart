import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';
import 'package:inspireui/utils/colors.dart';
import 'package:snippet_coder_utils/FormHelper.dart';
import 'package:snippet_coder_utils/ProgressHUD.dart';

import 'api_service.dart';
import 'otp_verify_page.dart';

class ForgetLoginPage extends StatefulWidget {
  const ForgetLoginPage({Key? key}) : super(key: key);

  @override
  ForgetLoginPageState createState() => ForgetLoginPageState();
}

class ForgetLoginPageState extends State<ForgetLoginPage> {
  String email = '';
  bool enableBtn = false;
  bool isAPIcallProcess = false;

  @override
  void initState() {
    super.initState();
    email = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: ProgressHUD(
        inAsyncCall: isAPIcallProcess,
        opacity: 0.3,
        key: UniqueKey(),
        child: loginUI(),
      ),
    );
  }

  Widget loginUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اعثر على حسابك'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image.network(
          //   "https://i.imgur.com/bOCEVJg.png",
          //   height: 180,
          //   fit: BoxFit.contain,
          // ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'العثور على عنوان بريدك الإلكتروني',
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'إدخال عنوان البريد الإلكتروني لاسترداد الحساب',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 5,
                  child: TextFormField(
                    key: const Key('loginEmailField2'),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(6),
                      hintText: 'Email',
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
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (String value) {
                      email = value;
                      enableBtn = true;
                    },
                    validator: (value) {
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FormHelper.submitButton(
              'Continue',
              () async {
                if (enableBtn) {
                  setState(() {
                    isAPIcallProcess = true;
                  });

                  await ForgetAPIService.forgetOtpLogin(email: email)
                      .then((response) async {
                    setState(() {
                      isAPIcallProcess = false;
                    });

                    if (response.data != null && response.data!.status == 200) {
                      const snackBar = SnackBar(
                        content: Text(
                          'تم إرسال الكود بنجاح',
                          textAlign: TextAlign.center,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FogetOTPVerifyPage(
                            // password: response.data?.status.toString(),
                            email: email,
                          ),
                        ),
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
}
