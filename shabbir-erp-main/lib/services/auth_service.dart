import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Safe wrapper around Firebase Auth.
/// All methods are no-ops when Firebase is not initialised
/// (i.e. when firebaseReady == false in main.dart).
class AuthService {
  static AuthService? _instance;
  AuthService._();
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  FirebaseAuth? _safeAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  GoogleSignIn? _safeGoogle() {
    try {
      return GoogleSignIn();
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _safeAuth()?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _safeAuth()?.authStateChanges() ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    final auth = _safeAuth();
    final google = _safeGoogle();
    if (auth == null || google == null) {
      throw Exception('Firebase is not configured. Please complete FIREBASE_SETUP.md.');
    }
    final googleUser = await google.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await auth.signInWithCredential(credential);
  }

  // ── Phone Sign In ─────────────────────────────────────────────────────────
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onTimeout,
  }) async {
    final auth = _safeAuth();
    if (auth == null) {
      onFailed(FirebaseAuthException(
          code: 'not-configured',
          message: 'Firebase is not configured. Please complete FIREBASE_SETUP.md.'));
      return;
    }
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String otp,
  }) async {
    final auth = _safeAuth();
    if (auth == null) {
      throw Exception('Firebase is not configured.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      final auth = _safeAuth();
      final google = _safeGoogle();
      await Future.wait([
        if (auth != null) auth.signOut(),
        if (google != null) google.signOut(),
      ]);
    } catch (_) {}
  }

  String get displayName {
    try {
      final u = currentUser;
      return u?.displayName ?? u?.phoneNumber ?? u?.email ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  String get email {
    try {
      return currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  String get phoneNumber {
    try {
      return currentUser?.phoneNumber ?? '';
    } catch (_) {
      return '';
    }
  }

  String? get photoUrl {
    try {
      return currentUser?.photoURL;
    } catch (_) {
      return null;
    }
  }
}
