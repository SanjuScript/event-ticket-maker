import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class DeviceInfoProvider with ChangeNotifier {
  String deviceModel = '';
  String os = '';
  String userAgent = '';
  String language = '';
  String ipAddress = '';

  Future<void> init() async {
    if (kIsWeb) {
      userAgent = html.window.navigator.userAgent;
      language = html.window.navigator.language;
    } else {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model ?? '';
        os = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine ?? '';
        os = 'iOS ${iosInfo.systemVersion}';
      }
    }

    try {
      final ipResponse = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      ipAddress = jsonDecode(ipResponse.body)['ip'] ?? '';
    } catch (e) {
      ipAddress = 'unknown';
    }

    notifyListeners();
  }
}
