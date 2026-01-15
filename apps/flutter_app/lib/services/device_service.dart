import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      return windowsInfo.deviceId.replaceAll('{', '').replaceAll('}', '');
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios-device';
    }
    return 'unknown-device';
  }
}
