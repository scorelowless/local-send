import 'package:flutter/services.dart';

class HotspotHelper {
  static const MethodChannel _channel = MethodChannel('com.example.flutter_app/hotspot');

  static Future<bool> isHotspotEnabled() async {
    try {
      final bool? isEnabled = await _channel.invokeMethod<bool>('isHotspotEnabled');
      return isEnabled ?? false;
    } on PlatformException {
      return false;
    }
  }
}
