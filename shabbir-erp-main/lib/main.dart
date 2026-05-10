import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'providers/erp_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/pattern_lock_screen.dart';
import 'services/auth_service.dart';
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialise Firebase — placeholder credentials will throw, which
  // we catch so the rest of the app (storage, PDF, etc.) still works fine.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  // Portrait lock only on mobile — not supported on web
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(const ShabbirERP());
}

class ShabbirERP extends StatelessWidget {
  const ShabbirERP({super.key});

  @override
  Widget build(BuildContext context) {
    final interTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return ChangeNotifierProvider(
      create: (_) => ERPProvider()..load(),
      child: MaterialApp(
        title: 'Shabbir ERP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: interTheme,
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.tint,
            surface: AppColors.card,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.foreground,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.foreground,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.foreground),
          ),
        ),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _loading = true;
  bool _isLoggedIn = false;
  bool _needsPattern = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();

    // If Firebase never initialised, skip auth entirely — go straight to app.
    if (!firebaseReady) {
      setState(() {
        _isLoggedIn = true;
        _needsPattern = false;
        _loading = false;
      });
      return;
    }

    // If user previously chose Offline Mode, restore that session.
    final offlineSession = prefs.getBool('offline_logged_in') ?? false;
    if (offlineSession) {
      final patternEnabled = await SecurityService.instance.isPatternEnabled();
      final hasPattern = await SecurityService.instance.hasPatternSet();
      setState(() {
        _isLoggedIn = true;
        _needsPattern = patternEnabled && hasPattern;
        _loading = false;
      });
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoggedIn = false;
        _loading = false;
      });
      return;
    }

    final patternEnabled = await SecurityService.instance.isPatternEnabled();
    final hasPattern = await SecurityService.instance.hasPatternSet();
    setState(() {
      _isLoggedIn = true;
      _needsPattern = patternEnabled && hasPattern;
      _loading = false;
    });
  }

  void _onLogin() {
    setState(() {
      _isLoggedIn = true;
      _needsPattern = false;
      _loading = false;
    });
  }

  void _onLogout() {
    // Clear offline session flag so the user returns to the login screen.
    SharedPreferences.getInstance().then((p) => p.remove('offline_logged_in'));
    if (!firebaseReady) {
      setState(() {
        _isLoggedIn = false;
        _needsPattern = false;
        _loading = false;
      });
      return;
    }
    setState(() {
      _isLoggedIn = false;
      _needsPattern = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('S',
                  style: GoogleFonts.inter(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.accent),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _onLogin);
    }

    if (_needsPattern) {
      return PatternLockScreen(
        mode: PatternLockMode.verify,
        onSuccess: () => setState(() => _needsPattern = false),
      );
    }

    return MainScreen(onLogout: _onLogout);
  }
}
