import 'package:flutter/material.dart';

class TypeDeviceUtils {
  static bool isDesktop(BuildContext context, {double breakpoint = 900}) {
    return MediaQuery.sizeOf(context).width >= breakpoint;
  }

  static bool isCompact(BuildContext context, {double breakpoint = 700}) {
    return MediaQuery.sizeOf(context).width < breakpoint;
  }
}
