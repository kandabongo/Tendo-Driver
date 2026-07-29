import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/app_permission_handler.service.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fuodz/constants/app_colors.dart';

class DriverCustomPermissionService {
  /**
   * Permission:
   * 1. Location
   * 2. Background Location
   * 3. Notification
   * 4. Background Service
   * 5. 
   *  */

  Future<bool> checkAllRequiredPermissions() async {
    //location
    bool permissionGranted = true;
    permissionGranted = await _handlePermission(
      Permission.locationWhenInUse,
      "Location Permission",
      "We need your location to find nearby requests",
      "assets/images/no_location.png",
    );
    if (!permissionGranted) {
      return false;
    }

    //background location
    permissionGranted = await _handlePermission(
      Permission.locationAlways,
      "Background Location Permission",
      "We need your background location to receive requests even when the app is in background",
      "assets/images/no_location.png",
    );
    if (!permissionGranted) {
      // return false;
      //although continue but let user know that they might not receive requests when app is in background or some other scenarios
      final context = AppService().navigatorKey.currentContext!;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Background Location Permission".tr()),
            content: Text(
              "Although you can continue, you might not receive requests when the app is in background or some other scenarios. You can always visit the settings to enable it"
                  .tr(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK".tr()),
              ),
            ],
          );
        },
      );
    }

    //notification
    permissionGranted = await _handlePermission(
      Permission.notification,
      "Notification Permission",
      "We need notification permission to alert you of new requests/messages",
      "assets/images/no-notification.png",
    );
    if (!permissionGranted) {
      return false;
    }

    //background service
    final bgServiceAllowed =
        await AppPermissionHandlerService().handleBackgroundRequest();
    if (!bgServiceAllowed) {
      return false;
    }

    //draw over: for when driver minimizes the app
    permissionGranted = await _handlePermission(
      Permission.systemAlertWindow,
      "Draw Over Permission",
      "We need draw over permission to alert you of new requests/messages",
      "assets/images/no-notification.png",
    );
    if (!permissionGranted) {
      return false;
    }

    return true;
  }

  Future<bool> _handlePermission(
    Permission permission,
    String title,
    String description,
    String asset,
  ) async {
    var status = await permission.status;
    if (status.isGranted) {
      return true;
    }

    // Show dialog
    final proceed = await _showPermissionDialog(title, description, asset);

    if (!proceed) {
      return false;
    }

    // Request permission
    status = await permission.request();
    return status.isGranted;
  }

  Future<bool> _showPermissionDialog(
    String title,
    String description,
    String asset,
  ) async {
    dynamic result = false;
    final context = AppService().navigatorKey.currentContext!;
    final isIos = Platform.isIOS;

    result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon/Image
                if (asset.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset(
                      asset,
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),

                // Title
                Text(
                  title.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // Description
                Text(
                  description.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 30),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      (isIos ? "Next" : "Request Permission").tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Cancel Button (Android only)
                if (!isIos) ...[
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(
                      "Cancel".tr(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (result is bool) {
      return result;
    }

    return false;
  }
}

//WIDGETS
