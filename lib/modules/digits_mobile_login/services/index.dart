import 'dart:convert' as convert;

import 'package:inspireui/utils/logs.dart';
import 'package:quiver/strings.dart';

import '../../../models/entities/user.dart';
import '../../../services/services.dart';

class DigitsMobileLoginServices {
  final domain = Services().api.domain;

  Future<bool> signUpCheck(
      {required String username,
      required String email,
      required String? countryCode,
      required String? mobile}) async {
    try {
      var response = await httpPost(
          Uri.parse('$domain/wp-json/api/flutter_user/digits/register/check'),
          body: convert.jsonEncode({
            'username': username,
            'email': email,
            'country_code': countryCode,
            'mobile': mobile
          }),
          headers: {'Content-Type': 'application/json'});
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return true;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<User> signUp(
      {required String username,
      required String email,
      required String? countryCode,
      required String? mobile,
      required String? fToken}) async {
    try {
      var response = await httpPost(
          Uri.parse('$domain/wp-json/api/flutter_user/digits/register'),
          body: convert.jsonEncode({
            'username': username,
            'email': email,
            'country_code': countryCode,
            'mobile': mobile,
            'ftoken': fToken
          }),
          headers: {'Content-Type': 'application/json'});
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return User.fromWooJson(jsonDecode);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<bool> loginCheck(
      {required String? countryCode, required String? mobile}) async {
    try {
      var response = await httpPost(
          Uri.parse('$domain/wp-json/api/flutter_user/digits/login/check'),
          body: convert
              .jsonEncode({'country_code': countryCode, 'mobile': mobile}),
          headers: {'Content-Type': 'application/json'});
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return true;
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<User> login(
      {required String? countryCode,
      required String? mobile,
      required String? otp,
      required String? fToken}) async {
    try {
      var response = await httpPost(
          Uri.parse('$domain/wp-json/api/flutter_user/digits/login'),
          body: convert.jsonEncode({
            'otp': otp,
            'country_code': countryCode,
            'mobile': mobile,
            'ftoken': fToken
          }),
          headers: {'Content-Type': 'application/json'});
      var jsonDecode = convert.jsonDecode(response.body);
      if (jsonDecode is Map && isNotBlank(jsonDecode['message'])) {
        throw Exception(jsonDecode['message']);
      } else {
        return User.fromWooJson(jsonDecode);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }
}
