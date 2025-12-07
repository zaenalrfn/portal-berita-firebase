import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(String id, Map<String, dynamic> m) => Comment(
    id: id,
    userId: m['userId'],
    userName: m['userName'],
    content: m['content'],
    createdAt: (m['createdAt'] as Timestamp).toDate(),
  );
}
