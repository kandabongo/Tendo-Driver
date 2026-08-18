import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/auth.service.dart';
import 'package:fuodz/services/lifecycle_event_handler.dart';
import 'package:fuodz/services/local_storage.service.dart';
import 'package:fuodz/services/overlay.service.dart';

class ExtendedOrderService {
  void fbListener() {
    //
    LocalStorageService.prefs!.setBool("appInBackground", false);
    LifecycleEventHandler().onLeaveHintCallback = () {
      if (AppService().driverIsOnline == false ||
          !AuthServices.authenticated()) {
        return;
      }
      LocalStorageService.prefs!.setBool("appInBackground", true);
      OverlayService().showFloatingBubble();
    };

    LifecycleEventHandler().onResumeCallback = () {
      LocalStorageService.prefs!.setBool("appInBackground", false);
      OverlayService().closeFloatingBubble();
    };
  }

  bool appIsInBackground() {
    return LocalStorageService.prefs!.getBool("appInBackground") ?? false;
  }

  void dispose() {
    LifecycleEventHandler().onLeaveHintCallback = null;
    LifecycleEventHandler().onResumeCallback = null;
  }
}
