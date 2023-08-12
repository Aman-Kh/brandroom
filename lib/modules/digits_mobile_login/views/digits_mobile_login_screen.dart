import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart';
import '../../../screens/login_sms/login_sms_screen.dart';
import '../../../screens/login_sms/verify.dart';
import '../services/index.dart';

class DigitsMobileLoginScreen extends LoginSMSScreen {
  const DigitsMobileLoginScreen();

  @override
  LoginSMSScreenState<DigitsMobileLoginScreen> createState() =>
      _LoginSMSState();
}

class _LoginSMSState extends LoginSMSScreenState<DigitsMobileLoginScreen> {
  final _services = DigitsMobileLoginServices();

  @override
  void loginSMS(context) {
    if (viewModel.phoneNumber.isEmpty) {
      Tools.showSnackBar(
          ScaffoldMessenger.of(context), S.of(context).pleaseInput);
    } else {
      try {
        Future autoRetrieve(String verId) {
          return stopAnimation();
        }

        Future smsCodeSent(String verId, [int? forceCodeResend]) {
          stopAnimation();
          return Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCode(
                verId: verId,
                phoneNumber: viewModel.phoneFullText,
                verifySuccessStream: viewModel.getStreamSuccess,
                resendToken: forceCodeResend,
                callback: _submitLogin,
              ),
            ),
          );
        }

        void verifyFailed(exception) {
          stopAnimation();
          failMessage(exception.message, context);
        }

        viewModel.verify(
            autoRetrieve: autoRetrieve,
            smsCodeSent: smsCodeSent,
            verifyFailed: verifyFailed,
            startVerify: () async {
              await playAnimation();
              try {
                await _services.loginCheck(
                    countryCode: viewModel.countryDialCode,
                    mobile: viewModel.phoneNumber);
                return true;
              } catch (e) {
                await stopAnimation()
                    .then((value) => failMessage(e.toString(), context));
                return false;
              }
            });
      } catch (e) {
        stopAnimation().then((value) => failMessage(e.toString(), context));
      }
    }
  }

  Future<void> _submitLogin(String smsCode, User user) async {
    try {
      await playAnimation();
      final fToken = await user.getIdToken();
      var loggedInUser = await _services.login(
          otp: smsCode,
          countryCode: viewModel.countryDialCode,
          mobile: viewModel.phoneNumber,
          fToken: fToken);
      await Provider.of<UserModel>(context, listen: false)
          .setUser(loggedInUser);
      await stopAnimation();
      NavigateTools.navigateAfterLogin(loggedInUser, context);
    } catch (e) {
      await stopAnimation();
      failMessage(e.toString(), context);
    }
  }
}
