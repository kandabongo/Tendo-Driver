import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:fuodz/my_app.dart';
import 'package:fuodz/services/local_storage.service.dart';
import 'package:fuodz/services/phone_util.service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

import 'constants/app_languages.dart';
import 'views/overlays/floating_app_bubble.view.dart';

//ssll handshake error
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloatingAppBubble(),
    ),
  );
}

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      //setting up firebase notifications
      await Firebase.initializeApp();
      await PhoneUtilService.init();
      //
      await translator.init(
        localeType: LocalizationDefaultType.asDefined,
        languagesList: AppLanguages.codes,
        assetsDirectory: 'assets/lang/',
      );
      //
      await LocalStorageService.getPrefs();

      //prevent ssl error
      HttpOverrides.global = new MyHttpOverrides();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // DIAGNOSTIC (temporary): in a RELEASE build a build-time exception
      // renders as a blank GREY box with no text - which is exactly what hid
      // the cause of the grey Home screen. This replaces that silent grey with
      // the real exception + widget location + top stack frames, drawn on
      // screen so it can be screenshotted (Logcat is unavailable). It also
      // mirrors the same details to Crashlytics. Remove once the root cause is
      // confirmed and fixed.
      ErrorWidget.builder = (FlutterErrorDetails details) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
        final stackHead =
            details.stack?.toString().split('\n').take(14).join('\n') ?? '';
        return Material(
          color: const Color(0xFFB00020),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                "APP ERROR (diagnostic build)\n\n"
                "${details.exceptionAsString()}\n\n"
                "WHERE: ${details.context?.toString() ?? '(unknown)'}\n\n"
                "$stackHead",
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ),
        );
      };

      //font
      GoogleFonts.pendingFonts([GoogleFonts.plusJakartaSans()]);
      // Run app!
      runApp(LocalizedApp(child: MyApp()));
    },
    (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    },
  );
}
