import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkService _service = BookmarkService();
  String? uid;
  List<String> _bookmarkedIds = [];
  List<String> get bookmarkedIds => _bookmarkedIds;
  StreamSubscription? _sub;

  void setUid(String? u) {
    uid = u;
    _sub?.cancel();
    _bookmarkedIds = [];
    if (uid != null) {
      _sub = _service.streamBookmarks(uid!).listen((snap) {
        _bookmarkedIds = snap.docs.map((d) => d.id).toList();
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String newsId, Map<String, dynamic> meta) async {
    if (uid == null) throw Exception('Not authenticated');
    final isBook = _bookmarkedIds.contains(newsId);
    if (isBook) {
      await _service.removeBookmark(uid!, newsId);
    } else {
      await _service.addBookmark(uid!, newsId, meta);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
