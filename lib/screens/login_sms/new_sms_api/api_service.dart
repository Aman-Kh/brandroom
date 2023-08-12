import 'dart:convert';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models/login_response_model.dart';

class APIService {
  static var client = http.Client();

  static Future<LoginResponseModel> otpLogin(String mobileNo) async {
    var requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse(Config.apiURL + Config.otpLoginAPI);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({'phone': mobileNo}),
    );

    return loginResponseJson(response.body);
  }

  static Future<LoginResponseModel> verifyOtp(
    String mobileNo,
    String otpHash,
    String otpCode,
  ) async {
    var requestHeaders = <String, String>{
      'Content-Type': 'application/json',
    };

    var url = Uri.parse(Config.apiURL + Config.verifyOTPAPI);
    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({'phone': mobileNo, 'otp': otpCode, 'hash': otpHash}),
    );

    return loginResponseJson(response.body);
  }
}
