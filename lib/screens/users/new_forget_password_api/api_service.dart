import 'dart:convert';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'models/login_response_model.dart';

class ForgetAPIService {
  static var client = http.Client();

  static Future<ForgetPasswordResponse> forgetOtpLogin(
      {required String email}) async {
    var requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.parse(ForgetConfig.apiURL + ForgetConfig.restPasswordApi);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({
        'email': email,
      }),
    );

    return ForgetPasswordResponse.fromJson(response.body);
  }

  static Future<ForgetPasswordResponse> forgetVerifyOtp({
    required String email,
    required String code,
  }) async {
    var requestHeaders = <String, String>{
      'Content-Type': 'application/json',
    };

    var url = Uri.parse(ForgetConfig.apiURL + ForgetConfig.validateCodeApi);
    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    return ForgetPasswordResponse.fromJson(response.body);
  }

  static Future<ForgetPasswordResponse> forgetSetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    var requestHeaders = <String, String>{
      'Content-Type': 'application/json',
    };
    var url = Uri.parse(
      ForgetConfig.apiURL + ForgetConfig.setPasswordApi,
    );
    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({
        'email': email.toString(),
        'code': code.toString(),
        'password': password.toString(),
      }),
    );

    return ForgetPasswordResponse.fromJson(response.body);
  }
}
