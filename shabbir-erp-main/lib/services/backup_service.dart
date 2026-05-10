import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_service.dart';

class BackupService {
  static BackupService? _instance;
  BackupService._();
  static BackupService get instance {
    _instance ??= BackupService._();
    return _instance!;
  }

  static const String _backupFileName = 'shabbir_erp_backup.json';

  // ── Local Backup ──────────────────────────────────────────────────────────

  Future<void> backupToLocalStorage() async {
    final json = await DatabaseService.instance.exportToJson();
    if (kIsWeb) {
      _triggerWebDownload(utf8.encode(json), _backupFileName);
      return;
    }
    await _backupNative(json);
  }

  Future<void> _backupNative(String json) async {
    throw UnsupportedError('Native backup not available in this environment');
  }

  Future<bool> localBackupExists() async => false;

  Future<void> restoreFromJson(String json) async {
    await DatabaseService.instance.importFromJson(json);
  }

  // ── Google Drive Backup ───────────────────────────────────────────────────

  Future<void> backupToGoogleDrive() async {
    throw UnsupportedError('Google Drive backup requires native platform');
  }

  Future<void> restoreFromGoogleDrive() async {
    throw UnsupportedError('Google Drive restore requires native platform');
  }
}

void _triggerWebDownload(List<int> bytes, String filename) {
}
