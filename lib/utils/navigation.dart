import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../model/device.dart';
import 'types.dart';

var _compassStreamController = StreamController<double>.broadcast();
Stream<double> get compassStream => _compassStreamController.stream;

var _ownPositionStreamController = StreamController<OwnPosition>.broadcast();
Stream<OwnPosition> get ownPositionStream =>
    _ownPositionStreamController.stream;

OwnPosition currentOwnPosition = OwnPosition(
  latitude: 0,
  longitude: 0,
  speed: 0,
  heading: 0,
);

final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
final positionStream = _geolocatorPlatform.getPositionStream();

Future<void> startNavigation() async {
  LocationPermission permission;
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Location Permission Denied');
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    debugPrint(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  try {
    FlutterCompass.events?.listen(
      (event) => compassListener(event),
      onError: (object, stackTrace) {
        if (kDebugMode) {
          print('compass error in navigation.dart');
        }
      },
    );
  } catch (e) {
    if (kDebugMode) {
      print('error caught: $e');
    }
  }

  LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best, distanceFilter: 0);

  _geolocatorPlatform
      .getPositionStream(locationSettings: locationSettings)
      .listen(
    (event) => geolocationListener(event),
    onError: (object, stackTrace) {
      if (kDebugMode) {
        print('navigation error in navigation.dart');
      }
    },
  );
}

void compassListener(CompassEvent compassEvent) {
  final double newHeading = compassEvent.heading ?? 0;
  //TODO: implement compassEvent.headingForCameraMode for AR mode
  _compassStreamController.add(newHeading);
}

void geolocationListener(Position newPosition) {
  final OwnPosition newOwnPosition = OwnPosition(
    latitude: newPosition.latitude,
    longitude: newPosition.longitude,
    speed: newPosition.speed,
    heading: newPosition.heading,
  );
  currentOwnPosition = newOwnPosition;
  _ownPositionStreamController.add(newOwnPosition);
}

String getDistanceString({
  required OwnPosition? selfPosition,
  required DevicePosition? trackerPosition,
}) {
  if (trackerPosition == null) return '';
  if (selfPosition == null) return '';

  final int distance = _geolocatorPlatform
      .distanceBetween(
        selfPosition.latitude,
        selfPosition.longitude,
        trackerPosition.latitude,
        trackerPosition.longitude,
      )
      .toInt();

  // print('    own: ${selfPosition.latitude} : ${selfPosition.longitude}');
  // print('tracker: ${trackerPosition.latitude} : ${trackerPosition.longitude}');
  // print('distance: $distance');

  if (distance < 100) return '${distance.toString()} m';
  if (distance < 1000) return distance.toString();
  if (distance > 1000 * 999) return 'Far \n away';
  return '${distance ~/ 1000} km';
}

double? getDirection({
  required double? heading,
  required OwnPosition? selfPosition,
  required DevicePosition? trackerPosition,
}) {
  if (heading == null) return null;
  if (trackerPosition == null) return null;
  if (selfPosition == null) return null;

  final double direction = heading +
      _geolocatorPlatform.bearingBetween(
        selfPosition.latitude,
        selfPosition.longitude,
        trackerPosition.latitude,
        trackerPosition.longitude,
      );

  return (-2 * pi * (direction + 180) / 360) + pi / 2;
}

String ageOfCoordinates(Position trackerPosition) {
  final String age =
      trackerPosition.timestamp?.toLocal().toIso8601String() ?? '';
  return age;
}
