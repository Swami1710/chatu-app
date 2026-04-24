import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ================= GOOGLE SIGN IN =================
  Future<User?> signInWithGoogle() async {
    try {
      // 🔥 Force account selection (important)
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // ================= BAN SYSTEM =================
  Future<bool> isUserAllowed(String email) async {
    try {
      final doc =
      await _firestore.collection("banned_users").doc(email).get();

      return !doc.exists;
    } catch (e) {
      print("Ban Check Error: $e");
      return true;
    }
  }

  // ================= FIRST TIME CHECK =================
  Future<bool> isFirstTime(User user) async {
    final doc =
    await _firestore.collection('users').doc(user.uid).get();

    return !doc.exists;
  }

  // ================= SAVE USER =================
  Future<void> saveUser(User user) async {
    try {
      String? fcmToken = await _messaging.getToken();

      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "email": user.email,
        "name": user.displayName ?? "",
        "photoUrl": user.photoURL ?? "",
        "isOnline": true,
        "lastSeen": DateTime.now(),
        "fcmToken": fcmToken,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 🔥 Auto update FCM token (very important)
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _firestore.collection('users').doc(user.uid).update({
          "fcmToken": newToken,
        });
      });
    } catch (e) {
      print("Save User Error: $e");
    }
  }

  // ================= ONLINE STATUS =================
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        "isOnline": isOnline,
        "lastSeen": DateTime.now(),
      });
    } catch (e) {
      print("Online Status Error: $e");
    }
  }

  // ================= INIT PRESENCE TRACKING =================
  Future<void> initPresence() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 🔥 Set online when app starts
    await updateOnlineStatus(true);

    // 🔥 When app closes → offline
    _auth.userChanges().listen((user) {
      if (user == null) {
        updateOnlineStatus(false);
      }
    });
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      await updateOnlineStatus(false);
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print("Logout Error: $e");
    }
  }
}