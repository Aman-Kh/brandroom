import 'tiktok_video.dart';

class TikTokVideoInfo {
  String? id;
  String? text;
  bool? stitchEnabled;
  bool? shareEnabled;
  String? createTime;
  String? authorId;
  String authorAvatar = '';
  String? musicId;
  List<String>? covers;
  List<String>? coversOrigin;
  List<String>? shareCover;
  List<String>? coversDynamic;
  TikTokVideo? video;
  int? diggCount;
  int? shareCount;
  int? playCount;
  int? commentCount;
  bool? isOriginal;
  bool? isOfficial;
  bool? isActivityItem;
  bool? secret;
  bool? forFriend;
  bool? vl1;
  bool? liked;
  int? commentStatus;
  bool? showNotPass;
  bool? isAd;
  bool? itemMute;

  TikTokVideoInfo({
    this.id,
    this.text,
    this.stitchEnabled,
    this.shareEnabled,
    this.createTime,
    this.authorId,
    this.musicId,
    this.covers,
    this.coversOrigin,
    this.shareCover,
    this.coversDynamic,
    this.video,
    this.diggCount,
    this.shareCount,
    this.playCount,
    this.commentCount,
    this.isOriginal,
    this.isOfficial,
    this.isActivityItem,
    this.secret,
    this.forFriend,
    this.vl1,
    this.liked,
    this.commentStatus,
    this.showNotPass,
    this.isAd,
    this.itemMute,
  });

  TikTokVideoInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    text = json['text'];
    stitchEnabled = json['stitchEnabled'];
    shareEnabled = json['shareEnabled'];
    createTime = json['createTime'];
    authorId = json['authorId'];
    authorAvatar = json['authorAvatar'] ?? '';
    musicId = json['musicId'];
    covers = <String>[];
    for (var item in json['covers']) {
      if (item is String && item.isNotEmpty) {
        covers?.add(item);
      }
    }
    coversOrigin = <String>[];
    for (var item in json['coversOrigin']) {
      if (item is String && item.isNotEmpty) {
        coversOrigin?.add(item);
      }
    }
    shareCover = <String>[];
    for (var item in json['shareCover']) {
      if (item is String && item.isNotEmpty) {
        shareCover?.add(item);
      }
    }
    coversDynamic = <String>[];
    for (var item in json['coversDynamic']) {
      if (item is String && item.isNotEmpty) {
        coversDynamic?.add(item);
      }
    }
    video = json['video'] != null ? TikTokVideo.fromJson(json['video']) : null;
    diggCount = json['diggCount'];
    shareCount = json['shareCount'];
    playCount = json['playCount'];
    commentCount = json['commentCount'];
    isOriginal = json['isOriginal'];
    isOfficial = json['isOfficial'];
    isActivityItem = json['isActivityItem'];
    secret = json['secret'];
    forFriend = json['forFriend'];
    vl1 = json['vl1'];
    liked = json['liked'];
    commentStatus = json['commentStatus'];
    showNotPass = json['showNotPass'];
    isAd = json['isAd'];
    itemMute = json['itemMute'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['text'] = text;
    data['stitchEnabled'] = stitchEnabled;
    data['shareEnabled'] = shareEnabled;
    data['createTime'] = createTime;
    data['authorId'] = authorId;
    data['authorAvatar'] = authorAvatar;
    data['musicId'] = musicId;
    data['covers'] = covers;
    data['coversOrigin'] = coversOrigin;
    data['shareCover'] = shareCover;
    data['coversDynamic'] = coversDynamic;
    if (video != null) {
      data['video'] = video!.toJson();
    }
    data['diggCount'] = diggCount;
    data['shareCount'] = shareCount;
    data['playCount'] = playCount;
    data['commentCount'] = commentCount;
    data['isOriginal'] = isOriginal;
    data['isOfficial'] = isOfficial;
    data['isActivityItem'] = isActivityItem;
    data['secret'] = secret;
    data['forFriend'] = forFriend;
    data['vl1'] = vl1;
    data['liked'] = liked;
    data['commentStatus'] = commentStatus;
    data['showNotPass'] = showNotPass;
    data['isAd'] = isAd;
    data['itemMute'] = itemMute;
    return data;
  }
}
