/*
 * @Author: Charley
 * @Date: 2020-10-29 15:16:09
 * @LastEditors: Charley
 * @LastEditTime: 2020-10-30 12:11:12
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
  }) async {
    final result = await _channel.invokeMethod("login", {"permissions": permissions});

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
}
