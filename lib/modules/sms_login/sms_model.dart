import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:inspireui/utils/logs.dart';

import '../../../../models/entities/user.dart';
import '../../../../services/services.dart';
import '../../common/config.dart';
import '../../models/entities/firebase_error_exception.dart';
import '../../screens/login_sms/new_sms_api/api_service.dart';

enum SMSModelState { loading, complete }

class SMSModel extends ChangeNotifier {
  var _state = SMSModelState.complete;

  SMSModelState get state => _state;
  // String _verificationId = '';
  String _smsCode = '';
  String get smsCode => _smsCode;
  String _phoneNumber = LoginSMSConstants.dialCodeDefault;
  String get phoneNumber => _phoneNumber;

  String _otpHash = '';
  String get otpHash => _otpHash;
  CountryCode _countryCode = CountryCode();

  /// Computed
  // String get smsCode => _smsCode;

  // String get phoneNumber => _phoneNumber;

  String get phoneNumberWithoutZero => _phoneNumber.replaceFirst('0', '');

  String get dialPhoneNumber => _countryCode.dialCode! + phoneNumberWithoutZero;

  String get dialPhoneNumberWithoutPlus => dialPhoneNumber.replaceAll('+', '');

  String get countryDialCode => _countryCode.dialCode ?? '';

  CountryCode get country => _countryCode;

  String get flagUri => _countryCode.flagUri ?? '';

  String get countryName => _countryCode.name ?? 'Unknown';

  bool get isValidPhoneNumber => _phoneNumber.isNotEmpty;

  void updateCountryCode(CountryCode countryCode) {
    _countryCode = countryCode;
    notifyListeners();
  }

  /// Update state
  void _updateState(state) {
    _state = state;
    notifyListeners();
  }

  Future<void> sendOTP({
    Function? onPageChanged,
    Function? onMessage,
    Function? onVerify,
  }) async {
    try {
      _updateState(SMSModelState.loading);
      await APIService.otpLogin(_phoneNumber).then((response) async {
        if (response.data != null) {
          printLog(response.data.toString());
          printLog(response.message);

          _otpHash = response.data!;

          onPageChanged?.call();
          _updateState(SMSModelState.complete);
        } else {
          onMessage?.call();
        }
      });
      // await Services().firebase.verifyPhoneNumber(
      //       phoneNumber: dialPhoneNumber,
      //       verificationCompleted: (String? smsCode) {
      //         _smsCode = smsCode!;
      //         onVerify?.call();
      //       },
      //       verificationFailed: (FirebaseErrorException e) {
      //         onMessage?.call(e.code);
      //         _updateState(SMSModelState.complete);
      //       },
      //       codeSent: (String verificationId, int? resendToken) {
      //         _verificationId = verificationId;
      //         onPageChanged?.call();
      //         _updateState(SMSModelState.complete);

      ///Test with number +84764555949
      // Future.delayed(Duration(seconds: 3)).then((value) {
      //   _smsCode = '123456';
      //   onVerify();
      // });
      //   },
      //   codeAutoRetrievalTimeout: (String verificationId) {},
      // );
    } catch (err) {
      printLog(err);
      _updateState(SMSModelState.complete);
    }
  }

  Future<bool> smsVerify(Function showMessage) async {
    _updateState(SMSModelState.loading);
    try {
      _phoneNumber = _phoneNumber.replaceAll('+963', '').replaceAll(' ', '');
      return true;

      // final credential = Services().firebase.getFirebaseCredential(
      //     verificationId: _verificationId, smsCode: _smsCode);

      // final user = await Services()
      //     .firebase
      //     .loginFirebaseCredential(credential: credential);
      // if (user != null) {
      //   _phoneNumber = _phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      //   return true;
      // }
    } on FirebaseErrorException catch (err) {
      printLog(err.message);
      showMessage(err.code);
    }
    _updateState(SMSModelState.complete);
    return false;
  }

  Future<bool> isPhoneNumberExisted() async {
    final result = await Services().api.isUserExisted(phone: _phoneNumber);
    if (!result) {
      _updateState(SMSModelState.complete);
    }
    return result;
  }

  Future<bool> isUserExisted(String username) async {
    _updateState(SMSModelState.loading);
    final result = await Services().api.isUserExisted(username: username);
    if (result) {
      _updateState(SMSModelState.complete);
    }
    return result;
  }

  Future<User?> login() async {
    final result = await Services().api.loginSMS(token: _phoneNumber);
    if (result == null) {
      _updateState(SMSModelState.complete);
    }
    _smsCode = '';
    return result;
  }

  Future<User?> createUser(data) async {
    try {
      final user = await Services().api.createUser(
            phoneNumber: data['phoneNumber'],
            firstName: data['firstName'],
            lastName: data['lastName'],
            username: data['username'],
            password: data['password'],
          );
      _updateState(SMSModelState.complete);
      return user;
    } catch (e) {
      _updateState(SMSModelState.complete);
      rethrow;
    }
  }

  void updatePhoneNumber(val) {
    _phoneNumber = val;
    notifyListeners();
  }

  void updateSMSCode(val) {
    _smsCode = val;
    notifyListeners();
  }

  void updateNewotpHash(val) {
    _otpHash = val;
    notifyListeners();
  }
}
