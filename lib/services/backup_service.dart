import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  // Define all the active boxes in the app
  static const List<String> _boxes = [
    'transactions',
    'categories',
    'budgets',
    'accounts',
    'loans',
    'contacts',
    'counters',
    'settings',
    'savings',
  ];

  static Future<bool> createBackup(BuildContext context) async {
    try {
      final backupData = <String, dynamic>{};

      for (var boxName in _boxes) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          final boxData = <dynamic, dynamic>{};
          
          for (var key in box.keys) {
            boxData[key.toString()] = box.get(key);
          }
          backupData[boxName] = boxData;
        } else {
          // If a box is dynamic (using 'Map', 'int' etc.), we need to open it temporarily just to back it up
          // Note: for simplicity in Cash Management, most are opened at initialization so we assume they are open.
          // Fallback logic here if needed.
        }
      }

      final jsonString = jsonEncode(backupData);
      
      final directory = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final File file = File('${directory.path}/cash_management_backup_$dateStr.json');
      
      await file.writeAsString(jsonString);

      // Prompt to save/share the backup file
      await Share.shareXFiles([XFile(file.path)], text: 'Cash Management Backup');
      return true;
    } catch (e) {
      debugPrint('Backup Error: $e');
      return false;
    }
  }

  static Future<bool> restoreBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();
        
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        // Warning: This replaces existing data entirely.
        for (var boxName in _boxes) {
          if (backupData.containsKey(boxName)) {
             Box box;
             if (Hive.isBoxOpen(boxName)) {
               box = Hive.box(boxName);
             } else {
               box = await Hive.openBox(boxName); // dynamic open
             }
             
             await box.clear(); // Clear existing data
             final Map<String, dynamic> boxData = backupData[boxName];
             
             // Put all backed up data back
             for (var entry in boxData.entries) {
               await box.put(entry.key, entry.value);
             }
          }
        }
        return true;
      }
      return false; // User canceled
    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }
}
