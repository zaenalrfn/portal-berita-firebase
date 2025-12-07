import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String? coverUrl;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.coverUrl,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory News.fromMap(String id, Map<String, dynamic> m) => News(
    id: id,
    title: m['title'] ?? '',
    content: m['content'] ?? '',
    coverUrl: m['coverUrl'],
    authorId: m['authorId'] ?? '',
    authorName: m['authorName'] ?? '',
    createdAt: (m['createdAt'] as Timestamp).toDate(),
  );
}
