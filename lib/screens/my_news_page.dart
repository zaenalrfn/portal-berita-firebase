import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/news_provider.dart';
import '../widgets/auth_dialog.dart';

class MyNewsPage extends StatefulWidget {
  @override
  _MyNewsPageState createState() => _MyNewsPageState();
}

class _MyNewsPageState extends State<MyNewsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      return DateFormat('MMM dd, yyyy').format(dt);
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

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('My News'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Viewing as guest'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    showDialog(context: context, builder: (_) => AuthDialog()),
                child: Text('Login to manage your news'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0, // Custom header in body
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My News',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/add'),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFE8EEFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: Color(0xFF1E50F8)),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search my articles...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF1E50F8)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // News List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('news')
                    .where('authorId', isEqualTo: auth.user!.id)
                    .snapshots(),
                builder: (c, s) {
                  if (s.hasError)
                    return Center(child: Text('Error: ${s.error}'));
                  if (!s.hasData)
                    return Center(child: CircularProgressIndicator());

                  final docs = s.data!.docs;

                  // Sort descending
                  docs.sort((a, b) {
                    final da = a.data() as Map<String, dynamic>;
                    final db = b.data() as Map<String, dynamic>;
                    final ca = da['createdAt'] as Timestamp?;
                    final cb = db['createdAt'] as Timestamp?;
                    if (ca == null || cb == null) return 0;
                    return cb.compareTo(ca);
                  });

                  // Filter local
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '')
                        .toString()
                        .toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    if (_searchQuery.isNotEmpty) {
                      return Center(
                        child: Text(
                          'No articles found matching "$_searchQuery".',
                        ),
                      );
                    }
                    return Center(
                      child: Text('You have not published any news'),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    separatorBuilder: (c, i) =>
                        Divider(height: 30, color: Colors.grey.shade100),
                    itemCount: filteredDocs.length,
                    itemBuilder: (ctx, i) {
                      final doc = filteredDocs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      final String id = doc.id;
                      final String? coverUrl = d['coverUrl'];
                      final String title = d['title'] ?? 'No Title';
                      final dynamic createdAt = d['createdAt'];

                      return Container(
                        height: 80,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[200],
                                image: (coverUrl != null && coverUrl.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(coverUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (coverUrl == null || coverUrl.isEmpty)
                                  ? Icon(Icons.image, color: Colors.grey)
                                  : null,
                            ),
                            SizedBox(width: 16),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    _formatTimeAgo(createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/edit_news',
                                      arguments: {
                                        'id': id,
                                        'title': title,
                                        'content': d['content'],
                                        'coverUrl': coverUrl,
                                      },
                                    );
                                  },
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16),
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text('Delete News?'),
                                        content: Text('This cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await Provider.of<NewsProvider>(
                                        context,
                                        listen: false,
                                      ).deleteNews(id);
                                    }
                                  },
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
