import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mess_manager/utils/app_constants.dart';
import 'package:intl/intl.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> createBackup() async {
    try {
      final Map<String, dynamic> backupData = {};

      // 1. Backup Global Collections
      backupData[AppConstants.collectionUsers] = await _getCollectionData(
        AppConstants.collectionUsers,
      );
      backupData[AppConstants.collectionMembers] = await _getCollectionData(
        AppConstants.collectionMembers,
      );

      // 2. Backup Hostels and Subcollections
      final hostelsSnapshot = await _firestore.collection('hostels').get();
      final hostelsData = {};

      for (var doc in hostelsSnapshot.docs) {
        final hostelId = doc.id;
        final hostelMap = doc.data();

        // Backup subcollections for each hostel
        hostelMap['members'] = await _getCollectionData(
          'hostels/$hostelId/members',
        );
        hostelMap['mealEntries'] = await _getCollectionData(
          'hostels/$hostelId/${AppConstants.collectionMealEntries}',
        );
        hostelMap['expenses'] = await _getCollectionData(
          'hostels/$hostelId/${AppConstants.collectionExpenses}',
        );
        hostelMap['contributions'] = await _getCollectionData(
          'hostels/$hostelId/${AppConstants.collectionContributions}',
        );
        hostelMap['marketSchedules'] = await _getCollectionData(
          'hostels/$hostelId/${AppConstants.collectionMarketSchedules}',
        );
        hostelMap['notices'] = await _getCollectionData(
          'hostels/$hostelId/notices',
        );
        hostelMap['feedback'] = await _getCollectionData(
          'hostels/$hostelId/feedback',
        );
        hostelMap['expense_requests'] = await _getCollectionData(
          'hostels/$hostelId/expense_requests',
        );
        hostelMap['messages'] = await _getCollectionData(
          'hostels/$hostelId/messages',
        );

        hostelsData[hostelId] = hostelMap;
      }
      backupData['hostels'] = hostelsData;

      // 3. Save to File
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final filename = 'backup_$timestamp.json';
      final file = File('${directory.path}/$filename');

      // Convert to JSON with custom encoder for Timestamps
      final jsonString = jsonEncode(backupData, toEncodable: _customEncoder);
      await file.writeAsString(jsonString);

      return filename;
    } catch (e) {
      debugPrint('Backup Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getCollectionData(String path) async {
    final snapshot = await _firestore.collection(path).get();
    final Map<String, dynamic> data = {};
    for (var doc in snapshot.docs) {
      data[doc.id] = doc.data();
    }
    return data;
  }

  Object? _customEncoder(dynamic item) {
    if (item is Timestamp) {
      return {
        '__type__': 'Timestamp',
        'seconds': item.seconds,
        'nanoseconds': item.nanoseconds,
      };
    }
    return item;
  }

  // --- Restore ---

  Future<List<FileSystemEntity>> getBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    return files
        .where(
          (file) =>
              file.path.endsWith('.json') && file.path.contains('backup_'),
        )
        .toList();
  }

  Future<bool> deleteBackup(File file) async {
    try {
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreBackup(File file) async {
    try {
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // 1. Restore Global Collections
      if (backupData.containsKey(AppConstants.collectionUsers)) {
        await _restoreCollection(
          AppConstants.collectionUsers,
          backupData[AppConstants.collectionUsers],
        );
      }
      if (backupData.containsKey(AppConstants.collectionMembers)) {
        await _restoreCollection(
          AppConstants.collectionMembers,
          backupData[AppConstants.collectionMembers],
        );
      }

      // 2. Restore Hostels
      if (backupData.containsKey('hostels')) {
        final Map<String, dynamic> hostelsData = backupData['hostels'];
        for (final hostelId in hostelsData.keys) {
          final Map<String, dynamic> hostelMap = hostelsData[hostelId];

          // Restore Hostel Doc (excluding subcollection keys which are maps)
          final Map<String, dynamic> hostelDocData = {};
          final List<String> subCols = [
            'members',
            'mealEntries',
            'expenses',
            'contributions',
            'marketSchedules',
            'notices',
            'feedback',
            'expense_requests',
            'messages',
          ];

          hostelMap.forEach((key, value) {
            if (!subCols.contains(key)) {
              hostelDocData[key] = _customDecoder(value);
            }
          });

          await _firestore
              .collection('hostels')
              .doc(hostelId)
              .set(hostelDocData);

          // Restore Subcollections
          for (final subCol in subCols) {
            if (hostelMap.containsKey(subCol)) {
              await _restoreCollection(
                'hostels/$hostelId/$subCol',
                hostelMap[subCol],
              );
            }
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }

  Future<void> _restoreCollection(
    String path,
    Map<String, dynamic> data,
  ) async {
    var batch = _firestore.batch();
    int count = 0;

    for (final docId in data.keys) {
      final docData = data[docId] as Map<String, dynamic>;
      final decodedData = docData.map((k, v) => MapEntry(k, _customDecoder(v)));

      final docRef = _firestore.collection(path).doc(docId);
      batch.set(docRef, decodedData);
      count++;

      if (count % 400 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    if (count % 400 != 0) {
      await batch.commit();
    }
  }
}

// Extracted valid decoder for easier reading/writing
dynamic _customDecoder(dynamic item) {
  if (item is Map<String, dynamic> && item['__type__'] == 'Timestamp') {
    return Timestamp(item['seconds'], item['nanoseconds']);
  }
  if (item is List) {
    return item.map((e) => _customDecoder(e)).toList();
  }
  if (item is Map<String, dynamic>) {
    // Recursive for nested maps
    return item.map((k, v) => MapEntry(k, _customDecoder(v)));
  }
  return item;
}
