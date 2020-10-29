
import 'dart:async';

import 'package:flutter/services.dart';

class FacebookAllInOne {
  static const MethodChannel _channel =
      const MethodChannel('facebook_all_in_one');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
