import 'package:flutter/material.dart';
import 'package:snippet_coder_utils/FormHelper.dart';
import 'package:snippet_coder_utils/ProgressHUD.dart';

import '../../../common/constants.dart';

import 'api_service.dart';
import 'otp_login_page.dart';

class NewPasswordOTPVerifyPage extends StatefulWidget {
  final String email;
  final String code;

  const NewPasswordOTPVerifyPage({
    Key? key,
    required this.email,
    required this.code,
  }) : super(key: key);

  @override
  NewPasswordOTPVerifyPageState createState() =>
      NewPasswordOTPVerifyPageState();
}

class NewPasswordOTPVerifyPageState extends State<NewPasswordOTPVerifyPage> {
  String password = '';
  String email = '';
  String code = '';

  bool enableBtn = false;
  bool isAPIcallProcess = false;

  FocusNode inputNode = FocusNode();
// to open keyboard call this function;
  void openKeyboard() {
    FocusScope.of(context).requestFocus(inputNode);
  }

  @override
  void initState() {
    email = widget.email;
    code = widget.code;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressHUD(
        key: const Key('ProgressHUDaaa'),
        inAsyncCall: isAPIcallProcess,
        opacity: 0.3,
        child: ListView(
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Text(
                  'قم بوضع كلمة السر الجديدة',
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextFormField(
                  key: const Key('loginPasswordField2'),
                  focusNode: inputNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(6),
                    hintText: 'New Password',
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
                  autovalidateMode: AutovalidateMode.always,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (String value) {
                    password = value;

                    if (value.length >= 8) {
                      setState(() {
                        enableBtn = true;
                      });
                    } else {
                      setState(() {
                        enableBtn = false;
                      });
                    }
                  },
                  obscureText: true,
                  validator: (value) {
                    if (value!.length < 8) {
                      return 'يجب أن تكون كلمة السر من ٨ أحرف';
                    }
                    return null;
                  },
                ),
              ),
            ),
            if (enableBtn == true)
              Center(
                child: FormHelper.submitButton(
                  'Continue',
                  () {
                    if (enableBtn) {
                      setState(() {
                        isAPIcallProcess = true;
                      });

                      ForgetAPIService.forgetSetPassword(
                        email: email,
                        code: code,
                        password: password,
                      ).then((response) async {
                        setState(() {
                          isAPIcallProcess = false;
                        });

                        if (response.data != null &&
                            response.data?.status == 200) {
                          //REDIRECT TO LOgin SCREEN
                          const snackBar = SnackBar(
                            content: Text(
                              'تم تعديل كلمة السر بنجاح',
                              textAlign: TextAlign.center,
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(snackBar);

                          await Navigator.pushNamedAndRemoveUntil<dynamic>(
                            context,
                            (RouteList.login),
                            (route) =>
                                false, //if you want to disable back feature set to false
                          );
                          // await Navigator.pushAndRemoveUntil(
                          //   context,
                          //   // MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                          //   MaterialPageRoute(
                          //       builder: (context) => const SettingScreen()),
                          //   (route) => false,
                          // );
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
      ),
    );
  }
}
