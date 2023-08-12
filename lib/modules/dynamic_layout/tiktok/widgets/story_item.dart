import 'package:flutter/material.dart';
import '../../../../screens/detail/widgets/video_feature.dart';
import '../../../tiktok/index.dart';

class TikTokPlayerItem extends StatelessWidget {
  final TikTokVideoInfo item;

  const TikTokPlayerItem(this.item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: FeatureVideoPlayer(
        '${item.videoUrl}&dummy=${DateTime.now().millisecondsSinceEpoch}',
        autoPlay: true,
        forceLoad: true,
      ),
    );
  }
}
