import 'dart:async';

import 'package:flutter/material.dart';

import '../../common/tools/flash.dart';
import '../../generated/l10n.dart';
import '../../models/entities/blog.dart';
import '../../services/services.dart';

class ShareButton extends StatelessWidget {
  final Blog blog;

  const ShareButton({required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(
          FlashHelper.message(
            context,
            message: S.of(context).generatingLink,
            duration: const Duration(seconds: 1),
          ),
        );
        Services().firebase.shareDynamicLinkProduct(itemUrl: blog.link);
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Icon(
          Icons.share,
          size: 18.0,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
