import 'dart:async';

import 'package:another_one_traccar_manager/model/device.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;

import '../conf.dart';
import '../utils/types.dart';
import 'traccar/traccar.dart';
import 'devices_repository.dart';
import 'connection_status.dart';

/// Program logic for server backend:
/// 1. Login
/// 2. Get device list
/// 3. Load tracks with selected length
/// 4. Start web socket listener
/// 5. Start periodic checker,
///        which downloads new data if the socket broken

ConnectionStatus traccarConnectionStatus = ConnectionStatus();
ServerLoginStatus traccarStatus = ServerLoginStatus.disconnected;
TraccarServer traccar = TraccarServer();

class AppStateModel extends foundation.ChangeNotifier {
  // All the available devices.
  List<Device> _availableDevices = [];

  int get numberOfDevices => _availableDevices.length;

  TrackerSort _selectedSortOrder = TrackerSort.name;

  TrackerSort get selectedSortOrder {
    return _selectedSortOrder;
  }

  /// Returns a copy of the list of available devices, filtered by category.
  List<Device> getDevices() {
    return _availableDevices;
  }

  // Search the device catalog
  List<Device> search(String searchTerms) {
    return getDevices().where((device) {
      return device.name.toLowerCase().contains(searchTerms.toLowerCase());
    }).toList();
  }

  /// Loads the sorted list of available devices from the repository
  void loadSortedDevices() {
    _availableDevices = DevicesRepository.loadPDevices(TrackerSort.name);
    notifyListeners();
  }

  void setSortOrder(TrackerSort newSortOrder) {
    _selectedSortOrder = newSortOrder;
    notifyListeners();
  }

  void toggleTrackDrawing(Device device) {
    device.track.show = !device.track.show;
    notifyListeners();
  }

  // =====================================
  _callBackChangeStatus(ServerStatusCode newStatus) {
    debugPrint('New server status: $newStatus');
    traccarConnectionStatus.setErrorStatus(newStatus);
    traccarConnectionStatus.updateNotifier(null);
    notifyListeners();
  }

  /// Request to traccar module for login,
  /// [address] - domain or IP with http(s)
  ///
  Future<void> serverLogin({
    required String address,
    required String login,
    required String password,
    required Tail tailLength,
  }) async {
    debugPrint('Login button pressed');

    traccarStatus = ServerLoginStatus.tryingToConnect;
    notifyListeners();

    final ServerStatusCode? serverStatusCode = await traccar.login(
        url: address,
        name: login,
        password: password,
        callBackChangeStatus: _callBackChangeStatus);
    //Waiting to login, then...
    // success
    if (serverStatusCode == ServerStatusCode.connected) {
      traccarStatus = ServerLoginStatus.connected;
      traccarConnectionStatus.setErrorStatus(ServerStatusCode.connected);
      notifyListeners();
      await serverGetDevices();
      await serverGetTracks(tailLength: tailLength);
      startPeriodicCheckForUpdates();
    } else {
      // ... fail :-(
      traccarConnectionStatus.serverStatusCode =
          serverStatusCode ?? ServerStatusCode.lostConnection;
      traccarStatus = ServerLoginStatus.disconnected;

      //set error text
      traccarConnectionStatus.setErrorStatus(serverStatusCode);
      notifyListeners();
    }
  }

  /// Request to traccar logout,
  Future<void> serverLogout() async {
    debugPrint('Logout button pressed');
    stopPeriodicCheckForUpdates();
    traccarConnectionStatus.setErrorStatus(ServerStatusCode.disconnected);

    if (traccarStatus != ServerLoginStatus.disconnected) {
      traccarStatus = ServerLoginStatus.tryingToConnect;
      _availableDevices.clear();
      try {
        await traccar.logout();
      } catch (e) {
        debugPrint('Logout error in appStateModel/serverLogout - $e');
      }

      traccarStatus = ServerLoginStatus.disconnected;
    }
    traccarStatus = ServerLoginStatus.disconnected;
    notifyListeners();
  }

  /// Request to traccar module for get devices
  /// The result will be placed in the class [DevicesRepository]
  Future<void> serverGetDevices() async {
    final devices = await traccar.getDevices();
    if (devices == null) return;
    DevicesRepository.setDevicesList(devices);
    loadSortedDevices();
    await serverGetLastPositions();
    traccar.startWebSocketListener(lastPositionsListener);
  }

  serverGetLastPositions({bool withDelay = false}) async {
    for (var device in _availableDevices) {
      DevicePosition? lastPosition = await traccar.getLastPosition(device.id);
      if (device.setLastPosition(lastPosition)) {
        notifyListeners(); //new last position
        if (withDelay) await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Get new track
  serverGetTracks({
    Tail tailLength = Tail.tail30min,
    bool withDelay = false,
  }) async {
    if (tailLength == Tail.withoutTail) {
      debugPrint('Login without loading tracks');
      return;
    }

    DateTime startTailTime = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: tailLength30min));

    if (tailLength == Tail.tailToday) {
      final String startDayTimeSting =
          "${DateTime.now().toUtc().toString().substring(0, 11)}"
          "00:00:00.000000Z";
      startTailTime = DateTime.tryParse(startDayTimeSting) ?? startTailTime;
    }

    for (var device in _availableDevices) {
      debugPrint('');
      debugPrint('Try to gets track for ${device.name}');

      try {
        List<DevicePosition>? track = await traccar.getTrack(
            deviceId: device.id, startTime: startTailTime);
        //
        if (track != null) {
          if (device.track.loadTrack(track)) {
            notifyListeners(); //new track
            if (withDelay) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }
      } catch (e) {
        debugPrint('Error in serverGetTrack, device = ${device.name}');
      }
    }
  }

  /// Loading new pieces of tracks
  serverUpdateTracks({
    bool withDelay = false,
  }) async {
    for (var device in _availableDevices) {
      debugPrint('');
      debugPrint('Try to gets track for ${device.name} '
          'from ${device.track.endTTime} to now');

      try {
        List<DevicePosition>? track = await traccar.getTrack(
          deviceId: device.id,
          startTime: device.track.endTTime,
        );
        //
        if (track != null) {
          final int pointsAdded = device.track.addTrack(track);
          if (pointsAdded > 0) {
            debugPrint('$pointsAdded points added');
            notifyListeners(); //new track
            if (withDelay) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }
      } catch (e) {
        debugPrint('Error in serverGetTrack, device = ${device.name}');
      }
    }
  }

  updateNotifyListeners(int? id) {
    traccarConnectionStatus.updateNotifier(id); // rotate  indicator
    notifyListeners(); // update interface
  }

  //============================================================
  /// Listener new position from web sockets
  ///
  lastPositionsListener(DevicePosition? newlastPosition) {
    if (newlastPosition != null) {
      for (var device in _availableDevices) {
        if (device.id == newlastPosition.deviceId) {
          device.lastPosition = newlastPosition;
          updateNotifyListeners(device.id);
        }
      }
    }
  }

  //===============================================================
  // periodic updates check
  Timer? _updateTimer;

  startPeriodicCheckForUpdates() {
    _updateTimer = Timer.periodic(
      const Duration(seconds: traccarPeriodCheckForUpdatesInSec),
      periodicUpdateFunc,
    );
  }

  stopPeriodicCheckForUpdates() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
      _updateTimer = null;
    }
  }

  periodicUpdateFunc(Timer _) async {
    debugPrint('Time for check updates and socket status');
    updateNotifyListeners(0);
    //await serverGetLastPositions(withDelay: true);
    if (!traccar.isWebSocketOn) {
      debugPrint('Web socket OFF, start updating');
      await serverUpdateTracks(withDelay: true);
      debugPrint('Update tracks completed');
    }

    if ((!traccar.isWebSocketOn) &&
        (traccarConnectionStatus.serverStatusCode ==
            ServerStatusCode.connected)) {
      try {
        debugPrint('Try to start web socket ');
        traccar.startWebSocketListener(lastPositionsListener);
      } catch (e) {
        debugPrint('Fail restarting web socket');
      }
    }
  }
}

void debugPrintWarning(String text) {
  debugPrint('\x1B[33m$text\x1B[0m');
}

void debugPrintError(String text) {
  debugPrint('\x1B[31m$text\x1B[0m');
}
