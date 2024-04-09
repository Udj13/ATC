
import 'device.dart';

enum TrackerSort {
  name,
  active,
}

class DevicesRepository {
  static List<Device> _allDevices = <Device>[];

  static void setDevicesList(List<Device> devices) {
    _allDevices = devices;
  }

  static List<Device> loadPDevices(TrackerSort sort) {
    // if (category == Category.all) {
    //   return _allProducts;
    // } else {
    //   return _allProducts.where((p) => p.category == category).toList();
    // }
    return _allDevices;
  }
}

// allDevices = <Device>[
// Device(
// name: "tracker 1",
// status: TrackerStatus.offline,
// id: 1,
// uniqueId: '111',
// lastUpdate: '111',
// ),
// Device(
// name: "tracker 2",
// status: TrackerStatus.offline,
// id: 1,
// uniqueId: '111',
// lastUpdate: '111',
// ),
// Device(
// name: "tracker 3",
// status: TrackerStatus.offline,
// id: 1,
// uniqueId: '111',
// lastUpdate: '111',
// ),
