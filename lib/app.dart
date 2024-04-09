
import 'package:another_one_traccar_manager/styles.dart';
import 'package:badges/badges.dart' as badges;
import 'package:another_one_traccar_manager/utils/navigation.dart';
import 'package:another_one_traccar_manager/utils/storage.dart';
import 'package:another_one_traccar_manager/widgets/map_tab.dart';
import 'package:another_one_traccar_manager/widgets/server_tab.dart';
import 'package:another_one_traccar_manager/widgets/trackers_list_tab.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '/model/app_state_model.dart';
import 'conf.dart';

class CupertinoTraccarApp extends StatelessWidget {
  const CupertinoTraccarApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoTraccarHomePage(),
    );
  }
}

class CupertinoTraccarHomePage extends StatefulWidget {
  const CupertinoTraccarHomePage({super.key});

  @override
  State<CupertinoTraccarHomePage> createState() =>
      _CupertinoTraccarHomePageState();
}

class _CupertinoTraccarHomePageState extends State<CupertinoTraccarHomePage> {
  // https://stackoverflow.com/questions/63516892/how-to-navigate-to-a-different-page-on-a-different-tab-using-cupertinotabbar
  int currentIndex = 0;
  var controller = CupertinoTabController(initialIndex: indexTrackersListTab);

  @override
  void initState() {
    super.initState();
    currentAuthData = getAuthParams();
    controller.index = indexSettingsTab;
    startNavigation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  LatLng? mapsRoute;

  void _openMapWithCoordinates({required double lat, required double lon}) {
    debugPrint('Try to open map with coordinates: $lat:$lon');
    mapsRoute = LatLng(lat, lon);
    controller.index = indexMapTab;
    mapGoTo(mapsRoute!); //from the map_tab.dart
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: controller,
      tabBar: CupertinoTabBar(
        onTap: (index) {
          mapsRoute = null;
          currentIndex = index;
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Consumer<AppStateModel>(builder: (context, model, child) {
              final devices = model.numberOfDevices;
              return badges.Badge(
                showBadge: devices > 0,
                position: badges.BadgePosition.topEnd(top: -4, end: -4),
                badgeStyle: const badges.BadgeStyle(
                  shape: badges.BadgeShape.circle,
                  badgeColor: CupertinoColors.activeBlue,
                ),
                badgeContent: Text(devices.toString(), style: Styles.badgeText),
                child: const Icon(CupertinoIcons.square_list),
              );
            }),
            label: 'Trackers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map),
            label: 'Map',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(CupertinoIcons.view_3d),
          //   label: 'AR',
          // ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cloud_download),
            label: 'Traccar',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        late final CupertinoTabView returnValue;
        switch (index) {
          case 0:
            returnValue = CupertinoTabView(builder: (context) {
              return CupertinoPageScaffold(
                child: TrackerListTab(
                  callBackFunc: _openMapWithCoordinates,
                ),
              );
            });
            break;
          case 1:
            returnValue = CupertinoTabView(builder: (context) {
              return CupertinoPageScaffold(
                child: MapTab(center: mapsRoute),
              );
            });
            break;
          // case 2:
          //   returnValue = CupertinoTabView(builder: (context) {
          //     return const CupertinoPageScaffold(
          //       child: ARTab(),
          //     );
          //   });
          //   break;
          case 2:
            returnValue = CupertinoTabView(builder: (context) {
              return CupertinoPageScaffold(child:
                  Consumer<AppStateModel>(builder: (context, model, child) {
                // final products = model.getDevices();
                return ServerTabPage(model, controller);
              }));
            });
            break;
        }
        return returnValue;
      },
    );
  }
}
