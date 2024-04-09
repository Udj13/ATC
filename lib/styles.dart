// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// https://codelabs.developers.google.com/codelabs/flutter-cupertino/#2

import 'package:flutter/cupertino.dart';

abstract class Styles {
  static const TextStyle deviceName = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 0.8),
    fontSize: 18,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle productRowTotal = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 0.8),
    fontSize: 18,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.bold,
  );

  static const deviceStatusFontSize = 13.0;

  static const TextStyle deviceStatus = TextStyle(
    color: Color(0xFF8E8E93),
    fontSize: deviceStatusFontSize,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle deviceStatusStop = TextStyle(
    color: Color(0xFFA83838),
    fontSize: deviceStatusFontSize,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle deviceStatusOnMove = TextStyle(
    color: Color(0xFF388A45),
    fontSize: deviceStatusFontSize,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle badgeText = TextStyle(
    color: CupertinoColors.white,
    fontSize: 13,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle errorStatus = TextStyle(
    color: errorRed,
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle warningStatus = TextStyle(
    color: Color(0xFFE5DD02),
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle searchText = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 1),
    fontSize: 14,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle deliveryTimeLabel = TextStyle(
    color: Color(0xFFC2C2C2),
    fontWeight: FontWeight.w300,
  );

  static const TextStyle deliveryTime = TextStyle(
    color: CupertinoColors.inactiveGray,
  );

  static const Color errorRed = Color(0xFFBB0000);

  static const Color productRowDivider = Color(0xFFD9D9D9);

  static const Color scaffoldBackground = Color(0xfff0f0f0);

  static const Color searchBackground = Color(0xffe0e0e0);

  static const Color searchCursorColor = Color.fromRGBO(0, 122, 255, 1);

  static const Color searchIconColor = Color.fromRGBO(128, 128, 128, 1);
}
