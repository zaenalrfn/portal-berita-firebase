import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../models/user_model.dart';
import '../providers/bookmark_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  AppUser? user;

  AuthProvider() {
    _service.authStateChanges().listen((u) async {
      if (u != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(u.uid)
              .get();
          if (doc.exists) {
            user = AppUser.fromMap(u.uid, doc.data() as Map<String, dynamic>);
          } else {
            // Fallback if firestore doc missing but auth exists
            user = AppUser(
              id: u.uid,
              name: u.displayName ?? 'No Name',
              email: u.email ?? '',
              photoUrl: u.photoURL,
            );
          }
        } catch (e) {
          print("Error fetching user profile: $e");
          user = AppUser(
            id: u.uid,
            name: u.displayName ?? 'No Name',
            email: u.email ?? '',
            photoUrl: u.photoURL,
          );
        }
      } else {
        user = null;
      }
      notifyListeners();
    });
  }

  bool get isAuthenticated => user != null;

  Future<void> login(String email, String password) async {
    await _service.login(email, password);
  }

  Future<void> register(String email, String password, String name) async {
    await _service.register(email, password, name);
  }

  Future<void> logout() async {
    await _service.logout();
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    await _service.updateProfile(name: name, photoUrl: photoUrl);
    // Reload local user data
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.id)
          .get();
      if (doc.exists) {
        user = AppUser.fromMap(user!.id, doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _service.updatePassword(newPassword);
  }

  Future<void> reauthenticate(String password) async {
    await _service.reauthenticate(password);
  }

  Future<void> resetPassword(String email) async {
    await _service.sendPasswordResetEmail(email);
  }
}
