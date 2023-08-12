import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart' as config;
import '../../models/user_model.dart';
import '../../services/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen();

  @override
  State<ChatScreen> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);

    return ListenableProvider.value(
      value: userModel,
      child: Consumer<UserModel>(
        builder: (context, value, child) {
          if (value.user!.email == config.adminEmail) {
            return Services().firebase.renderListChatScreen();
          }
          return Services().firebase.renderChatScreen(
                senderUser: value.user,
                receiverEmail: config.adminEmail,
                receiverName: config.adminName,
              );
        },
      ),
    );
  }
}
