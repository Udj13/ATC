import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:web_socket_channel/io.dart';

import '../connection_status.dart';
import '../device.dart';
import '../tracking_server.dart';

class TraccarServer extends TrackingServer {
  Traccar? _traccarAPI;

  // Look at tracking_server.dart
  @override
  Future<ServerStatusCode?> login({
    required String url,
    required String name,
    required String password,
    required Function(ServerStatusCode newStatus) callBackChangeStatus,
  }) async {
    super.login(
      url: url,
      name: name,
      password: password,
      callBackChangeStatus: callBackChangeStatus,
    );
    _traccarAPI = Traccar(url, name, password, callBackChangeStatus);
    return await _traccarAPI?.login();
  }

  get isWebSocketOn => _traccarAPI!.isWebSocketOn;

  @override
  Future<void> logout() async {
    if (_traccarAPI != null) {
      await _traccarAPI?.logout();
      _traccarAPI = null;
    }
  }

  @override
  Future<List<Device>>? getDevices() async {
    if (_traccarAPI != null) {
      debugPrint('try to get devices');
      return await _traccarAPI!.getDevices();
    }
    final List<Device> emptyList = [];
    return emptyList;
  }

  Future<DevicePosition?> getLastPosition(int deviceId) async {
    if (_traccarAPI != null) {
      debugPrint('try to get position for $deviceId');
      return await _traccarAPI!.getLastPosition(deviceId);
    }
    return null;
  }

  Future<List<DevicePosition>?> getTrack({
    required int deviceId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    if (_traccarAPI != null) {
      (' ================= GET TRACKS ============================');
      debugPrint('try to get track for $deviceId');
      return await _traccarAPI!.getTrack(
        deviceId: deviceId,
        startTime: startTime,
        endTime: endTime,
      );
    }
    return null;
  }

  void startWebSocketListener(Function listener) {
    if (_traccarAPI != null) {
      // _traccar!.getPositionStream().devices.listen((event) {
      //   listener(event);
      // });
      try {
        _traccarAPI!.getPositionStream().positions.listen((event) {
          listener(event);
        });
      } catch (e) {
        debugPrint('Can not open web socket');
      }
    }
  }
}

//===================================================================
/// class for Traccar API calls
class Traccar {
  bool isWebSocketOn = false;

  bool isLogin = false;

  final String _url;
  final String _name;
  final String _password;

  final Function(ServerStatusCode newStatus) _callBackChangeStatus;

  final Dio _dio;
  final _cookieJar = CookieJar();

  Traccar(this._url, this._name, this._password, this._callBackChangeStatus)
      : _dio = Dio(BaseOptions(
            baseUrl: _url,
            connectTimeout: Duration(seconds: 3),
            receiveTimeout: Duration(seconds: 10),
            headers: {
              'Cookie': '',
              'Accept': 'application/json',
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              //'connection': 'Upgrade',
              //'upgrade': 'websocket',
            })) {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  String _setCookie = '';

  /// Login
  ///
  Future<ServerStatusCode> login() async {
    debugPrint('Start traccar login to $_url as $_name');

    try {
      final response = await _dio.post(
        '/api/session',
        data: {'email': _name, 'password': _password},
        options: Options(validateStatus: (_) => true),
      );
      //if (kDebugMode) print('Response code: ${response.statusCode}');
      //if (kDebugMode) print('Response: $response');
      if (response.statusCode == 200) {
        debugPrint('Login success');
        print(response.headers);

        final String cookies = response.headers.map['set-cookie']![0];
        //_setCookie = cookies.split(';')[0];
        _setCookie = cookies;
        debugPrint('cookie: $_setCookie');
        return ServerStatusCode.connected;
        //_callBackChangeStatus;
      } else {
        debugPrint('Login failed');
        return ServerStatusCode.loginFailed;
        //throw Exception('Login failed');
      }
    } on DioError catch (e) {
      if (e.error.toString().contains('Invalid port')) {
        debugPrint('Invalid port');
        return ServerStatusCode.invalidPort;
        //throw Exception('Port');
      }
      if (e.error.toString().contains('No address')) {
        debugPrint('Wrong server');
        return ServerStatusCode.wrongServer;
        //throw Exception('Address');
      }
      if (e.error.toString().contains('Handshake error')) {
        debugPrint('Https error');
        return ServerStatusCode.httpsError;
        //throw Exception('Https');
      }
      if (e.error.toString().contains('401')) {
        debugPrint('Wrong login');
        return ServerStatusCode.wrongLogin;
        //throw Exception('Login');
      }
    }
    return ServerStatusCode.disconnected;
  }

  ///LOGOUT
  ///
  Future<ServerStatusCode> logout() async {
    debugPrint('API request for logout');

    try {
      final response = await _dio.delete(
        '/api/session',
        options: Options(),
      );
      closePositionStream();

      if (response.statusCode == 204) {
        debugPrint('Logout success');
        closePositionStream();
        return ServerStatusCode.disconnected;
      } else {
        debugPrint('Logout  failed');
        return ServerStatusCode.loginFailed;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint('Logout  failed');
        return ServerStatusCode.loginFailed;
      } else {
        debugPrint('Logout  failed');
        return ServerStatusCode.loginFailed;
      }
    }
  }

  Future<List<Device>> getDevices() async {
    debugPrint('API request for get devices');

    try {
      final response = await _dio.get(
        '/api/devices',
        options: Options(contentType: "application/json"),
      );
      //if (kDebugMode) print('Response code: ${response.statusCode}');
      //if (kDebugMode) print('Response: $response');
      if (response.statusCode == 200) {
        debugPrint('Get devices success');
        final List<Device> devices =
            (response.data as List).map((e) => Device.fromJson(e)).toList();
        return devices;
      } else {
        debugPrintError(
            'traccar.dart: Get devices failed with http code ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrintError('traccar.dart: Get devices failed with exception: $e');
        return [];
      } else {
        debugPrintError('traccar.dart: Get devices failed with exception: $e');
        return [];
      }
    }
  }

  Future<DevicePosition?> getLastPosition(int deviceId) async {
//    if (kDebugMode) print('Start traccar get positions');
    //final DevicePosition position;

    try {
      final response = await _dio.get(
        '/api/positions?deviceId=$deviceId',
        options: Options(contentType: "application/json"),
      );
      //if (kDebugMode) print('Response code: ${response.statusCode}');
      //if (kDebugMode) print('Response: $response');
      if (response.statusCode == 200) {
        _callBackChangeStatus(ServerStatusCode.connected);
        // final List<Position> positions =
        //     (response.data as List).map((e) => Position.fromJson(e)).toList();

        try {
          DevicePosition? position = DevicePosition.fromJson(response.data[0]);
          return position;
        } catch (e) {
          debugPrint('Problem! Can\'t loading device with id = $deviceId');
          return null;
        }
      } else {
        debugPrint('traccar.dart: getLastPosition, response error');
      }
    } catch (e) {
      debugPrint(
          'traccar.dart: getLastPosition, DevicePosition.fromJson error');
      _callBackChangeStatus(ServerStatusCode.lostConnection);
    }
    return null;
  }

  /// Get track (list of position)
  Future<List<DevicePosition>> getTrack(
      {required int deviceId,
      required DateTime startTime,
      DateTime? endTime}) async {
    List<DevicePosition> track = [];

    const detailedDebug = false;

    if (detailedDebug) debugPrint('traccar.getTrack for $deviceId');

    final startTimeISO = startTime.toIso8601String().substring(0, 22);
    final parameterTo = DateTime.now().toIso8601String().substring(0, 22);

    if (detailedDebug) {
      debugPrint('start time: $startTimeISO, \n '
          'end time: $parameterTo');
    }

    final request = '/api/positions?deviceId=$deviceId'
        '&from=${startTimeISO}Z'
        '&to=${parameterTo}Z';

    if (detailedDebug) debugPrint('Request: $request');

    try {
      final response = await _dio.get(
        request,
        options: Options(contentType: "application/json"),
      );

      if (detailedDebug) debugPrint('Response ==================>');
      if (detailedDebug) debugPrint('ID = $deviceId');

      if (detailedDebug) debugPrint('Response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        _callBackChangeStatus(ServerStatusCode.connected);
        // final List<Position> positions =
        //     (response.data as List).map((e) => Position.fromJson(e)).toList();
        if (response.data == null) {
          return [];
        }

        if (detailedDebug) {
          debugPrint('----------response.data-------------------');
        }

        for (var element in response.data) {
          if (detailedDebug) debugPrint('Response: $element');
          try {
            DevicePosition? position = DevicePosition.fromJson(element);
            track.add(position);
            if (detailedDebug) {
              debugPrint('point ${position.id} added to track');
            }
          } catch (e) {
            debugPrint('traccar.dart:getTrack! '
                'error in track\'s point in $deviceId');
          }
        }
        debugPrint('Track length ${track.length} loaded from server');
        return track;

        //final List<dynamic> data = json.decode(response.data[0]);

        //debugPrint('from json: $data');

        // for (var d in data) {
        //   try {
        //     DevicePosition? position = DevicePosition.fromJson(d);
        //     track.add(position);
        //   } catch (e) {
        //     debugPrint(
        //         'traccar.dart:getTrack! Can\'t loading point track of $deviceId');
        //     return [];
        //   }
        // }
      } else {
        debugPrint('traccar.dart: getTrack, response error');
      }
    } catch (e) {
      debugPrint('traccar.dart: getTrack, DevicePosition.fromJson error');
    }
    return [];
  }

  /// get the data stream via web sockets from traccar api /api/socket
//  Stream<Position> getPositionStream() {

  late IOWebSocketChannel _channel;

  DevicePositionStreams getPositionStream() {
    isWebSocketOn = false;
    final StreamController<DevicePosition> positionStreamController =
        StreamController<DevicePosition>();
    final Stream<DevicePosition> positionStream =
        positionStreamController.stream.asBroadcastStream();

    final StreamController<Device> deviceStreamController =
        StreamController<Device>();
    final Stream<Device> deviceStream =
        deviceStreamController.stream.asBroadcastStream();

    try {
      final String webSocketAddress = 'ws://${_clearURL(_url)}:8082/api/socket';
      //final String webSocketAddress = 'ws://maps.free-gps.ru:8082/api/socket';

      debugPrint('Try websocket connection to $webSocketAddress');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(webSocketAddress),
        headers: {'Cookie': _setCookie},
      );

      _channel.stream.listen(
        (message) {
          isWebSocketOn = true;
          Map<String, dynamic> jsonData = jsonDecode(message);
          if (jsonData['devices'] != null) {
            final List<Device> devices = (jsonData['devices'] as List)
                .map((e) => Device.fromJson(e))
                .toList();
            for (var d in devices) {
              deviceStreamController.add(d);
            }
          }
          if (jsonData['positions'] != null) {
            final List<DevicePosition> positions =
                (jsonData['positions'] as List)
                    .map((e) => DevicePosition.fromJson(e))
                    .toList();
            for (var p in positions) {
              positionStreamController.add(p);
            }
          }
          //channel.sink.add('received!');
          //channel.sink.close(status.goingAway);
        },
        onDone: () {
          // on DONE ----------------------------
          debugPrint('Close web socket');
          isWebSocketOn = false;
          _channel.sink.close();
          deviceStreamController.close();
          positionStreamController.close();
        },
        // onError: () {
        //   // ERROR ------------------------------
        //   isWebSocketOn = false;
        //   debugPrint('Cannot open socket');
        //   _channel.sink.close();
        // },
      );
    } on SocketException catch (e) {
      isWebSocketOn = false;
      debugPrint('Cannot open socket, SocketException: $e');
      _channel.sink.close();
    } catch (e) {
      isWebSocketOn = false;
      debugPrint('Cannot open socket, e: $e');
      _channel.sink.close();
    }

    DevicePositionStreams devicePositionStreams = DevicePositionStreams(
      devices: deviceStream,
      positions: positionStream,
    );

    return devicePositionStreams;
  }

  closePositionStream() {
    isWebSocketOn = false;
    _channel.sink.close();
  }

  String _clearURL(String fullAddress) {
    String result = fullAddress.replaceFirst('https://', '');
    result = result.replaceFirst('http://', '');
    result = result.split(':')[0]; // port removing
    return result;
  }
}

void debugPrintWarning(String text) {
  debugPrint('\x1B[33m$text\x1B[0m');
}

void debugPrintError(String text) {
  debugPrint('\x1B[31m$text\x1B[0m');
}
