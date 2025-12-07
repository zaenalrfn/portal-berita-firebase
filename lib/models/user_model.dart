class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });
  factory AppUser.fromMap(String id, Map<String, dynamic> m) => AppUser(
    id: id,
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    photoUrl: m['photoUrl'],
  );
}
