import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDisplay extends StatelessWidget {
  final String userId;
  final String fallbackName;
  final TextStyle? style;
  final String prefix;

  const UserDisplay({
    Key? key,
    required this.userId,
    this.fallbackName = 'Unknown',
    this.style,
    this.prefix = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Text(prefix + fallbackName, style: style);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = fallbackName;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null && data['name'].isNotEmpty) {
            name = data['name'];
          }
        }
        return Text(
          prefix + name,
          style: style,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    Key? key,
    required this.userId,
    this.radius = 20,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: Icon(Icons.person, color: Colors.grey, size: radius),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            photoUrl = data['photoUrl'];
          }
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
              ? NetworkImage(photoUrl)
              : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Icon(Icons.person, color: Colors.grey, size: radius)
              : null,
        );
      },
    );
  }
}
