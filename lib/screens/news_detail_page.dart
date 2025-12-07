import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/news_provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/auth_dialog.dart';

class NewsDetailPage extends StatefulWidget {
  final String newsId;
  NewsDetailPage({required this.newsId});

  @override
  _NewsDetailPageState createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool _showAllComments = false;

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return '';
  }

  String _formatTimeAgo(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      final now = DateTime.now();
      final diff = now.difference(date.toDate());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM dd').format(date.toDate());
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bookmarkProv = Provider.of<BookmarkProvider>(context);
    final newsRef = FirebaseFirestore.instance
        .collection('news')
        .doc(widget.newsId);
    final isBookmarked = bookmarkProv.bookmarkedIds.contains(widget.newsId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.blue : Colors.black,
            ),
            onPressed: () async {
              if (!auth.isAuthenticated) {
                showDialog(context: context, builder: (_) => AuthDialog());
                return;
              }
              // We need to fetch data to save bookmark meta
              // Optimistic toggle is handled by provider but we need data for first add
              // For simplicity, we'll let the provider handle fetch or pass current data if available
              // But here we might not have data readily available in a variable outside StreamBuilder.
              // So we will handle it inside the StreamBuilder or fetch it.
              // Actually, best to pass the data from the stream.
              // Since we are outside stream, we can't fully support "add" with meta here
              // UNLESS we used a ValueNotifier or similar.
              // However, simpler approach: The API requires meta.
              // Let's wrapping the Icon in the StreamBuilder is better or fetching once.
              // But AppBar is outside body.
              // We will handle it by fetching snapshot.
              final doc = await newsRef.get();
              if (doc.exists) {
                final data = doc.data() as Map<String, dynamic>;
                await bookmarkProv.toggleBookmark(widget.newsId, data);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: newsRef.snapshots(),
        builder: (c, s) {
          if (!s.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final data = s.data!.data() as Map<String, dynamic>?;
          if (data == null) return Center(child: Text("News not found"));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                // Hero Image
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    image:
                        (data['coverUrl'] != null &&
                            data['coverUrl'].isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(data['coverUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (data['coverUrl'] == null || data['coverUrl'].isEmpty)
                      ? Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _formatDate(data['createdAt']),
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Author Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                null, // No author photo in news model yet, keeping generic
                            child: Icon(Icons.person, color: Colors.grey),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['authorName'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Author', // Static role as per request/mockup limitation
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Content
                      Text(
                        data['content'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 30),

                      Divider(height: 1),
                      SizedBox(height: 24),

                      // Comments Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Comment Input
                      auth.isAuthenticated
                          ? _CommentInput(newsId: widget.newsId)
                          : GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => AuthDialog(),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Login to share your thoughts...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                      SizedBox(height: 24),

                      // Comments List
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('news')
                            .doc(widget.newsId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (c, s) {
                          if (!s.hasData) return SizedBox();
                          final docs = s.data!.docs;
                          final count = docs.length;
                          final visibleDocs = _showAllComments
                              ? docs
                              : docs.take(3).toList();

                          if (count == 0) {
                            return Text(
                              'No comments yet.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...visibleDocs.map((d) {
                                final m = d.data() as Map<String, dynamic>;
                                final isOwner =
                                    auth.isAuthenticated &&
                                    auth.user!.id == m['userId'];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.purple.shade100,
                                        child: Text(
                                          (m['userName'] ?? 'A')[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  m['userName'] ?? 'Anonymous',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      _formatTimeAgo(
                                                        m['createdAt'],
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    if (isOwner) ...[
                                                      SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _showEditDialog(
                                                              context,
                                                              widget.newsId,
                                                              d.id,
                                                              m['content'],
                                                            ),
                                                        child: Icon(
                                                          Icons.edit,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _deleteComment(
                                                              context,
                                                              widget.newsId,
                                                              d.id,
                                                            ),
                                                        child: Icon(
                                                          Icons.delete,
                                                          size: 14,
                                                          color:
                                                              Colors.red[300],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              m['content'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[800],
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              if (count > 3 && !_showAllComments)
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        setState(() => _showAllComments = true),
                                    child: Text('View all $count comments'),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String newsId,
    String commentId,
    String currentContent,
  ) {
    final ctrl = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Comment'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: 'Content'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NewsProvider>(
                context,
                listen: false,
              ).updateComment(newsId, commentId, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(BuildContext context, String newsId, String commentId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NewsProvider>(
                context,
                listen: false,
              ).deleteComment(newsId, commentId);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatefulWidget {
  final String newsId;
  _CommentInput({required this.newsId});
  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final newsProv = Provider.of<NewsProvider>(context, listen: false);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          SizedBox(width: 12),
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              (auth.user?.name ?? 'U')[0].toUpperCase(),
              style: TextStyle(fontSize: 10, color: Colors.blue),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              style: TextStyle(fontSize: 13),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          IconButton(
            icon: _submitting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
            onPressed: _submitting
                ? null
                : () async {
                    final content = _ctrl.text.trim();
                    if (content.isEmpty) return;
                    setState(() => _submitting = true);
                    await newsProv.addComment(widget.newsId, {
                      'userId': auth.user!.id,
                      'userName': auth.user!.name.isEmpty
                          ? auth.user!.email
                          : auth.user!.name,
                      'content': content,
                    });
                    _ctrl.clear();
                    setState(() => _submitting = false);
                  },
          ),
        ],
      ),
    );
  }
}
