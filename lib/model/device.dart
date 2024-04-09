import 'package:flutter/cupertino.dart';

enum TrackerStatus {
  unknown,
  online,
  offline,
}

class DevicePositionStreams {
  final Stream<DevicePosition> positions;
  final Stream<Device> devices;

  DevicePositionStreams({required this.positions, required this.devices});
}

class Device {
  int id;
  String name;
  String uniqueId;
  TrackerStatus status;
  DateTime? lastUpdate;
  DevicePosition? lastPosition;

  Track track = Track();

  Device({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.status,
    required this.lastUpdate,
  });

  /// Set last position for device. Checks the time and
  /// returns "true" if the last position has changed.
  bool setLastPosition(DevicePosition? newLastPosition) {
    if (newLastPosition == null) {
      return false;
    }

    if (lastPosition != null) {
      try {
        if (lastPosition!.fixTime.isAfter(newLastPosition.fixTime)) {
          return false;
        }
      } catch (e) {
        debugPrint('Error in device.dart: setLastPosition');
      }
    }

    lastPosition = newLastPosition;
    lastUpdate = newLastPosition.fixTime;
    track.addNewPositionToTrack(newLastPosition);

    return true;
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    String lastUpdateText = '';
    try {
      lastUpdateText = json['lastUpdate'].toString().substring(0, 10);
    } catch (e) {
      lastUpdateText = 'never';
    }
    debugPrint('${json['name']} (${json['id']}), updated $lastUpdateText');

    //print(json['status']);
    //print(json['lastUpdate']);
    String jsonStatus = json['status'];
    TrackerStatus status = TrackerStatus.unknown;
    if (jsonStatus == 'offline') {
      status = TrackerStatus.offline;
    }
    if (jsonStatus == 'online') {
      status = TrackerStatus.online;
    }

    DateTime? lastUpdate;
    String jsonLastUpdate = json['lastUpdate'] ?? 'null';
    if (jsonLastUpdate != 'null') {
      lastUpdate = DateTime.tryParse(jsonLastUpdate);
    } else {
      status = TrackerStatus.unknown;
    }

    return Device(
      id: json['id'],
      name: json['name'],
      uniqueId: json['uniqueId'],
      status: status,
      lastUpdate: lastUpdate,
    );
  }
}

class DevicePosition {
  final int id;
  final int deviceId;
  final DateTime fixTime;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double course;

  DevicePosition({
    required this.id,
    required this.deviceId,
    required this.fixTime,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.course,
  });

  factory DevicePosition.fromJson(Map<String, dynamic> json) {
    // debugPrint(
    //     'device ${json['deviceId']}: lat: ${json['latitude']}, lon:${json['longitude']}');

    DateTime fixTime = DateTime.tryParse(json['fixTime']) ?? DateTime.utc(0);

    return DevicePosition(
      id: json['id'],
      deviceId: json['deviceId'],
      fixTime: fixTime,
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      speed: json['speed'],
      course: json['course'],
    );
  }
}

class Track {
  List<DevicePosition> _positions = [];
  bool show = true;
  DateTime startTime = DateTime.now();
  DateTime endTTime = DateTime.now();

  addNewPositionToTrack(DevicePosition? position) {
    if (position != null) {
      _positions.add(position);
      endTTime = position.fixTime;
    }
  }

  clearTrack() {
    _positions.clear();
    startTime = DateTime.now();
    endTTime = DateTime.now();
  }

  List<DevicePosition>? getTrack() {
    return _positions;
  }

  loadTrack(List<DevicePosition> track) {
    _positions = track;
    _positions.sort((a, b) => a.fixTime.compareTo(b.fixTime));
    //Todo: check this sort
    startTime = _positions.first.fixTime;
    endTTime = _positions.last.fixTime;
  }

  int addTrack(List<DevicePosition> track) {
    var positions = track;
    positions.sort((a, b) => a.fixTime.compareTo(b.fixTime));
    positions.removeAt(0);

    _positions.addAll(positions);

    startTime = _positions.first.fixTime;
    endTTime = _positions.last.fixTime;

    return positions.length;
  }
}
