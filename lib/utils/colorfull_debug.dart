import 'package:flutter/cupertino.dart';

void debugPrintWarning(String text) {
  debugPrint('\x1B[33m$text\x1B[0m');
}

void debugPrintError(String text) {
  debugPrint('\x1B[31m$text\x1B[0m');
}
