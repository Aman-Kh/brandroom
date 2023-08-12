import 'dart:convert';
import 'dart:math';
import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/languages/local_widgets_localizations.dart';
import '../../services/index.dart' show ServerConfig;
import '../config.dart' show kAdvanceConfig;
import '../constants.dart' show RegexUtils, isMobile, kIsWeb, printLog;

class Tools {
  static double? formatDouble(num? value) => value == null ? null : value * 1.0;

  /// check tablet screen
  static bool isTablet(MediaQueryData query) {
    if (ServerConfig().isBuilder) {
      return false;
    }

    if (kIsWeb) {
      return true;
    }

    if (UniversalPlatform.isWindows || UniversalPlatform.isMacOS) {
      return false;
    }

    var size = query.size;
    var diagonal =
        sqrt((size.width * size.width) + (size.height * size.height));
    var isTablet = diagonal > 1100.0;
    return isTablet;
  }

  static bool isPhone(MediaQueryData query) {
    return isMobile && !isTablet(query);
  }

  static Future<List<dynamic>> loadStatesByCountry(String country) async {
    try {
      // load local config
      var path = 'lib/config/states/state_${country.toLowerCase()}.json';
      //if use loadString can't catch file is not exists
      final data = await rootBundle.load(path);
      String? appJson;
      if (data.lengthInBytes < 50 * 1024) {
        appJson = utf8.decode(data.buffer.asUint8List());
      } else {
        String utf8decode(ByteData data) {
          return utf8.decode(data.buffer.asUint8List());
        }

        appJson = utf8decode(data);
      }
      return List<dynamic>.from(jsonDecode(appJson));
    } catch (e) {
      return [];
    }
  }

  static dynamic getValueByKey(Map<String, dynamic>? json, String? key) {
    if (key == null) return null;
    try {
      List keys = key.split('.');
      Map<String, dynamic>? data = Map<String, dynamic>.from(json!);
      if (keys[0] == '_links') {
        var links = json['listing_data']['_links'] ?? [];
        for (var item in links) {
          if (item['network'] == keys[keys.length - 1]) return item['url'];
        }
      }
      for (var i = 0; i < keys.length - 1; i++) {
        if (data![keys[i]] is Map) {
          data = data[keys[i]];
        } else {
          return null;
        }
      }
      if (data![keys[keys.length - 1]].toString().isEmpty) return null;
      return data[keys[keys.length - 1]];
    } catch (e) {
      printLog(e.toString());
      return 'Error when mapping $key';
    }
  }

  static void showSnackBar(ScaffoldMessengerState? state, message) {
    if (state != null) {
      state.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static Future<void> launchMapsURL(dynamic lat, dynamic long) async {
    var googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$long';
    await Tools.launchURL(googleUrl);
  }

  static Future<void> launchURL(
    String? url, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    final uri = Uri.parse(url ?? '');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: mode);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<dynamic> parseJsonFromAssets(String assetsPath) async {
    return rootBundle.loadString(assetsPath).then(jsonDecode);
  }

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static bool isRTL(BuildContext context) {
    var languageCode = Localizations.localeOf(context).languageCode;
    return Bidi.isRtlLanguage(languageCode) ||
        LocalWidgetsLocalizations.isRtlLanguage(languageCode);
  }

  static String? convertDateTime(DateTime date) {
    return DateFormat.yMd().add_jm().format(date);
  }

  static String? getTimeWith2Digit(String time) {
    return time.length == 1 ? '0$time' : time;
  }

  static String getFileNameFromUrl(String url) {
    final nameFromUrlRegExp = RegExp(RegexUtils.fileNameFromUrl);
    if (RegexUtils.check(url, RegexUtils.url) &&
        nameFromUrlRegExp.hasMatch(url)) {
      return nameFromUrlRegExp.stringMatch(url)!;
    }
    return url;
  }

  static String removeHTMLTags(String value) {
    try {
      final document = parse(value);
      if (document.body == null) {
        return value;
      }
      final parsedString = parse(document.body!.text).documentElement!.text;
      return parsedString;
    } catch (e) {
      printLog(e);
    }
    return value;
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    var distance = 12742 * asin(sqrt(a));
    return distance.roundToDouble();
  }

  static dynamic formatDate(String date) {
    var dateFormat = DateFormat(DateFormat.YEAR_MONTH_DAY);
    return dateFormat.format(DateTime.tryParse(date) ?? DateTime.now());
  }

  static dynamic formatDateToLocal(String date) {
    var dateFormat = DateFormat(DateFormat.YEAR_MONTH_DAY);
    return dateFormat
        .format(DateTime.tryParse(date)?.toLocal() ?? DateTime.now());
  }

  static String? getCurrencyCode(String? currency) {
    var currencies = kAdvanceConfig.currencies;
    if (currencies.isNotEmpty) {
      var item = currencies
          .firstWhere((element) => element.currencyDisplay == currency);
      return item.currencyCode;
    }
    return currency;
  }

  static FontWeight getFontWeight(
    dynamic fontWeight, {
    FontWeight? defaultValue,
  }) {
    var fontWeightVal = '$fontWeight';
    switch (fontWeightVal) {
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '400':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '700':
        return FontWeight.w700;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return defaultValue ?? FontWeight.w400;
    }
  }

  static AlignmentGeometry getAlignment(
    String? alignment, {
    AlignmentGeometry? defaultValue,
  }) {
    switch (alignment) {
      case 'left':
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'right':
      case 'centerRight':
        return Alignment.centerRight;
      case 'topLeft':
        return Alignment.topLeft;
      case 'topRight':
        return Alignment.topRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomRight':
        return Alignment.bottomRight;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'topCenter':
        return Alignment.topCenter;
      case 'center':
      default:
        return defaultValue ?? Alignment.center;
    }
  }
}
