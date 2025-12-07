import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> register(
    String email,
    String password,
    String name,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (name != null) await user.updateDisplayName(name);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    // Update Firestore user record as well
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(user.uid).update(updates);
    }

    // Proactive update: Propagate name change to all authored news and comments
    // Proactive update: Propagate name change to all authored news and comments
    if (name != null) {
      // 1. Update authored news
      try {
        final newsQuery = await _db
            .collection('news')
            .where('authorId', isEqualTo: user.uid)
            .get();

        if (newsQuery.docs.isNotEmpty) {
          final batch = _db.batch();
          for (var doc in newsQuery.docs) {
            batch.update(doc.reference, {'authorName': name});
          }
          await batch.commit();
        }
      } catch (e) {
        print('Error updating news authors: $e');
      }

      // 2. Update comments (using collection group)
      try {
        final commentsQuery = await _db
            .collectionGroup('comments')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (commentsQuery.docs.isNotEmpty) {
          final batch = _db.batch();
          for (var doc in commentsQuery.docs) {
            batch.update(doc.reference, {'userName': name});
          }
          await batch.commit();
        }
      } catch (e) {
        print('Error updating comments: $e');
        // This fails if the necessary Composite Index is missing for CollectionGroup queries
        // Instructions: Check debug console for link to create index if this fails.
      }
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
