import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/bookmark_provider.dart';

class BookmarksPage extends StatelessWidget {
  String _formatTimeAgo(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is Timestamp) {
      dt = date.toDate();
    } else if (date is DateTime) {
      dt = date;
    } else {
      return '';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return DateFormat('MMM dd').format(dt);
    } else if (diff.inDays >= 1) {
      return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays} days ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bookmarkProv = Provider.of<BookmarkProvider>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Saved'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(child: Text('Login to view saved articles')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Saved Articles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.id)
            .collection('bookmarks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return Center(
              child: Text(
                'No bookmarks yet',
                style: TextStyle(color: Colors.grey),
              ),
            );

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            separatorBuilder: (c, i) =>
                Divider(height: 24, color: Colors.grey.shade100),
            itemBuilder: (c, i) {
              final d = docs[i];
              final meta =
                  d.data()
                      as Map<String, dynamic>; // This calls Object? cast map
              final Map<String, dynamic> data =
                  meta; // Explicit cast if needed or directly use meta if typed.
              // data usually has: title, coverUrl, authorName, createdAt (from when bookmarked or original? usually we store basic meta)
              // We might want to fetch fresh data to be safe, but UI relies on meta for speed.
              // The original implementation fetched news document. Let's do that to ensure data freshness
              // BUT to match the swift UI in mockup, using stored meta is faster.
              // However, if we want to be robust against deleted news, we should check existence.
              // The previous code did a FutureBuilder. Let's keep that pattern but style significantly better.
              // Actually, ListViews with FutureBuilders can be jumpy.
              // Better to use the meta we stored in the bookmark which is fast.
              // If we really want fresh data, we'd need a more complex setup.
              // Let's stick to the stored meta for instant generic UI, but maybe a background check?
              // The previous code had a "News deleted" cleanup. That is valuable.

              final newsId = d.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('news')
                    .doc(newsId)
                    .get(),
                builder: (context, newsSnap) {
                  // While loading, use existing meta if available
                  if (!newsSnap.hasData && data.isEmpty)
                    return SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );

                  Map<String, dynamic> displayData = data;
                  bool exists = true;

                  if (newsSnap.hasData) {
                    if (!newsSnap.data!.exists) {
                      exists = false;
                      // Auto-cleanup?
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        bookmarkProv.toggleBookmark(newsId, {});
                      });
                      return SizedBox();
                    } else {
                      // Use fresh data
                      displayData =
                          newsSnap.data!.data() as Map<String, dynamic>;
                    }
                  }

                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: {'id': newsId},
                    ),
                    child: _buildBookmarkItem(
                      context,
                      displayData,
                      newsId,
                      bookmarkProv,
                      displayData['createdAt'],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookmarkItem(
    BuildContext context,
    Map<String, dynamic> data,
    String newsId,
    BookmarkProvider bookmarkProv,
    dynamic date,
  ) {
    return Container(
      color: Colors.transparent, // For hit testing
      height: 90, // Fixed height for consistent look like mockup
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
              image:
                  (data['coverUrl'] != null &&
                      (data['coverUrl'] as String).isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(data['coverUrl']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                (data['coverUrl'] == null ||
                    (data['coverUrl'] as String).isEmpty)
                ? Icon(Icons.image, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Tag (Static for now as per plan)
                    Text(
                      'NEWS',
                      style: TextStyle(
                        color: Color(0xFF1E50F8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Title
                    Text(
                      data['title'] ?? 'No Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),

                // Meta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data['authorName'] ?? 'Unknown'} • ${_formatTimeAgo(date)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),

                    // Delete Icon
                    GestureDetector(
                      onTap: () => bookmarkProv.toggleBookmark(newsId, data),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
