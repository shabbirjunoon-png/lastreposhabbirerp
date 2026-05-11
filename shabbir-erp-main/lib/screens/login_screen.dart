import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../app_config.dart';
  import '../constants/app_colors.dart';
  import '../services/auth_service.dart';
  import '../widgets/app_header.dart';

  class LoginScreen extends StatefulWidget {
    final VoidCallback onLogin;
    const LoginScreen({super.key, required this.onLogin});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
    bool _loadingGoogle = false;
    String? _error;

    Future<void> _signInWithGoogle() async {
      setState(() { _loadingGoogle = true; _error = null; });
      try {
        final result = await AuthService.instance.signInWithGoogle();
        if (result != null && mounted) widget.onLogin();
      } catch (e) {
        setState(() { _error = 'Google sign-in failed. Check internet connection or use Offline Mode.'; });
      } finally {
        if (mounted) setState(() => _loadingGoogle = false);
      }
    }

    Future<void> _useOfflineMode() async {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name') ?? '';
      if (savedName.isNotEmpty) {
        await prefs.setBool('offline_logged_in', true);
        if (mounted) widget.onLogin();
        return;
      }
      final nameController = TextEditingController();
      if (!mounted) return;
      final name = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Apna naam likho', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Offline mode mein data sirf is phone par save hoga.', style: GoogleFonts.inter(fontSize: 13, color: Colors.white60, height: 1.5)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Jaise: Shabbir Ahmed',
                  hintStyle: GoogleFonts.inter(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Wapas', style: GoogleFonts.inter(color: Colors.white54))),
            ElevatedButton(
              onPressed: () { final n = nameController.text.trim(); if (n.isNotEmpty) Navigator.of(context).pop(n); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              child: Text('Jari rakho', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        await prefs.setString('user_name', name);
        await prefs.setBool('offline_logged_in', true);
        if (mounted) widget.onLogin();
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  ShabbirLogo(size: 72, bgColor: AppColors.accent, textColor: AppColors.primary, badgeColor: AppColors.primary),
                  const SizedBox(height: 24),
                  Text('Shabbir Ledger', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 34, letterSpacing: -1.0, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Business accounting made simple.', style: GoogleFonts.inter(fontSize: 15, color: Colors.white54, height: 1.5)),
                  const SizedBox(height: 52),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.destructive.withOpacity(0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.destructive.withOpacity(0.4))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 18, color: Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.4))),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (firebaseReady) ...[
                    _SectionLabel('Google account se login karo'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _loadingGoogle ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), disabledBackgroundColor: Colors.white38),
                        icon: _loadingGoogle
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4285F4)))
                            : Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle), child: Center(child: Text('G', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)))),
                        label: Text('Continue with Google', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1A1A2E))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _OrDivider(),
                    const SizedBox(height: 20),
                  ],
                  _SectionLabel('Bina internet ke use karo'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _useOfflineMode,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: AppColors.accent.withOpacity(0.7), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.offline_bolt_outlined, size: 20, color: AppColors.accent),
                      label: Text('Offline Mode mein chalao', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.white38),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Offline mode mein sab features kaam karte hain. Data sirf is phone par save hoga. Settings mein jaake backup le lo aur restore kar sakte ho.', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, height: 1.6))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  class _SectionLabel extends StatelessWidget {
    final String text;
    const _SectionLabel(this.text);
    @override
    Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white54));
  }

  class _OrDivider extends StatelessWidget {
    @override
    Widget build(BuildContext context) => Row(children: [
      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('ya phir', style: GoogleFonts.inter(fontSize: 12, color: Colors.white30))),
      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
    ]);
  }
  