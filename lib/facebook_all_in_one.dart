/*
 * @Author: Charley
 * @Date: 2020-10-29 15:16:09
 * @LastEditors: Charley
 * @LastEditTime: 2021-05-21 16:01:37
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
  static const EventChannel _eChannel = const EventChannel('VistaTeam/facebook_all_in_one_events');
  Stream<String>? _stream;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Stream<String> getLinksStream() {
    if (_stream == null) {
      _stream = _eChannel.receiveBroadcastStream().cast<String>();
    }
    return _stream!;
  }

  Stream<Uri> getUriLinksStream() {
    return getLinksStream().transform<Uri>(
      StreamTransformer<String, Uri>.fromHandlers(
        handleData: (String? link, EventSink<Uri?> sink) {
          if (link == null) {
            sink.add(null);
          } else {
            sink.add(Uri.parse(link));
          }
        },
      ),
    );
  }

  //----------------------------------------------------------------
  //get Launching Data
  //----------------------------------------------------------------

  static Future<String?> getLaunchingLink() async {
    dynamic launchingLink = await _channel.invokeMethod("getLaunchingLink");
    if (launchingLink is Null) {
      Future.value(null);
    }
    return Future.value(launchingLink as String?);
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
  Future<AccessToken?> get isLogged async {
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

  //----------------------------------------------------------------
  //event
  //----------------------------------------------------------------

  static const eventNameActivatedApp = 'fb_mobile_activate_app';
  static const eventNameDeactivatedApp = 'fb_mobile_deactivate_app';
  static const eventNameCompletedRegistration = 'fb_mobile_complete_registration';
  static const eventNameViewedContent = 'fb_mobile_content_view';
  static const eventNameRated = 'fb_mobile_rate';

  static const _paramNameValueToSum = "_valueToSum";
  static const paramNameRegistrationMethod = "fb_registration_method";

  /// Parameter key used to specify a generic content type/family for the logged event, e.g.
  /// "music", "photo", "video".  Options to use will vary depending on the nature of the app.
  static const paramNameContentType = "fb_content_type";

  /// Parameter key used to specify data for the one or more pieces of content being logged about.
  /// Data should be a JSON encoded string.
  /// Example:
  ///   "[{\"id\": \"1234\", \"quantity\": 2, \"item_price\": 5.99}, {\"id\": \"5678\", \"quantity\": 1, \"item_price\": 9.99}]"
  static const paramNameContent = "fb_content";

  /// Parameter key used to specify an ID for the specific piece of content being logged about.
  /// This could be an EAN, article identifier, etc., depending on the nature of the app.
  static const paramNameContentId = "fb_content_id";

  /// Clears the current user data
  static Future<void> clearUserData() {
    return _channel.invokeMethod<void>('clearUserData');
  }

  /// Clears the currently set user id.
  static Future<void> clearUserID() {
    return _channel.invokeMethod<void>('clearUserID');
  }

  /// Explicitly flush any stored events to the server.
  static Future<void> flush() {
    return _channel.invokeMethod<void>('flush');
  }

  /// Returns the app ID this logger was configured to log to.
  static Future<String?> getApplicationId() {
    return _channel.invokeMethod<String>('getApplicationId');
  }

  /// Log an app event with the specified [name] and the supplied [parameters] value.
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) {
    final args = <String, dynamic>{
      'name': name,
      'parameters': parameters,
      _paramNameValueToSum: valueToSum,
    };

    return _channel.invokeMethod<void>('logEvent', _filterOutNulls(args));
  }

  /// Sets user data to associate with all app events.
  /// All user data are hashed and used to match Facebook user from this
  /// instance of an application. The user data will be persisted between
  /// application instances.
  static Future<void> setUserData({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) {
    final args = <String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    };

    return _channel.invokeMethod<void>('setUserData', args);
  }

  /// Logs an app event that tracks that the application was open via Push Notification.
  static Future<void> logPushNotificationOpen({
    required Map<String, dynamic> payload,
    String? action,
  }) {
    final args = <String, dynamic>{
      'payload': payload,
      'action': action,
    };

    return _channel.invokeMethod<void>('logPushNotificationOpen', args);
  }

  /// Sets a user [id] to associate with all app events.
  /// This can be used to associate your own user id with the
  /// app events logged from this instance of an application.
  /// The user ID will be persisted between application instances.
  static Future<void> setUserID(String id) {
    return _channel.invokeMethod<void>('setUserID', id);
  }

  // Below are shorthand implementations of the predefined app event constants

  /// Log this event when an app is being activated.
  ///
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnameactivatedapp
  static Future<void> logActivatedApp() {
    return logEvent(name: eventNameActivatedApp);
  }

  /// Log this event when an app is being deactivated.
  ///
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnamedeactivatedapp
  static Future<void> logDeactivatedApp() {
    return logEvent(name: eventNameDeactivatedApp);
  }

  /// Log this event when the user has completed registration with the app.
  /// Parameter [registrationMethod] is used to specify the method the user has
  /// used to register for the app, e.g. "Facebook", "email", "Google", etc.
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnamecompletedregistration
  static Future<void> logCompletedRegistration({String? registrationMethod}) {
    return logEvent(
      name: eventNameCompletedRegistration,
      parameters: {
        paramNameRegistrationMethod: registrationMethod,
      },
    );
  }

  /// Log this event when the user has rated an item in the app.
  ///
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnamerated
  static Future<void> logRated({double? valueToSum}) {
    return logEvent(
      name: eventNameRated,
      valueToSum: valueToSum,
    );
  }

  /// Log this event when the user has viewed a form of content in the app.
  ///
  /// See: https://developers.facebook.com/docs/reference/androidsdk/current/facebook/com/facebook/appevents/appeventsconstants.html/#eventnameviewedcontent
  static Future<void> logViewContent({
    Map<String, dynamic>? content,
    String? id,
    String? type,
  }) {
    return logEvent(
      name: eventNameViewedContent,
      parameters: {
        paramNameContent: content,
        paramNameContentId: id,
        paramNameContentType: type,
      },
    );
  }

  /// Creates a new map containing all of the key/value pairs from [parameters]
  /// except those whose value is `null`.
  static Map<String, dynamic> _filterOutNulls(Map<String, dynamic> parameters) {
    final Map<String, dynamic> filtered = <String, dynamic>{};
    parameters.forEach((String key, dynamic value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  /// Re-enables auto logging of app events after user consent
  /// if disabled for GDPR-compliance.
  ///
  /// See: https://developers.facebook.com/docs/app-events/gdpr-compliance
  static Future<void> setAutoLogAppEventsEnabled(bool enabled) {
    return _channel.invokeMethod<void>('setAutoLogAppEventsEnabled', enabled);
  }

  /// Set Data Processing Options
  /// This is needed for California Consumer Privacy Act (CCPA) compliance
  ///
  /// See: https://developers.facebook.com/docs/marketing-apis/data-processing-options
  static Future<void> setDataProcessingOptions(
    List<String> options, {
    int? country,
    int? state,
  }) {
    final args = <String, dynamic>{
      'options': options,
      'country': country,
      'state': state,
    };

    return _channel.invokeMethod<void>('setDataProcessingOptions', args);
  }

  static Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) {
    final args = <String, dynamic>{
      'amount': amount,
      'currency': currency,
      'parameters': parameters,
    };
    return _channel.invokeMethod<void>('logPurchase', _filterOutNulls(args));
  }

  /// adid
  static Future<String> getAdid([bool requestTrackingAuthorization = false]) async {
    final String id = await _channel.invokeMethod('getAdvertisingId', requestTrackingAuthorization);
    return id;
  }

  static Future<bool> get isLimitAdTrackingEnabled async {
    return await _channel.invokeMethod('isLimitAdTrackingEnabled');
  }
}
