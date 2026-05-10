import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loadingGoogle = false;
  bool _loadingPhone = false;
  bool _showOtp = false;
  String _verificationId = '';
  final _phoneController = TextEditingController(text: '+92');
  final _otpController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result != null && mounted) widget.onLogin();
    } catch (e) {
      setState(
        () => _error =
            'Google sign-in failed. Check Firebase setup or use Offline Mode.',
      );
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number with country code');
      return;
    }
    setState(() {
      _loadingPhone = true;
      _error = null;
    });
    try {
      await AuthService.instance.verifyPhone(
        phoneNumber: phone,
        onAutoVerified: (credential) async {
          await AuthService.instance.signInWithOtp(
            verificationId: _verificationId,
            otp: credential.smsCode ?? '',
          );
          if (mounted) widget.onLogin();
        },
        onFailed: (e) => setState(() {
          _error = e.code == 'not-configured'
              ? 'Firebase not set up yet — use Offline Mode below.'
              : (e.message ?? 'Verification failed');
          _loadingPhone = false;
        }),
        onCodeSent: (id, _) => setState(() {
          _verificationId = id;
          _showOtp = true;
          _loadingPhone = false;
        }),
        onTimeout: (_) => setState(() {
          _error = 'OTP timeout — please try again';
          _loadingPhone = false;
        }),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingPhone = false;
      });
    }
  }

  Future<void> _useOfflineMode() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Enter Your Name',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.of(context).pop(name);
            },
            child: Text(
              'Continue',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      widget.onLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'S',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Shabbir Ledger',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  letterSpacing: -0.8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Business accounting made simple.\nSign in to access your data.',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // ── Offline Mode notice (shown when Firebase not configured) ──
              if (!firebaseReady)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Firebase not configured yet',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You can still use all ERP features in Offline Mode. Follow FIREBASE_SETUP.md to enable Google login later.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.destructive.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_showOtp) ...[
                // OTP input
                Text(
                  'Enter the 6-digit code sent to ${_phoneController.text}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white30,
                        letterSpacing: 8,
                        fontSize: 22,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PrimaryBtn(
                  label: 'Verify OTP',
                  loading: _loadingPhone,
                  onPress: _verifyOtp,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showOtp = false;
                      _otpController.clear();
                      _error = null;
                    }),
                    child: Text(
                      '← Change phone number',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Phone input
                Text(
                  'Phone Number',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: '+92 300 0000000',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PrimaryBtn(
                  label: 'Send OTP',
                  loading: _loadingPhone,
                  onPress: _sendOtp,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.2)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loadingGoogle ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _loadingGoogle
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'G',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                          ),
                    label: Text(
                      'Continue with Google',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],

              // ── Offline Mode bypass ──────────────────────────────────────
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _useOfflineMode(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.offline_bolt_outlined,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Use Offline (No Login)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPress;

  const _PrimaryBtn({
    required this.label,
    required this.loading,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
