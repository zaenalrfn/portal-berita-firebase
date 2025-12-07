import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/user_display.dart';

class NewsCard extends StatelessWidget {
  final String id;
  final String title;
  final String excerpt;
  final String? coverUrl;
  final String authorName;
  final String authorId;
  final Map<String, dynamic>? meta;

  NewsCard({
    required this.id,
    required this.title,
    required this.excerpt,
    this.coverUrl,
    required this.authorName,
    required this.authorId,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final bookmarkProv = Provider.of<BookmarkProvider>(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    // setUid logic moved to ProxyProvider in main app

    final isBook = bookmarkProv.bookmarkedIds.contains(id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/detail', arguments: {'id': id});
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // color: Colors.white, // Inherits from CardTheme which uses theme.cardColor
        child: Row(
          children: [
            Container(
              width: 110,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                image: (coverUrl != null && coverUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (coverUrl == null || coverUrl!.isEmpty)
                  ? Icon(Icons.image_not_supported, color: Colors.grey)
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text(excerpt),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: UserDisplay(
                            userId: authorId,
                            fallbackName: authorName,
                            prefix: 'by ',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isBook ? Icons.bookmark : Icons.bookmark_border,
                          ),
                          onPressed: () async {
                            if (!authProv.isAuthenticated) {
                              showDialog(
                                context: context,
                                builder: (_) => AuthDialog(),
                              );
                              return;
                            }
                            try {
                              await bookmarkProv.toggleBookmark(id, {
                                'title': title,
                                'coverUrl': coverUrl,
                                'authorName': authorName,
                                'authorId': authorId,
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ' + e.toString()),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
