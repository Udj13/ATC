import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../model/app_state_model.dart';
import '../model/device.dart';
import '../styles.dart';

import '../utils/navigation.dart';
import '../utils/types.dart';

class DeviceRowItem extends StatelessWidget {
  const DeviceRowItem({
    required this.device,
    required this.lastItem,
    required this.callBackFunc,
    Key? key,
  }) : super(key: key);

  final Device device;
  final bool lastItem;

  final Function callBackFunc;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(builder: (context, model, child) {
      final row = SafeArea(
        top: false,
        bottom: false,
        minimum: const EdgeInsets.only(
          left: 16,
          top: 8,
          bottom: 8,
          right: 8,
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: StreamBuilder<OwnPosition>(
                  stream: ownPositionStream,
                  builder: (context, ownPosition) {
                    if (!ownPosition.hasData) {
                      return const CircleImage();
                    }
                    return Stack(children: [
                      StreamBuilder<double>(
                          stream: compassStream,
                          builder: (context, heading) {
                            if (heading.hasData) {
                              final double? angle = getDirection(
                                heading: heading.data,
                                selfPosition: ownPosition.data,
                                trackerPosition: device.lastPosition,
                              );
                              if (angle != null) {
                                return Transform.rotate(
                                  angle: angle,
                                  child: const ArrowImage(),
                                );
                              }
                            }
                            // if no data
                            return const CircleImage();
                          }),
                      SizedBox(
                          width: 76,
                          height: 76,
                          child: Center(
                            child: Text(
                              getDistanceString(
                                selfPosition: ownPosition.data,
                                trackerPosition: device.lastPosition,
                              ),
                              style: Styles.deviceStatus,
                              textAlign: TextAlign.center,
                            ),
                          )),
                    ]);
                  }),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      device.name,
                      style: Styles.deviceName,
                    ),
                    const Padding(padding: EdgeInsets.only(top: 8)),
                    DeviceStatus(device: device)
                  ],
                ),
              ),
            ),
            (device.lastPosition != null)
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      model.toggleTrackDrawing(device);
                    },
                    child:
                        //const Icon(CupertinoIcons.clear_thick, color: CupertinoColors.inactiveGray,),
                        Icon(
                      CupertinoIcons.scribble,
                      color: (device.track.show)
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.inactiveGray,
                      semanticLabel: 'Path',
                    ),
                  )
                : const Icon(
                    CupertinoIcons.scribble,
                    color: CupertinoColors.inactiveGray,
                    semanticLabel: 'Track',
                  ),
            (device.lastPosition != null)
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      callBackFunc(
                        lat: device.lastPosition?.latitude,
                        lon: device.lastPosition?.longitude,
                      );
                      //final model = Provider.of<AppStateModel>(context, listen: false);
                      //model.addProductToCart(product.id);
                    },
                    child: const Icon(
                      CupertinoIcons.location_solid,
                      semanticLabel: 'GoTo',
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(width: 21),
                      Icon(
                        CupertinoIcons.question_circle,
                        color: CupertinoColors.inactiveGray,
                        semanticLabel: 'No points',
                      ),
                      SizedBox(width: 8),
                    ],
                  ),
          ],
        ),
      );

      if (lastItem) {
        return row;
      }

      return Column(
        children: <Widget>[
          row,
          Padding(
            padding: const EdgeInsets.only(
              left: 100,
              right: 16,
            ),
            child: Container(
              height: 1,
              color: Styles.productRowDivider,
            ),
          ),
        ],
      );
    });
  }
}

class ArrowImage extends StatelessWidget {
  const ArrowImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/arrow.png'),
      fit: BoxFit.cover,
      width: 76,
      height: 76,
    );
  }
}

class CircleImage extends StatelessWidget {
  const CircleImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/circle.png'),
      fit: BoxFit.cover,
      width: 76,
      height: 76,
    );
  }
}

class DeviceStatus extends StatelessWidget {
  const DeviceStatus({
    super.key,
    required this.device,
  });

  final Device device;

  String _offlineTimeToText(DateTime? fixTime) {
    if (fixTime == null) {
      return '';
    }

    final int hoursOffline =
        DateTime.now().difference(device.lastPosition!.fixTime).inHours.toInt();

    if (hoursOffline < 24) {
      return '$hoursOffline hours';
    }

    final int daysOffline =
        DateTime.now().difference(device.lastPosition!.fixTime).inDays.toInt();

    if (daysOffline < 356) {
      return daysOffline.toString() + ((daysOffline == 1) ? ' day' : ' days');
    } else {
      final int yearsOffline = daysOffline ~/ 365;
      return yearsOffline.toString() +
          ((yearsOffline == 1) ? ' year' : ' years');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (device.lastPosition != null) {
      final int hoursOffline = DateTime.now()
          .difference(device.lastPosition!.fixTime)
          .inHours
          .toInt();

      if (hoursOffline > 2) {
        return Text(
          'Offline ${_offlineTimeToText(device.lastPosition!.fixTime)}',
          style: Styles.deviceStatus,
        );
      }

      if (device.lastPosition!.speed > 4) {
        return Text(
          'Speed: ${device.lastPosition!.speed.toInt()} km/h',
          style: Styles.deviceStatusOnMove,
        );
      } else {
        return const Text(
          'Stop',
          style: Styles.deviceStatusStop,
        );
      }
    }
    return const Text(
      'Unknown',
      style: Styles.deviceStatus,
    );
  }
}
