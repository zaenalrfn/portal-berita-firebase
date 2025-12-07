// lib/services/news_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class NewsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a news document in collection `news`.
  /// Expects `data` to contain fields like:
  /// - title (String)
  /// - content (String)
  /// - authorId (String)
  /// - authorName (String)
  /// - coverUrl (String?) optional (Cloudinary secure_url)
  /// - publicId (String?) optional (Cloudinary public_id if you store it)
  Future<void> createNews(Map<String, dynamic> data) async {
    final id = Uuid().v4();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('news').doc(id).set(data);
  }

  /// Stream all news ordered by createdAt desc (real-time)
  Stream<QuerySnapshot> streamNews() =>
      _db.collection('news').orderBy('createdAt', descending: true).snapshots();

  /// Get news document by id (one-time read)
  Future<DocumentSnapshot> getNewsById(String id) =>
      _db.collection('news').doc(id).get();

  /// Add comment to news subcollection
  Future<void> addComment(String newsId, Map<String, dynamic> comment) async {
    comment['createdAt'] = FieldValue.serverTimestamp();
    await _db
        .collection('news')
        .doc(newsId)
        .collection('comments')
        .add(comment);
  }

  /// Pagination helper: fetch page of news with optional startAfter doc
  Future<QuerySnapshot> fetchNewsPage({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) {
    Query q = _db
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.get();
  }

  /// Delete news document by id.
  /// NOTE: this only deletes the Firestore document. If you uploaded cover to Cloudinary
  /// and stored its `publicId` in the document (e.g. data['publicId']), you should
  /// also call your backend endpoint to delete the Cloudinary resource using Cloudinary Admin API.
  Future<void> deleteNews(String newsId) async {
    await _db.collection('news').doc(newsId).delete();
  }

  /// Optional: update news document (title/content/coverUrl etc.)
  Future<void> updateNews(String newsId, Map<String, dynamic> updates) async {
    // Do NOT overwrite createdAt blindly; only update allowed fields
    if (updates.containsKey('createdAt')) updates.remove('createdAt');
    await _db.collection('news').doc(newsId).update(updates);
  }

  Future<void> deleteComment(String newsId, String commentId) async {
    await _db
        .collection('news')
        .doc(newsId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> updateComment(
    String newsId,
    String commentId,
    String content,
  ) async {
    await _db
        .collection('news')
        .doc(newsId)
        .collection('comments')
        .doc(commentId)
        .update({'content': content});
  }
}
