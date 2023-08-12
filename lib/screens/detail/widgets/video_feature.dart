import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../common/config.dart' show kLoadingWidget;
import '../../../common/constants.dart';

class FeatureVideoPlayer extends StatefulWidget {
  final String url;
  final bool? autoPlay;
  final bool forceLoad;

  const FeatureVideoPlayer(
    this.url, {
    Key? key,
    this.autoPlay,
    this.forceLoad = false,
  }) : super(key: key);

  @override
  State<FeatureVideoPlayer> createState() => _FeatureVideoPlayerState();
}

class _FeatureVideoPlayerState extends State<FeatureVideoPlayer> {
  VideoPlayerController? _controller;
  bool initialized = false;
  double? aspectRatio;
  bool isYoutube = false;

  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.forceLoad || widget.url.contains('.mp4')) {
      _controller = VideoPlayerController.network(widget.url)
        ..initialize()
        ..setLooping(true).then((_) {
          if (mounted) {
            setState(() {
              initialized = true;
              aspectRatio = _controller?.value.aspectRatio;
            });

            if (widget.autoPlay == true) _controller?.play();
          }
        });
    }

    /// Enable below to use the youtube video
    /// Compatible with: https://pub.dev/packages/youtube_player_iframe
    if (!isDesktop &&
        (widget.url.contains('youtu.be') || widget.url.contains('youtube'))) {
      isYoutube = true;
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: YoutubePlayerController.convertUrlToId(widget.url)!,
        params: const YoutubePlayerParams(
          showControls: false,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (!isYoutube) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isYoutube) {
      return initialized && _controller != null
          ? AspectRatio(
              aspectRatio: aspectRatio ?? _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          : Container(
              height: MediaQuery.of(context).size.width * 0.8,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: kLoadingWidget(context),
              ),
            );
    }

    if (isDesktop) {
      /// Desktop not support webview for YouTube iframe.
      return const SizedBox();
    }

    /// Enable below to use the youtube video
    /// Compatible with: https://pub.dev/packages/youtube_player_iframe
    return VisibilityDetector(
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          _youtubeController?.pauseVideo();
        }
      },
      key: ValueKey('youtube_player_iframe-${widget.url}'),
      child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
        if (orientation == Orientation.landscape) {
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: YoutubePlayer(
              controller: _youtubeController,
              aspectRatio: aspectRatio ?? 16 / 9,
            ),
          );
        }
        return SizedBox(
          height: MediaQuery.of(context).size.width * 0.8,
          width: MediaQuery.of(context).size.width,
          child: YoutubePlayer(
            controller: _youtubeController,
            aspectRatio: aspectRatio ?? 16 / 9,
          ),
        );
      }),
    );
  }
}
