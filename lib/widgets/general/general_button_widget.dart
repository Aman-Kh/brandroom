import 'package:flutter/material.dart';

import '../../common/config/models/general_setting_item.dart';
import '../../common/tools.dart';
import '../common/flux_image.dart';

class GeneralButtonWidget extends StatelessWidget {
  final GeneralSettingItem? item;
  const GeneralButtonWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    var itemVal = item ?? GeneralSettingItem();
    var buttons = itemVal.buttons;

    return Align(
      alignment: itemVal.displayButtonAlignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            buttons.length,
            (index) => InkWell(
              onTap: buttons[index].webUrl != null
                  ? () => Tools.launchURL(buttons[index].webUrl)
                  : null,
              child: Container(
                margin: EdgeInsets.only(
                  left: buttons[index].marginLeft.toDouble(),
                  right: buttons[index].marginRight.toDouble(),
                ),
                child: buttons[index].image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                            buttons[index].radius.toDouble()),
                        child: FluxImage(
                          imageUrl: buttons[index].image!,
                          width: buttons[index].width.toDouble(),
                          height: buttons[index].height.toDouble(),
                        ),
                      )
                    : SizedBox(
                        width: buttons[index].width.toDouble(),
                        height: buttons[index].height.toDouble(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
