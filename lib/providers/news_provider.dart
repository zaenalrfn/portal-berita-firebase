import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_model.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _service = NewsService();

  // stream for realtime initial (optional)
  Stream<QuerySnapshot> get newsStream => _service.streamNews();

  // pagination
  List<News> items = [];
  bool hasMore = true;
  bool loading = false;
  final int pageSize = 10;
  DocumentSnapshot? lastDoc;

  Future<void> fetchFirstPage() async {
    items = [];
    hasMore = true;
    lastDoc = null;
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (!hasMore || loading) return;
    loading = true;
    notifyListeners();
    final snap = await _service.fetchNewsPage(
      limit: pageSize,
      startAfter: lastDoc,
    );
    final docs = snap.docs;
    if (docs.length < pageSize) hasMore = false;
    if (docs.isNotEmpty) {
      lastDoc = docs.last;
      items.addAll(
        docs.map((d) => News.fromMap(d.id, d.data() as Map<String, dynamic>)),
      );
    }
    loading = false;
    notifyListeners();
  }

  Future<void> createNews(Map<String, dynamic> data) async {
    await _service.createNews(data);
    await fetchFirstPage(); // refresh
  }

  final CloudinaryService _cloudinary = CloudinaryService(
    cloudName: 'diyahzjpz',
    uploadPreset: 'unsigned_preset',
    apiKey: '627376456298499',
    apiSecret: '4z2kjd-qtzOI2cvA695-SuFTy0I',
  );

  Future<void> deleteNews(String id) async {
    // 1. Get the doc to find coverUrl
    final newsItem = items.firstWhere(
      (d) => d.id == id,
      orElse: () => throw 'News not found locally',
    );
    final coverUrl = newsItem.coverUrl;

    // 2. Delete from Cloudinary if exists
    if (coverUrl != null) {
      final publicId = _getPublicIdFromUrl(coverUrl);
      if (publicId != null) {
        await _cloudinary.deleteImage(publicId);
      }
    }

    // 3. Delete from Firestore
    await _service.deleteNews(id);

    // 4. Proactive: Delete from current user's bookmarks (for realtime effect)
    // We assume the current user is the one deleting (author), so we remove it from their bookmarks too.
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookmarks')
            .doc(id)
            .delete();
      }
    } catch (e) {
      print('Error deleting bookmark: $e');
    }

    items.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }

  Future<void> updateNews(String id, Map<String, dynamic> data) async {
    // Check if image is changing
    // We must fetch the current doc from Firestore because 'items' might not contain it
    // (if we are in MyNewsPage which uses a separate stream)
    try {
      final oldDoc = await _service.getNewsById(id);
      if (oldDoc.exists) {
        final oldData = oldDoc.data() as Map<String, dynamic>;
        final oldUrl = oldData['coverUrl'] as String?;
        final newUrl = data['coverUrl'] as String?;

        if (oldUrl != null && newUrl != null && oldUrl != newUrl) {
          // Image changed, delete old one
          final publicId = _getPublicIdFromUrl(oldUrl);
          if (publicId != null) {
            await _cloudinary.deleteImage(publicId);
          }
        }
      }
    } catch (e) {
      print('Error handling outdated image deletion: $e');
    }

    await _service.updateNews(id, data);

    // Refresh list locally or fetch again
    final index = items.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      // Ideally we re-fetch, but for simplicity we rely on next refresh or just handle standard stream if used
      // Since main feed uses pagination provider, we might need manual update or just re-fetch
    }
    await fetchFirstPage();
  }

  String? _getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments;
      // Simple parsing strategy for Cloudinary URLs
      final uploadIndex = path.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= path.length) return null;

      var parts = path.sublist(uploadIndex + 1);
      if (parts.isNotEmpty && parts[0].startsWith('v')) {
        parts = parts.sublist(1); // skip version
      }

      final publicIdWithExt = parts.join('/');
      final lastDot = publicIdWithExt.lastIndexOf('.');
      if (lastDot != -1) {
        return publicIdWithExt.substring(0, lastDot);
      }
      return publicIdWithExt;
    } catch (e) {
      print('Error parsing publicId: $e');
      return null;
    }
  }

  Future<void> addComment(String newsId, Map<String, dynamic> comment) =>
      _service.addComment(newsId, comment);

  Future<void> deleteComment(String newsId, String commentId) =>
      _service.deleteComment(newsId, commentId);

  Future<void> updateComment(String newsId, String commentId, String content) =>
      _service.updateComment(newsId, commentId, content);
}
