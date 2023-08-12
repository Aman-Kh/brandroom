import 'package:flutter/material.dart';

import '../extensions/extensions.dart';

enum DisplayType {
  desktop,
  tablet,
  mobile,
}

const kLimitWidthScreen = 1400.0;
const _desktopBreakpointWstH = 1024.0; // Width is smaller than Height
const _desktopBreakpointWgtH = 700.0; // Width is greater than Height

extension BuildContextExt2 on BuildContext {
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  bool get isBigScreen {
    return query.size.width >= 768;
  }

  DisplayType get displayType {
    final size = query.size;
    if ((size.width < size.height && size.width <= _desktopBreakpointWstH) ||
        (size.width > size.height && size.width <= _desktopBreakpointWgtH)) {
      return DisplayType.mobile;
    } else {
      return DisplayType.desktop;
    }
  }
}
