import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../styles.dart';

enum ServerLoginStatus {
  connected,
  tryingToConnect,
  disconnected,
}

class ConnectionStatus {
  bool isConnect = false;
  String status = '';
  bool notErrorJustWarning = false;
  ServerStatusCode serverStatusCode = ServerStatusCode.disconnected;
  IconData? icon;
  Widget? headerStatusIcon;
  bool hasNewData = false;

  bool isAllOk() {
    if (serverStatusCode == ServerStatusCode.connected) return true;
    if (serverStatusCode == ServerStatusCode.disconnected) return true;
    return false;
  }

  void setErrorStatus(ServerStatusCode? serverStatusCode) {
    if (serverStatusCode != null) {
      this.serverStatusCode = serverStatusCode;
    }

    notErrorJustWarning = false;

    switch (serverStatusCode) {
      case ServerStatusCode.connected:
        {
          icon = CupertinoIcons.check_mark_circled;
          status = 'Successful connected';
          headerStatusIcon = const Icon(
            CupertinoIcons.arrow_2_circlepath_circle,
            color: Colors.green,
          );
        }
        break;
      case ServerStatusCode.disconnected:
        {
          icon = CupertinoIcons.circle;
          status = 'Disconnected';
          headerStatusIcon = null;
        }
        break;

      case ServerStatusCode.wrongServer:
        {
          icon = CupertinoIcons.cloud_drizzle;
          status = 'Server unavailable...';
          headerStatusIcon = null;
        }
        break;

      case ServerStatusCode.invalidPort:
        {
          icon = CupertinoIcons.xmark_circle;
          status = 'Invalid port...';
          headerStatusIcon = null;
        }
        break;

      case ServerStatusCode.wrongLogin:
        {
          icon = CupertinoIcons.person_crop_circle_fill_badge_xmark;
          status = 'Wrong login...';
          headerStatusIcon = null;
        }
        break;
      case ServerStatusCode.loginFailed:
        {
          icon = CupertinoIcons.lock_circle;
          status = 'Login failed...';
          headerStatusIcon = null;
        }
        break;
      case ServerStatusCode.httpsError:
        {
          icon = CupertinoIcons.cloud_drizzle;
          status = 'Https error...';
          headerStatusIcon = null;
        }
        break;
      case ServerStatusCode.lostConnection:
        {
          icon = CupertinoIcons.clear_circled;
          status = 'Lost connection';
          headerStatusIcon = const Icon(
            CupertinoIcons.xmark_circle,
            color: Styles.errorRed,
          );
        }
        break;
      case ServerStatusCode.tryingToConnect:
        {
          icon = CupertinoIcons.bubble_right;
          status = 'Trying to connect...';
          headerStatusIcon = null;
        }
        break;

      case ServerStatusCode.webSocketError:
        {
          icon = CupertinoIcons.clear_circled;
          status = 'Web socket unavailable';
          //headerStatusIcon = null;
          notErrorJustWarning = true;
        }
        break;

      default:
        {
          icon = CupertinoIcons.xmark_circle;
          status = 'Unknown error...';
          headerStatusIcon = null;
        }
        break;
    }
  }

  var updateStreamController = StreamController<int?>.broadcast();
  Stream<int?> get updateDataStream => updateStreamController.stream;

  void updateNotifier(int? id) async {
    updateStreamController.add(id);
    await Future.delayed(const Duration(milliseconds: 500));
//        .then((value) => updateStreamController.add(null));
  }

  void clearUpdateStream() {
    updateStreamController.add(null);
  }
}

enum ServerStatusCode {
  connected,
  tryingToConnect,
  disconnected,
  lostConnection,
  wrongServer,
  wrongLogin,
  httpsError,
  loginFailed,
  invalidPort,
  webSocketError
}

// arrow_2_circlepath_circle_fill
// check_mark_circled
// circle_fill
// clear_circled
// cloud_download
// cloud
// goforward
// person
// person_circle
