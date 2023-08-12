import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/config.dart' as config;
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/user_model.dart';
import '../../services/index.dart';
import 'chat_mixin.dart';
import 'chat_screen.dart';
import 'scale_animation_mixin.dart';

class BottomSheetSmartChat extends StatefulWidget {
  final EdgeInsets? margin;
  final List<Map>? options;

  const BottomSheetSmartChat({this.margin, this.options});

  @override
  State<BottomSheetSmartChat> createState() => _BottomSheetSmartChatState();
}

class _BottomSheetSmartChatState extends State<BottomSheetSmartChat>
    with ChatMixin, ScaleAnimationMixin, SingleTickerProviderStateMixin {
  List<Map> get optionData => widget.options ?? config.smartChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        options = getSmartChatOptions();
      }
    });
  }

  IconButton getIconButton(
      IconData? iconData, double iconSize, Color iconColor, String? appUrl) {
    return IconButton(
      icon: Icon(
        iconData,
        size: iconSize,
        color: iconColor,
      ),
      onPressed: () async {
        if ((config.kConfigChat['UseRealtimeChat'] ?? false) &&
                Services().firebase.isEnabled ||
            ServerConfig().isBuilder) {
          final userModel = Provider.of<UserModel>(context, listen: false);
          if (userModel.user == null) {
            await Navigator.of(context).pushNamed(RouteList.login);
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
          return;
        }
        if (appUrl != null && await canLaunchUrl(Uri.parse(appUrl))) {
          if (appUrl.contains('http') &&
              !appUrl.contains('wa.me') &&
              !appUrl.contains('m.me')) {
            openChat(url: appUrl, context: context);
          } else {
            await launchUrl(
              Uri.parse(appUrl),
              mode: LaunchMode.externalApplication,
            );
          }
          return;
        }
        final snackBar = SnackBar(
          content: Text(
            S.of(context).canNotLaunch,
          ),
          action: SnackBarAction(
            label: S.of(context).undo,
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
  }

  List<Map> getSmartChatOptions() {
    final result = [];
    for (var i = 0; i < optionData.length; i++) {
      switch (optionData[i]['app']) {
        case 'firebase':
          if (Services().firebase.isEnabled || ServerConfig().isBuilder) {
            result.add({
              'app': 'firebase',
              'description': optionData[i]['description'] ?? S.of(context).chat,
              'iconData': optionData[i]['iconData'],
              'imageData': optionData[i]['imageData'],
            });
          }
          continue;
        default:
          result.add({
            'app': optionData[i]['app'],
            'description': optionData[i]['description'] ?? '',
            'iconData': optionData[i]['iconData'],
            'imageData': optionData[i]['imageData'],
          });
      }
    }
    return List<Map>.from(result);
  }

  @override
  Widget build(BuildContext context) {
    printLog('[build SmartChat]');

    var list = getSmartChatOptions();
    if (list.isEmpty) return const SizedBox();

    if (list.length == 1) {
      final option = optionData[0];
      final iconButton = getIconButton(
        option['iconData'],
        28,
        Theme.of(context).primaryColorLight,
        option['app'],
      );
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            onPressed: () {},
            heroTag: null,
            backgroundColor: Theme.of(context).primaryColor,
            child: iconButton,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ScaleTransition(
          scale: scaleAnimation,
          alignment: Alignment.center,
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: Theme.of(context).backgroundColor,
            onPressed: () async {
              if (scaleAnimationController.isCompleted) {
                Future.delayed(Duration.zero, scaleAnimationController.reverse);
                await Future.delayed(const Duration(milliseconds: 80), () {});
                await showActionSheet(context: context);
                await scaleAnimationController.forward();
              }
            },
            child: Icon(
              Icons.chat_rounded,
              color: Theme.of(context).primaryColor,
              size: 35,
            ),
          ),
        ),
      ),
    );
  }

  @override
  TickerProvider get vsync => this;
}

class BottomSheetSmartChatWhatsapp extends StatefulWidget {
  final EdgeInsets? margin;
  final List<Map>? options;

  const BottomSheetSmartChatWhatsapp({this.margin, this.options});

  @override
  State<BottomSheetSmartChatWhatsapp> createState() =>
      _BottomSheetSmartChatWhatsappState();
}

class _BottomSheetSmartChatWhatsappState
    extends State<BottomSheetSmartChatWhatsapp>
    with ChatMixin, ScaleAnimationMixin, SingleTickerProviderStateMixin {
  List<Map> get optionData => widget.options ?? config.smartChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        options = getSmartChatOptions();
      }
    });
  }

  IconButton getIconButton(
      IconData? iconData, double iconSize, Color iconColor, String? appUrl) {
    return IconButton(
      icon: Icon(
        iconData,
        size: iconSize,
        color: iconColor,
      ),
      onPressed: () async {
        if ((config.kConfigChat['UseRealtimeChat'] ?? false) &&
                Services().firebase.isEnabled ||
            ServerConfig().isBuilder) {
          final userModel = Provider.of<UserModel>(context, listen: false);
          if (userModel.user == null) {
            await Navigator.of(context).pushNamed(RouteList.login);
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
          return;
        }
        if (appUrl != null && await canLaunchUrl(Uri.parse(appUrl))) {
          if (appUrl.contains('http') &&
              !appUrl.contains('wa.me') &&
              !appUrl.contains('m.me')) {
            openChat(url: appUrl, context: context);
          } else {
            await launchUrl(
              Uri.parse(appUrl),
              mode: LaunchMode.externalApplication,
            );
          }
          return;
        }
        final snackBar = SnackBar(
          content: Text(
            S.of(context).canNotLaunch,
          ),
          action: SnackBarAction(
            label: S.of(context).undo,
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
  }

  IconButton getIconButton2(
      IconData? iconData, double iconSize, Color iconColor, String? appUrl) {
    return IconButton(
      padding: const EdgeInsets.all(3),
      icon: Image.asset(
        'assets/images/whatsapp_icon.png',
      ),
      onPressed: () async {
        if ((config.kConfigChat['UseRealtimeChat'] ?? false) &&
                Services().firebase.isEnabled ||
            ServerConfig().isBuilder) {
          final userModel = Provider.of<UserModel>(context, listen: false);
          if (userModel.user == null) {
            await Navigator.of(context).pushNamed(RouteList.login);
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
          return;
        }
        if (appUrl != null && await canLaunchUrl(Uri.parse(appUrl))) {
          if (appUrl.contains('http') &&
              !appUrl.contains('wa.me') &&
              !appUrl.contains('m.me')) {
            openChat(url: appUrl, context: context);
          } else {
            await launchUrl(
              Uri.parse(appUrl),
              mode: LaunchMode.externalApplication,
            );
          }
          return;
        }
        final snackBar = SnackBar(
          content: Text(
            S.of(context).canNotLaunch,
          ),
          action: SnackBarAction(
            label: S.of(context).undo,
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
    );
  }

  List<Map> getSmartChatOptions() {
    final result = [];
    for (var i = 0; i < optionData.length; i++) {
      switch (optionData[i]['app']) {
        case 'firebase':
          if (Services().firebase.isEnabled || ServerConfig().isBuilder) {
            result.add({
              'app': 'firebase',
              'description': optionData[i]['description'] ?? S.of(context).chat,
              'iconData': optionData[i]['iconData'],
              'imageData': optionData[i]['imageData'],
            });
          }
          continue;
        default:
          result.add({
            'app': optionData[i]['app'],
            'description': optionData[i]['description'] ?? '',
            'iconData': optionData[i]['iconData'],
            'imageData': optionData[i]['imageData'],
          });
      }
    }
    return List<Map>.from(result);
  }

  @override
  Widget build(BuildContext context) {
    printLog('[build SmartChat]');

    final iconButton = getIconButton2(
      FontAwesomeIcons.whatsapp, // Icons.whatsapp,
      50,
      Theme.of(context).primaryColorLight,
      'https://wa.me/963995040090',
    );
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 60.0),
        child: FloatingActionButton(
          onPressed: () {},
          heroTag: null,
          backgroundColor: Colors.white,
          child: iconButton,
        ),
      ),
    );

    // var list = getSmartChatOptions();
    // if (list.isEmpty) return const SizedBox();

    // if (list.length == 1) {

    // }

    // return Align(
    //   alignment: Alignment.bottomRight,
    //   child: Padding(
    //     padding: const EdgeInsets.all(14.0),
    //     child: ScaleTransition(
    //       scale: scaleAnimation,
    //       alignment: Alignment.center,
    //       child: FloatingActionButton(
    //         heroTag: null,
    //         backgroundColor: Theme.of(context).backgroundColor,
    //         onPressed: () async {
    //           if (scaleAnimationController.isCompleted) {
    //             Future.delayed(Duration.zero, scaleAnimationController.reverse);
    //             await Future.delayed(const Duration(milliseconds: 80), () {});
    //             await showActionSheet(context: context);
    //             await scaleAnimationController.forward();
    //           }
    //         },
    //         child: Icon(
    //           Icons.chat_rounded,
    //           color: Theme.of(context).primaryColor,
    //           size: 35,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  @override
  TickerProvider get vsync => this;
}
