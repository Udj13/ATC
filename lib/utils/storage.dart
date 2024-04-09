import 'package:another_one_traccar_manager/utils/types.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ref: https://pub.dev/packages/shared_preferences/example

late SharedPreferences prefs;
late Future<AuthData> currentAuthData;

class AuthData {
  final String server;

  final String login;
  final String password;
  final bool autoconnect;

  final Tail tailLength;

  AuthData(
      {required this.server,
      required this.login,
      required this.password,
      required this.autoconnect,
      required this.tailLength});
}

Future<AuthData> getAuthParams() async {
  final prefs = await SharedPreferences.getInstance();
  final String server = prefs.getString('server') ?? '';
  final String login = prefs.getString('login') ?? '';
  final String password = prefs.getString('password') ?? '';
  final bool connect = prefs.getBool('autoconnect') ?? false;
  final Tail tailLength = loadTailLengthToStorage(prefs);

  debugPrint('Load auth from storage: $server, $login, $password,'
      ' autologin: $connect, tail: $tailLength');
  debugPrint('$connect');
  var result = AuthData(
    server: server,
    login: login,
    password: password,
    autoconnect: connect,
    tailLength: tailLength,
  );
  return result;
}

void setAuthParams(
    String server, String login, String password, bool autoconnect) async {
  debugPrint('Save auth to storage: $server, '
      '$login, $password, autologin: $autoconnect');
  prefs = await SharedPreferences.getInstance();
  prefs.setString('server', server);
  prefs.setString('login', login);
  prefs.setString('password', password);
  prefs.setBool('autoconnect', autoconnect);
}

//enum Tail { withoutTail, tail30min, tailToday } in types.dart
saveTailLengthToStorage(Tail tailLength) async {
  prefs = await SharedPreferences.getInstance();
  prefs.setString('tail', tailLength.toString());
}

Tail loadTailLengthToStorage(SharedPreferences prefs) {
  final String tail = prefs.getString('tail') ?? 'Tail.tail30min';
  if (tail == Tail.withoutTail.toString()) return Tail.withoutTail;
  if (tail == Tail.tail30min.toString()) return Tail.tail30min;
  if (tail == Tail.tailToday.toString()) return Tail.tailToday;
  return Tail.tail30min;
}
