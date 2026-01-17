import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _uuid = Uuid();

  /// Get a unique device ID (persistent)
  Future<String> getDeviceId() async {
    // In production, this should be stored in SharedPreferences
    // For now, we'll use platform-specific IDs
    if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      return windowsInfo.deviceId.replaceAll('{', '').replaceAll('}', '');
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? _uuid.v4();
    }
    return _uuid.v4();
  }

  /// Get a friendly device name
  Future<String> getDeviceName() async {
    if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      return 'Windows PC (${windowsInfo.computerName})';
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return '${iosInfo.name} (${iosInfo.model})';
    } else if (Platform.isMacOS) {
      final macInfo = await _deviceInfo.macOsInfo;
      return 'Mac (${macInfo.computerName})';
    } else if (Platform.isLinux) {
      final linuxInfo = await _deviceInfo.linuxInfo;
      return 'Linux (${linuxInfo.name})';
    }
    return 'Unknown Device';
  }
}
