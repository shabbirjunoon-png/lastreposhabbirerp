import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:provider/provider.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../app_config.dart';
  import '../constants/app_colors.dart';
  import '../providers/erp_provider.dart';
  import '../services/auth_service.dart';
  import '../services/backup_service.dart';
  import '../services/security_service.dart';
  import '../widgets/app_header.dart';
  import 'pattern_lock_screen.dart';

  class SettingsScreen extends StatefulWidget {
    final VoidCallback onLogout;
    const SettingsScreen({super.key, required this.onLogout});
    @override
    State<SettingsScreen> createState() => _SettingsScreenState();
  }

  class _SettingsScreenState extends State<SettingsScreen> {
    bool _patternEnabled = false;
    bool _loadingBackupLocal = false;
    bool _loadingRestoreLocal = false;
    bool _loadingBackupDrive = false;
    bool _loadingRestoreDrive = false;
    bool _loadingLogout = false;
    String _offlineName = 'Offline User';

    @override
    void initState() { super.initState(); _loadSettings(); }

    Future<void> _loadSettings() async {
      final enabled = await SecurityService.instance.isPatternEnabled();
      final hasPattern = await SecurityService.instance.hasPatternSet();
      final prefs = await SharedPreferences.getInstance();
      final offlineName = prefs.getString('user_name') ?? 'Offline User';
      if (mounted) setState(() { _patternEnabled = enabled && hasPattern; _offlineName = offlineName; });
    }

    Future<void> _togglePattern() async {
      if (_patternEnabled) {
        final verified = await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PatternLockScreen(mode: PatternLockMode.verify, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false))));
        if (verified == true) { await SecurityService.instance.disablePattern(); if (mounted) setState(() => _patternEnabled = false); _snack('Pattern lock disabled'); }
      } else {
        final set = await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PatternLockScreen(mode: PatternLockMode.set, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false))));
        if (set == true) { if (mounted) setState(() => _patternEnabled = true); _snack('Pattern lock enabled'); }
      }
    }

    Future<void> _changePattern() async {
      final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PatternLockScreen(mode: PatternLockMode.change, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false))));
      if (changed == true) _snack('Pattern changed successfully');
    }

    Future<void> _backupLocal() async {
      setState(() => _loadingBackupLocal = true);
      try { await BackupService.instance.backupToLocalStorage(); _snack('Backup tayyar hai — share karo ya save karo'); }
      catch (e) { _snack('Backup failed: $e', error: true); }
      finally { if (mounted) setState(() => _loadingBackupLocal = false); }
    }

    Future<void> _restoreLocal() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Restore from Device?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text('Backup JSON file select karo. Ye action current data ko REPLACE kar dega.\n\nYe undo nahi hoga.', style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Restore', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ) ?? false;
      if (!confirm) return;
      setState(() => _loadingRestoreLocal = true);
      try {
        final success = await BackupService.instance.restoreFromLocalFile();
        if (!success) { _snack('Koi file select nahi ki'); return; }
        if (mounted) await context.read<ERPProvider>().reload();
        _snack('Data restore ho gaya backup file se');
      } catch (e) {
        _snack('Restore failed: ${e.toString().replaceAll("Exception:", "").trim()}', error: true);
      } finally { if (mounted) setState(() => _loadingRestoreLocal = false); }
    }

    Future<void> _backupDrive() async {
      if (!firebaseReady) { _snack('Google Drive backup requires Firebase setup', error: true); return; }
      setState(() => _loadingBackupDrive = true);
      try { await BackupService.instance.backupToGoogleDrive(); _snack('Backed up to Google Drive successfully'); }
      catch (e) { _snack('Drive backup failed: ${e.toString().replaceAll("Exception:", "").trim()}', error: true); }
      finally { if (mounted) setState(() => _loadingBackupDrive = false); }
    }

    Future<void> _restoreDrive() async {
      if (!firebaseReady) { _snack('Google Drive restore requires Firebase setup', error: true); return; }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Restore from Google Drive?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text('This will REPLACE all current data with the backup from Google Drive.\n\nThis cannot be undone.', style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Restore', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ) ?? false;
      if (!confirm) return;
      setState(() => _loadingRestoreDrive = true);
      try { await BackupService.instance.restoreFromGoogleDrive(); if (mounted) await context.read<ERPProvider>().reload(); _snack('Data restored from Google Drive'); }
      catch (e) { _snack('Restore failed: ${e.toString().replaceAll("Exception:", "").trim()}', error: true); }
      finally { if (mounted) setState(() => _loadingRestoreDrive = false); }
    }

    Future<void> _logout() async {
      if (!firebaseReady) { _snack('Running in offline mode — no account to sign out of.'); return; }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Sign out?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text('You will need to sign in again to access your data.', style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ) ?? false;
      if (!confirm) return;
      setState(() => _loadingLogout = true);
      try { await AuthService.instance.signOut(); if (mounted) widget.onLogout(); }
      finally { if (mounted) setState(() => _loadingLogout = false); }
    }

    void _snack(String msg, {bool error = false}) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
        backgroundColor: error ? AppColors.destructive : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }

    void _showAboutDialog(BuildContext context) {
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('About Shabbir ERP', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Powered by Shabbir Ahmed.\n\nThis app is totally AI-generated.', style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close', style: GoogleFonts.inter()))],
      ));
    }

    @override
    Widget build(BuildContext context) {
      final isOffline = !firebaseReady;
      final user = isOffline ? null : AuthService.instance.currentUser;
      final name = isOffline ? _offlineName : AuthService.instance.displayName;
      final identifier = isOffline ? 'Firebase not configured — see FIREBASE_SETUP.md' : (user?.email ?? user?.phoneNumber ?? '');
      final photoUrl = isOffline ? null : AuthService.instance.photoUrl;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(children: [
          const AppHeader(title: 'Settings', subtitle: 'Account, security & data'),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            children: [
              if (isOffline) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.offline_bolt_outlined, size: 20, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Running in Offline Mode', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.foreground)),
                      const SizedBox(height: 2),
                      Text('All data is saved locally. Complete FIREBASE_SETUP.md to enable cloud sync.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground, height: 1.4)),
                    ])),
                  ]),
                ),
              ],
              _SectionLabel('Account'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(color: isOffline ? AppColors.secondary : AppColors.primary, borderRadius: BorderRadius.circular(15)),
                    child: photoUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarLetter(name, isOffline)))
                        : _avatarLetter(name, isOffline),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                    if (identifier.isNotEmpty) Text(identifier, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11.5, color: AppColors.mutedForeground, height: 1.4), maxLines: 2),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: isOffline ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                    child: Text(isOffline ? 'Offline' : 'Signed In', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: isOffline ? const Color(0xFFD97706) : AppColors.success)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Security'),
              _Tile(icon: Icons.grid_view_outlined, title: 'Pattern Lock', subtitle: _patternEnabled ? 'App locks when opened — tap to disable' : 'Disabled — tap to enable', trailing: Switch(value: _patternEnabled, onChanged: (_) => _togglePattern(), activeColor: AppColors.primary)),
              if (_patternEnabled) _Tile(icon: Icons.refresh_outlined, title: 'Change Pattern', subtitle: 'Draw a new unlock pattern', onTap: _changePattern),
              const SizedBox(height: 24),
              _SectionLabel('Data Management'),
              _Tile(icon: Icons.phone_android_outlined, title: 'Backup to Device', subtitle: 'Save a .json file to your phone storage', loading: _loadingBackupLocal, onTap: _backupLocal),
              _Tile(icon: Icons.folder_open_outlined, title: 'Restore from Device', subtitle: 'Device se backup .json file select karo', loading: _loadingRestoreLocal, onTap: _restoreLocal),
              _Tile(icon: Icons.backup_outlined, title: 'Backup to Google Drive', subtitle: isOffline ? 'Requires Firebase setup' : 'Upload data to your Google Drive folder "ShabbirERP"', loading: _loadingBackupDrive, onTap: _backupDrive, dimmed: isOffline),
              _Tile(icon: Icons.restore_outlined, title: 'Restore from Google Drive', subtitle: isOffline ? 'Requires Firebase setup' : 'Download & replace all data from the last Drive backup', loading: _loadingRestoreDrive, onTap: _restoreDrive, dimmed: isOffline),
              const SizedBox(height: 24),
              _SectionLabel('Account Actions'),
              _Tile(icon: Icons.logout, title: isOffline ? 'Offline Mode' : 'Sign Out', subtitle: isOffline ? 'No account — complete Firebase setup to enable login' : 'Logout from your account', destructive: !isOffline, dimmed: isOffline, loading: _loadingLogout, onTap: _logout),
              const SizedBox(height: 36),
              _SectionLabel('About'),
              _Tile(icon: Icons.info_outline, title: 'About Shabbir ERP', subtitle: 'Powered by Shabbir Ahmed. This app is totally AI-generated.', onTap: () => _showAboutDialog(context)),
              const SizedBox(height: 12),
              Center(child: Text('Shabbir ERP  v1.0.0', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground))),
            ],
          )),
        ]),
      );
    }

    Widget _avatarLetter(String name, bool isOffline) => Center(child: Icon(isOffline ? Icons.offline_bolt_outlined : Icons.person, color: isOffline ? AppColors.mutedForeground : AppColors.accent, size: 26));
  }

  class _SectionLabel extends StatelessWidget {
    final String label;
    const _SectionLabel(this.label);
    @override
    Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.mutedForeground, letterSpacing: 0.8)),
    );
  }

  class _Tile extends StatelessWidget {
    final IconData icon;
    final String title;
    final String subtitle;
    final Widget? trailing;
    final VoidCallback? onTap;
    final bool destructive;
    final bool loading;
    final bool dimmed;

    const _Tile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap, this.destructive = false, this.loading = false, this.dimmed = false});

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Opacity(
          opacity: dimmed ? 0.5 : 1.0,
          child: GestureDetector(
            onTap: loading ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: destructive ? const Color(0xFFFEE2E2) : AppColors.secondary, borderRadius: BorderRadius.circular(11)),
                  child: loading
                      ? Padding(padding: const EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: destructive ? AppColors.destructive : AppColors.primary))
                      : Icon(icon, size: 18, color: destructive ? AppColors.destructive : AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: destructive ? AppColors.destructive : AppColors.foreground)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.mutedForeground), maxLines: 2),
                ])),
                if (trailing != null) trailing!
                else if (onTap != null && !loading) Icon(Icons.chevron_right, size: 18, color: destructive ? AppColors.destructive : AppColors.mutedForeground),
              ]),
            ),
          ),
        ),
      );
    }
  }
  