import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_service.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_html.dart';
import 'native_backup_stub.dart'
    if (dart.library.io) 'native_backup_impl.dart';

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
    final bytes = utf8.encode(json);
    if (kIsWeb) {
      triggerWebDownload(bytes, _backupFileName);
    } else {
      await nativeBackup(bytes, _backupFileName);
    }
  }

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
