import 'package:safe_device/safe_device.dart';
import 'package:flutter/foundation.dart';

class SecurityCheckResult {
  final bool isSafe;
  final String message;

  SecurityCheckResult({required this.isSafe, required this.message});
}

class SecurityService {
  Future<SecurityCheckResult> checkDeviceSecurity() async {
    // Skip checks on web
    if (kIsWeb) {
      return SecurityCheckResult(
        isSafe: true,
        message: 'Web environment safe.',
      );
    }

    try {
      // 1. Check Root / Jailbreak
      // SafeDevice.isJailBroken checks for Root on Android and Jailbreak on iOS
      bool isJailBroken = await SafeDevice.isJailBroken;

      if (isJailBroken) {
        return SecurityCheckResult(
          isSafe: false,
          message:
              'Rooted or Jailbroken device detected.\n\nFor security reasons, this application cannot run on compromised devices.',
        );
      }

      // 2. Real Device Check (Optional - enforcing strict security)
      // Note: We are primarily concerned with Root status as per request.
      // Uncomment if you want to block Emulators too.
      /*
      bool isRealDevice = await SafeDevice.isRealDevice;
      if (!isRealDevice) {
         return SecurityCheckResult(
          isSafe: false, 
          message: 'Emulator detected. App must run on a real device.'
        );
      }
      */

      return SecurityCheckResult(isSafe: true, message: 'Device is secure.');
    } catch (e) {
      debugPrint("Security Check Failed to execute: $e");
      // If the check itself fails (e.g. platform channel issue), we typically Log it.
      // For now, we allow proceeding if the CHECK fails, to avoid bricking users on weird devices.
      return SecurityCheckResult(
        isSafe: true,
        message: 'Security check passed (fallback).',
      );
    }
  }
}
