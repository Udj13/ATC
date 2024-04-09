import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../model/app_state_model.dart';
//import '../model/connection_status.dart';

double _turns = 0.0;

class headerTraccarStatusIcon extends StatelessWidget {
  const headerTraccarStatusIcon({super.key, required this.model});

  final AppStateModel model;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
        initialData: null,
        stream: traccarConnectionStatus.updateDataStream,
        builder: (context, snapshot) {
          bool isAnimationPlaying = false;
          if (snapshot.data != null) {
            //debugPrint('Update notifier - ${snapshot.data}');
            if (!isAnimationPlaying) _turns += pi;
            isAnimationPlaying = true;
            traccarConnectionStatus.clearUpdateStream();
          } else {
            _turns = 0;
          }
          return AnimatedRotation(
            turns: _turns,
            curve: Curves.easeOutExpo,
            duration: const Duration(milliseconds: 500),
            child: traccarConnectionStatus.headerStatusIcon,
            onEnd: () => isAnimationPlaying = false,
          );
        });
  }
}
