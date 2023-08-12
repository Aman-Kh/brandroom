import 'tiktok_video.dart';
import 'tiktok_video_info.dart';

extension TikTokVideoExtension on TikTokVideo {
  String get url {
    final urlList = urls;
    if (urlList == null || urlList.isEmpty) {
      return '';
    }
    return urlList.first;
  }
}

extension TikTokVideoInfoExtension on TikTokVideoInfo {
  String get videoUrl {
    return video?.url ?? '';
  }

  int get duration {
    return video?.videoMeta?.duration ?? 0;
  }

  String get videoThumbnail {
    var urls = covers;
    if (urls != null && urls.isNotEmpty) {
      return urls.last;
    }

    urls = coversOrigin;
    if (urls != null && urls.isNotEmpty) {
      return urls.last;
    }
    urls = shareCover;
    if (urls != null && urls.isNotEmpty) {
      return urls.last;
    }

    return '';
  }
}
