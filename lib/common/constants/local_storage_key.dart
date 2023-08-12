part of '../constants.dart';

// const appFolder = 'FluxBuilder/';
const appFolder = '';

class LocalStorageKey {
  /// FLUXBUILDER
  static const String loggedIn = '${appFolder}loggedIn';
  static const String app = '${appFolder}fstore';
  static const String notification = '${appFolder}notification';
  static const String blogWishList = '${appFolder}blogWishList';
  static const String recentBlogsSearch = '${appFolder}recentBlogSearch';
  static const String dataOrder = '${appFolder}data_order';
  static const String address = '${appFolder}address';
  static const String userCookie = '${appFolder}userToken';
  static const String instagramLocalKey = '${appFolder}instagram_';

  /// NORMAL APPS
  static const String seen = 'seen';
  static const String agreePrivacy = 'agreePrivacy';
  static const String posAddress = 'posAddress';
  static const String askedAgeRestriction = 'askedAgeRestriction';
  static const String popupBannerLastUpdatedTime = 'popupBannerLastUpdatedTime';
}

class FileHelper {
  static Future<String> createAppFolder() async {
    if (appFolder.isEmpty) {
      return '';
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final appDocDirFolder = Directory('${appDocDir.path}/$appFolder');

    if (await appDocDirFolder.exists()) {
      //if folder already exists return path
      return appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final appDocDirNewFolder = await appDocDirFolder.create(recursive: true);
      return appDocDirNewFolder.path;
    }
  }
}
