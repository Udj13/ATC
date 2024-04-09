import 'package:another_one_traccar_manager/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../conf.dart';
import '../model/connection_status.dart';
import '../utils/storage.dart';

import '../model/app_state_model.dart';
import '../utils/types.dart';
import 'items/headerTraccarStatusIcon.dart';

class ServerTabPage extends StatefulWidget {
  const ServerTabPage(this.model, this.tabController, {Key? key})
      : super(key: key);

  final AppStateModel model;
  final CupertinoTabController tabController;

  @override
  _ServerTabState createState() {
    return _ServerTabState();
  }
}

class _ServerTabState extends State<ServerTabPage> {
  _ServerTabState();

  late TextEditingController _serverTextController;
  late TextEditingController _loginTextController;
  late TextEditingController _pwdTextController;

  bool _obscure = true;

  bool _isNaneAndPwdCorrect = false;
  bool _isAddressCorrect = false;

  String _address = '';
  String _login = '';
  String _password = '';
  Tail _selectedTailLength = Tail.tail30min;

  bool _autoConnect = false;

  @override
  initState() {
    super.initState();
    _serverTextController = TextEditingController(text: 'http://');
    _loginTextController = TextEditingController(text: '');
    _pwdTextController = TextEditingController(text: '');

    currentAuthData.then((authData) {
      _address = authData.server;
      _login = authData.login;
      _password = authData.password;
      _autoConnect = authData.autoconnect;
      _selectedTailLength = authData.tailLength;
      inputChecker();

      _serverTextController.text = authData.server;
      _loginTextController.text = authData.login;
      _pwdTextController.text = authData.password;

      if (_autoConnect) {
        debugPrint(
            'autologin enabled, try login and change tab to Trackers List');
        // if auto connect is on...
        // try login to server
        widget.model.serverLogin(
          address: _address,
          login: _login,
          password: _password,
          tailLength: _selectedTailLength,
        );
        widget.tabController.index = indexTrackersListTab;
      }
    });
  }

  @override
  void dispose() {
    _serverTextController.dispose();
    _loginTextController.dispose();
    _pwdTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, model, child) {
        // final products = model.getDevices();
        return CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              leading: const Icon(CupertinoIcons.cloud_fill),
              largeTitle: const Text('Connection'),
              // middle: Row(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [Text('Disconnected')],
              // ),
              trailing: headerTraccarStatusIcon(model: model),
            ),
            SliverSafeArea(
                top: false,
                minimum: const EdgeInsets.only(top: 4),
                sliver: SliverList(
                  delegate: _buildAuthorizationDelegate(model),
                )),
          ],
        );
      },
    );
  }

  SliverChildBuilderDelegate _buildAuthorizationDelegate(AppStateModel model) {
    return SliverChildBuilderDelegate(
      (context, index) {
        switch (index) {
          case 0:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildServerAddressField(),
            );
          case 1:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildNameField(),
            );
          case 2:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPasswordField(),
            );
          case 3:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTailLength(),
            );

          case 4:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: (traccarStatus == ServerLoginStatus.disconnected)
                  ? _buildLoginButton(model)
                  : _buildLogoutButton(model),
            );
          case 5:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAutologinSwitch(),
            );

          case 6:
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildErrorInformationText());
          case 7:
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildOpenWebButton());
          case 8:
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildInformationText());
          default:
          // Do nothing. For now.
        }
        return null;
      },
    );
  }

  Widget _buildServerAddressField() {
    return CupertinoTextField(
        enabled: !(traccarStatus == ServerLoginStatus.connected),
        prefix: const Icon(
          CupertinoIcons.globe,
          color: CupertinoColors.lightBackgroundGray,
          size: 28,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        //clearButtonMode: OverlayVisibilityMode.editing,
        textCapitalization: TextCapitalization.words,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0,
              color: CupertinoColors.inactiveGray,
            ),
          ),
        ),
        placeholder: 'Traccar server',
        controller: _serverTextController,
        onChanged: (String newText) {
          _address = newText;
          inputChecker();
        });
  }

  Widget _buildNameField() {
    return CupertinoTextField(
        enabled: !(traccarStatus == ServerLoginStatus.connected),
        prefix: const Icon(
          CupertinoIcons.person_solid,
          color: CupertinoColors.lightBackgroundGray,
          size: 28,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        clearButtonMode: !(traccarStatus == ServerLoginStatus.connected)
            ? OverlayVisibilityMode.editing
            : OverlayVisibilityMode.never,
        textCapitalization: TextCapitalization.words,
        autocorrect: false,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0,
              color: CupertinoColors.inactiveGray,
            ),
          ),
        ),
        placeholder: 'Name',
        controller: _loginTextController,
        onChanged: (String newText) {
          _login = newText;
          inputChecker();
        });
  }

  Widget _buildPasswordField() {
    return CupertinoTextField(
        enabled: !(traccarStatus == ServerLoginStatus.connected),
        prefix: const Icon(
          CupertinoIcons.padlock,
          color: CupertinoColors.lightBackgroundGray,
          size: 28,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        clearButtonMode: OverlayVisibilityMode.editing,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0,
              color: CupertinoColors.inactiveGray,
            ),
          ),
        ),
        placeholder: 'Password',
        controller: _pwdTextController,
        obscureText: _obscure,
        suffix: !(traccarStatus == ServerLoginStatus.connected)
            ? CupertinoButton(
                child: Icon(
                    _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                })
            : const SizedBox.shrink(),
        onChanged: (String newText) {
          _password = newText;
          inputChecker();
        });
  }

  void inputChecker() {
    setState(() {
      _isAddressCorrect = _address.isNotEmpty;
      _isNaneAndPwdCorrect = (_login.isNotEmpty && _password.isNotEmpty);
    });
  }

  Widget _buildAutologinSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CupertinoSwitch(
            // This bool value toggles the switch.
            value: _autoConnect,
            activeColor: CupertinoColors.activeBlue,
            onChanged: (bool? value) {
              // This is called when the user toggles the switch.
              setState(() {
                _autoConnect = value ?? false;
              });

              setAuthParams(_address, _login, _password, _autoConnect);
            }),
        const SizedBox(width: 15),
        const Text('Switch auto login on start'),
      ],
    );
  }

  Widget _buildTailLength() {
    bool enabled = true;
    if (traccarStatus == ServerLoginStatus.connected) {
      enabled = false;
    }

    return CupertinoSegmentedControl<Tail>(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      groupValue: _selectedTailLength,
      selectedColor:
          enabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
      borderColor:
          enabled ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
      onValueChanged: (Tail value) {
        setState(() {
          if (enabled) _selectedTailLength = value;
          saveTailLengthToStorage(value);
        });
      },
      children: const <Tail, Widget>{
        Tail.withoutTail: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('No tail'),
        ),
        Tail.tail30min: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('30 min'),
        ),
        Tail.tailToday: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('All day'),
        ),
      },
    );
  }

  Widget _buildLoginButton(AppStateModel model) {
    String httpChecker(String address) {
      if (!address.startsWith('http')) {
        return 'http://$address';
      }
      return address;
    }

    void onPress() {
      _address = httpChecker(_address);
      _serverTextController.text = _address;

      setAuthParams(_address, _login, _password, _autoConnect);
      model.serverLogin(
        address: _address,
        login: _login,
        password: _password,
        tailLength: _selectedTailLength,
      );
    }

    return CupertinoButton.filled(
      onPressed: (_isAddressCorrect && _isNaneAndPwdCorrect) ? onPress : null,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.cloud_upload),
          SizedBox(width: 8),
          Text('Login Traccar'),
        ],
      ),
    );
  }

  callBackChangeStatus(ConnectionStatus newStatus) {
    debugPrint('New server status: ${newStatus.serverStatusCode}');
  }

  Widget _buildOpenWebButton() {
    void onPress() {
      debugPrint('Open Web page: $_address');
      _openWebPage(_address);
    }

    return CupertinoButton(
      onPressed: _isAddressCorrect ? onPress : null,
      child: const Text('Open server in web browser'),
    );
  }

  Widget _buildLogoutButton(AppStateModel model) {
    return CupertinoButton.filled(
      onPressed: () {
        model.serverLogout();
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.xmark_circle),
          SizedBox(width: 8),
          Text('Logout'),
        ],
      ),
    );
  }
}

_openWebPage(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

Widget _buildInformationText() {
  return const Text(
    "You can login any Traccar cloud server. \n "
    "If you can't connect, try other address options, for example: \n"
    "http://your_server_address, \n"
    "https://your_server_address, \n"
    "http://your_server_address:8082",
    style: Styles.deviceStatus,
  );
}

Widget _buildErrorInformationText() {
  if (traccarConnectionStatus.serverStatusCode == ServerStatusCode.connected) {
    return const SizedBox.shrink();
  }
  if (traccarConnectionStatus.serverStatusCode ==
      ServerStatusCode.disconnected) {
    return const SizedBox.shrink();
  }
  if (traccarConnectionStatus.isAllOk()) {
    return const SizedBox.shrink();
  } else {
    final TextStyle style = traccarConnectionStatus.notErrorJustWarning
        ? Styles.warningStatus
        : Styles.errorStatus;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(traccarConnectionStatus.icon, color: style.color),
        const SizedBox(width: 8),
        Text(traccarConnectionStatus.status, style: style),
      ],
    );
  }
}
