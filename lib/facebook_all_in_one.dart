/*
 * @Author: Charley
 * @Date: 2020-10-29 15:16:09
 * @LastEditors: Charley
 * @LastEditTime: 2020-10-31 14:46:01
 * @FilePath: /facebook_all_in_one/lib/facebook_all_in_one.dart
 * @Description: FacebookAllInOne dart code
 */
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:facebook_all_in_one/src/access_token.dart';
import 'package:facebook_all_in_one/src/login_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class FacebookAllInOneLoginResponse {
  static const ok = 200;
  static const cancelled = 403;
  static const error = 500;
}

/// Different behaviors for controlling how the Facebook Login dialog should
/// be presented.
///
/// Ignored on iOS, as it's not supported by the iOS Facebook Login SDK anymore.
enum FacebookLoginBehavior {
  /// Login dialog should be rendered by the native Android or iOS Facebook app.
  ///
  /// If the user doesn't have a native Facebook app installed, this falls back
  /// to using the web browser based auth dialog.
  ///
  /// This is the default login behavior.
  ///
  /// Might have logout issues on iOS; see the [FacebookLogin.logOut] documentation.
  nativeWithFallback,

  /// Login dialog should be rendered by the native Android or iOS Facebook app
  /// only.
  ///
  /// If the user hasn't installed the Facebook app on their device, the
  /// login will fail when using this behavior.
  ///
  /// On iOS, this behaves like the [nativeWithFallback] option. This is because
  /// the iOS Facebook Login SDK doesn't support the native-only login.
  nativeOnly,

  /// Login dialog should be rendered by using a web browser.
  ///
  /// Might have logout issues on iOS; see the [FacebookLogin.logOut] documentation.
  webOnly,

  /// Login dialog should be rendered by using a WebView.
  webViewOnly,
}

class FacebookAllInOne {
  static const MethodChannel _channel = const MethodChannel('VistaTeam/facebook_all_in_one');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // deep link
  static Future<dynamic> getFBLinks() async {
    try {
      var data = await _channel.invokeMethod('getFBLinks');

      if (data == null) return null;

      final Map<String, String> result = new Map.from(data);
      return result;
    } catch (e) {
      debugPrint("Error retrieving deferred deep link: $e");

      return null;
    }
  }

  /// [permissions] permissions like ["email","public_profile"]
  static Future<LoginResult> login({
    List<String> permissions = const ['email', 'public_profile'],
    FacebookLoginBehavior loginBehavior = FacebookLoginBehavior.nativeWithFallback,
  }) async {
    final result = await _channel.invokeMethod("login", {
      "permissions": permissions,
      'behavior': _currentLoginBehaviorAsString(loginBehavior),
    });

    return LoginResult.fromJson(
      Map<String, dynamic>.from(result),
    ); // accessToken
  }

  /// [fields] string of fields like birthday,email,hometown
  Future<dynamic> getUserData({String fields = "name,email,picture"}) async {
    final result = await _channel.invokeMethod("getUserData", {"fields": fields});
    return Platform.isAndroid ? jsonDecode(result) : Map<String, dynamic>.from(result); //null  or dynamic data
  }

  /// Sign Out
  Future<void> logOut() async {
    await _channel.invokeMethod("logOut");
  }

  /// if the user is logged return one instance of AccessToken
  Future<AccessToken> get isLogged async {
    try {
      final result = await _channel.invokeMethod("isLogged");
      if (result != null) {
        return AccessToken.fromJson(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e, s) {
      print(e);
      print(s);
      return null;
    }
  }

  static String _currentLoginBehaviorAsString(FacebookLoginBehavior loginBehavior) {
    assert(loginBehavior != null, 'The login behavior was unexpectedly null.');

    switch (loginBehavior) {
      case FacebookLoginBehavior.nativeWithFallback:
        return 'nativeWithFallback';
      case FacebookLoginBehavior.nativeOnly:
        return 'nativeOnly';
      case FacebookLoginBehavior.webOnly:
        return 'webOnly';
      case FacebookLoginBehavior.webViewOnly:
        return 'webViewOnly';
    }

    throw StateError('Invalid login behavior.');
  }
}
