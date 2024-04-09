import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../model/app_state_model.dart';
import 'device_row_item.dart';
import 'items/headerTraccarStatusIcon.dart';

// https://blog.logrocket.com/flutter-cupertino-tutorial-build-ios-apps-native/
// search from here

class TrackerListTab extends StatelessWidget {
  const TrackerListTab({
    Key? key,
    required this.callBackFunc,
  }) : super(key: key);

  final Function callBackFunc;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, model, child) {
        final devices = model.getDevices();
        return CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              leading: const Icon(
                CupertinoIcons.square_list_fill,
              ),
              largeTitle: const Text('Tracker list'),
              trailing: headerTraccarStatusIcon(model: model),
            ),
            SliverSafeArea(
              top: false,
              minimum: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < devices.length) {
                      return DeviceRowItem(
                        device: devices[index],
                        lastItem: index == devices.length - 1,
                        callBackFunc: callBackFunc,
                      );
                    }

                    return null;
                  },
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
