import 'connection_status.dart';
import 'device.dart';
import 'dart:async';

class TrackingServer {
  void login({
    required String url,
    required String name,
    required String password,
    required Function(ServerStatusCode newStatus) callBackChangeStatus,
  }) {}

  Future<void> logout() async {}

  Future<List<Device>>? getDevices() {
    return null;
  }

  late Future<List<Device>> getLastPositions;
  late Stream<DevicePosition> streamDeviceSositions;
}
