import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:google_sign_in/google_sign_in.dart';

  // Web OAuth client ID (also used as serverClientId on Android to get idToken)
  const _webClientId =
      '533290517471-nha8kqm8p92qb1dfpd81tajc7oqbgmmi.apps.googleusercontent.com';

  /// Safe wrapper around Firebase Auth.
  /// All methods are no-ops when Firebase is not initialised.
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
        return GoogleSignIn(
          // On web: clientId is required.
          // On Android: serverClientId is required to get an idToken for Firebase.
          clientId: kIsWeb ? _webClientId : null,
          serverClientId: kIsWeb ? null : _webClientId,
          scopes: ['email', 'profile'],
        );
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

    // -- Google Sign In
    Future<UserCredential?> signInWithGoogle() async {
      final auth = _safeAuth();
      final google = _safeGoogle();
      if (auth == null || google == null) {
        throw Exception(
            'Firebase is not configured. Please complete Firebase setup.');
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
        return u?.displayName ?? u?.email ?? 'User';
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

    String? get photoUrl {
      try {
        return currentUser?.photoURL;
      } catch (_) {
        return null;
      }
    }
  }
  