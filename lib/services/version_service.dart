import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

enum VersionStatus { upToDate, updateRequired, maintenanceMode, error }

class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VersionStatus> checkVersionStatus() async {
    try {
      // 1. Get Local App Version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      debugPrint('Current App Version: $currentVersion');

      // 2. Fetch Config from Firestore
      final DocumentSnapshot configDoc =
          await _firestore.collection('config').doc('app_settings').get();

      if (!configDoc.exists) {
        // If config doesn't exist, assume we are safe (or create default)
        debugPrint('Config document not found. Assuming up-to-date.');
        return VersionStatus.upToDate;
      }

      final Map<String, dynamic>? data =
          configDoc.data() as Map<String, dynamic>?;

      if (data == null) return VersionStatus.upToDate;

      // Check for maintenance mode first
      if (data['maintenance_mode'] == true) {
        return VersionStatus.maintenanceMode;
      }

      final String minVersion = data['min_version'] ?? '0.0.0';

      // 3. Compare Versions
      if (_isVersionLower(currentVersion, minVersion)) {
        return VersionStatus.updateRequired;
      }

      return VersionStatus.upToDate;
    } catch (e) {
      debugPrint('Version Check Error: $e');
      // In case of error (e.g. offline), we usually allow access unless critical
      return VersionStatus.error;
    }
  }

  /// Returns true if [current] is lower than [minimum]
  bool _isVersionLower(String current, String minimum) {
    try {
      List<int> cParts = current.split('.').map(int.parse).toList();
      List<int> mParts = minimum.split('.').map(int.parse).toList();

      // Pad with zeros if lengths differ (e.g. 1.0 vs 1.0.0)
      while (cParts.length < 3) {
        cParts.add(0);
      }
      while (mParts.length < 3) {
        mParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (cParts[i] < mParts[i]) return true;
        if (cParts[i] > mParts[i]) return false;
      }
      return false; // Equal
    } catch (e) {
      debugPrint('Error parsing versions: $e');
      return false;
    }
  }
}
