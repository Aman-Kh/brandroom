import 'tiktok_video_meta.dart';

class TikTokVideo {
  List<String>? urls;
  TikTokVideoMeta? videoMeta;

  TikTokVideo({this.urls, this.videoMeta});

  TikTokVideo.fromJson(Map<String, dynamic> json) {
    urls = <String>[];
    for (var item in json['urls']) {
      if (item is String && item.isNotEmpty) {
        urls?.add(item);
      }
    }
    videoMeta = json['videoMeta'] != null
        ? TikTokVideoMeta.fromJson(json['videoMeta'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['urls'] = urls;
    if (videoMeta != null) {
      data['videoMeta'] = videoMeta!.toJson();
    }
    return data;
  }
}
