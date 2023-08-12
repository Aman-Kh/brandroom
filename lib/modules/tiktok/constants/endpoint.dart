import 'dart:core';

class TikTokEndPoints {
  static const String _domain = 'https://www.tiktok.com';
  static const String _user = '$_domain/node/share/user/@';

  /// This endpoint requires to request 20 times 😭😭 to get data.
  static const String _userAlt = '$_domain/api/user/detail/?uniqueId=';
  static const String _videos = '$_domain/share/item/list';

  static String getUserEndpoint(String username) {
    return '$_user$username';
  }

  static String getUserEndpointAlt(String username) {
    return '$_userAlt$username';
  }

  static String getVideosInfoEndpoint(
    String id,
    String secUid, {
    int count = 1,
    int minCursor = 0,
    int maxCursor = 0,
  }) {
    var endpoint = '$_videos?type=1';
    endpoint += '&count=$count';
    endpoint += '&minCursor=$minCursor';
    endpoint += '&maxCursor=$maxCursor';
    endpoint += '&id=$id';
    endpoint += '&secUid=$secUid';
    return endpoint;
  }
}
