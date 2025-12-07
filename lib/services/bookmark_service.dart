import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addBookmark(
    String uid,
    String newsId,
    Map<String, dynamic> meta,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(newsId)
        .set({
          'newsId': newsId,
          'meta': meta,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> removeBookmark(String uid, String newsId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(newsId)
        .delete();
  }

  Stream<QuerySnapshot> streamBookmarks(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> isBookmarked(String uid, String newsId) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(newsId)
        .get();
    return doc.exists;
  }
}
