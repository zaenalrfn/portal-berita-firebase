# Laporan Proyek: Portal Berita Firebase

## 1. Pendahuluan

### Studi Kasus
Proyek ini adalah sebuah **Portal Berita** berbasis aplikasi *mobile* yang dikembangkan menggunakan Flutter. Aplikasi ini memungkinkan pengguna untuk membaca berita, membuat berita baru (bagi pengguna terdaftar), memberika komentar, dan menyimpan berita ke daftar bacaan (bookmarks).

### Tujuan Aplikasi
Tujuan utama dari aplikasi ini adalah sebagai media berbagi informasi yang interaktif. Pengguna tidak hanya menjadi konsumen berita, tetapi juga berkontribusi sebagai pembuat konten (*User Generated Content*). Aplikasi ini juga mendemonstrasikan integrasi teknologi *cloud* modern menggunakan **Firebase** (untuk autentikasi dan database) dan **Cloudinary** (untuk penyimpanan media gambar).

---

## 2. Persiapan dan Setup

### Pembuatan Project Flutter
Proyek dibuat menggunakan perintah standar Flutter:
```bash
flutter create portal_berita_firebase
```
Struktur folder disesuaikan untuk memisahkan logika (*services, providers*), data (*models*), dan tampilan (*screens, widgets*).

### Pembuatan Project di Firebase Console
1.  Membuat proyek baru di [Firebase Console](https://console.firebase.google.com/).
2.  Mengaktifkan **Authentication** (Email/Password).
3.  Membuat database **Cloud Firestore**.

### Integrasi Firebase dengan Flutter
Menggunakan `flutterfire_cli` untuk menghubungkan proyek lokal dengan Firebase:
```bash
flutter pub add firebase_core firebase_auth cloud_firestore
dart pub global activate flutterfire_cli
flutterfire configure
```
Konfigurasi ini menghasilkan file `firebase_options.dart`.

Pada `main.dart`, Firebase diinisialisasi sebelum aplikasi dijalankan:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(App());
}
```

---

## 3. Implementasi Firebase Authentication

### Alur Login/Registrasi
Aplikasi menggunakan **Email & Password Authentication**.
-   **Login**: Pengguna memasukkan email dan password. Jika valid, sesi pengguna disimpan oleh Firebase Auth.
-   **Registrasi**: Pengguna mendaftar dengan email, password, dan nama lengkap. Data pengguna disimpan di Firebase Auth dan dokumen profil tambahan dibuat di koleksi `users` di Firestore.
-   UI Login/Register ditangani oleh sebuah dialog modal (`AuthDialog`) yang dapat diakses dari halaman Home atau Profile jika pengguna belum login.

### Cuplikan Kode Penting (AuthService)

Berikut adalah implementasi `AuthService` di `lib/services/auth_service.dart`:

**Fungsi Register:**
```dart
Future<UserCredential> register(String email, String password, String name) async {
  // 1. Buat akun di Firebase Auth
  final cred = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  // 2. Simpan data profil tambahan di Firestore
  await _db.collection('users').doc(cred.user!.uid).set({
    'name': name,
    'email': email,
    'photoUrl': null,
    'createdAt': FieldValue.serverTimestamp(),
  });
  return cred;
}
```
*Penjelasan*: Fungsi ini membuat user baru di sistem autentikasi Firebase, lalu segera membuat dokumen di koleksi `users` agar aplikasi bisa menyimpan data profil seperti nama dan foto.

**Fungsi Login:**
```dart
Future<UserCredential> login(String email, String password) async {
  return await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}
```
*Penjelasan*: Menggunakan method bawaan Firebase untuk memvalidasi kredensial email/password.

**Pengecekan Status Login (Stream):**
```dart
Stream<User?> authStateChanges() => _auth.authStateChanges();
```
*Penjelasan*: Stream ini mendengarkan perubahan status login secara *real-time*. `AuthProvider` menggunakan stream ini untuk memperbarui UI secara otomatis ketika user login atau logout.

---

## 4. Perancangan & Implementasi Data (Cloud Firestore)

### Struktur Data (Entitas)
Database menggunakan Cloud Firestore (NoSQL) dengan struktur utama sebagai berikut:

1.  **Users (`users/{uid}`)**: Menyimpan profil pengguna.
    *   `name`: String
    *   `email`: String
    *   `photoUrl`: String (URL Cloudinary)
2.  **News (`news/{newsId}`)**: Menyimpan artikel berita.
    *   `title`: String
    *   `content`: String
    *   `coverUrl`: String
    *   `authorId`: String
    *   `createdAt`: Timestamp
3.  **Comments (`news/{newsId}/comments/{commentId}`)**: Sub-koleksi untuk komentar.
    *   `content`: String
    *   `userId`: String
    *   `createdAt`: Timestamp

### Implementasi Penyimpanan & Pengambilan Data

**Model Berita (`News` Model):**
Menerjemahkan data JSON dari Firestore ke objek Dart.
```dart
class News {
  final String id;
  final String title;
  final String content;
  // ... field lainnya
  
  factory News.fromMap(String id, Map<String, dynamic> m) => News(
    id: id,
    title: m['title'] ?? '',
    content: m['content'] ?? '',
    // ...
  );
}
```

**Stream Berita (Real-time):**
Mengambil daftar berita dan memperbaruinya otomatis jika ada data baru.
```dart
Stream<QuerySnapshot> streamNews() =>
    _db.collection('news').orderBy('createdAt', descending: true).snapshots();
```

**Menambah Komentar (Sub-collection):**
```dart
Future<void> addComment(String newsId, Map<String, dynamic> comment) async {
  comment['createdAt'] = FieldValue.serverTimestamp();
  await _db
      .collection('news')
      .doc(newsId)
      .collection('comments')
      .add(comment);
}
```
*Penjelasan*: Komentar disimpan sebagai *child* dari dokumen berita tertentu, memudahkan pengambilan komentar spesifik untuk satu berita.

---

## 5. Implementasi Fitur Utama

### 1. Profil Pengguna & Edit Foto
Pengguna dapat melihat dan mengubah profil mereka,termasuk mengunggah foto profil. Foto diunggah ke **Cloudinary** dan URL-nya disimpan di Firestore.

**Logika Upload Foto (ProfilePage):**
```dart
// Upload gambar ke Cloudinary
newPhotoUrl = await _cloudinary.uploadImage(_image!);

// Update URL di Firestore Profile
await Provider.of<AuthProvider>(context, listen: false).updateProfile(
  name: _nameCtrl.text.trim(),
  photoUrl: newPhotoUrl,
);
```

### 2. Manajemen Berita (CRUD)
Pengguna dapat menambah, mengedit, dan menghapus berita mereka sendiri.
-   **Create**: `AddNewsPage` memanggil `NewsService.createNews`.
-   **Read**: `HomePage` menampilkan list berita dengan `GridView` atau `ListView`.
-   **Update/Delete**: Ikon edit/hapus hanya muncul jika `currentUserId == news.authorId`.

### 3. Bookmarks
Fitur untuk menyimpan berita favorit secara lokal (menggunakan logic di `BookmarkProvider`).

---

## 6. Tampilan Antarmuka (UI)

Desain aplikasi menggunakan gaya modern dengan dukungan **Dark Mode** dan **Light Mode** yang responsif.

### A. Screenshot

| Halaman | Deskripsi |
| :--- | :--- |
| **Login / Register** | ![Login Screen](PLACEHOLDER_LINK_IMAGE_LOGIN) <br> Dialog modal untuk masuk atau mendaftar akun baru. |
| **Home Page** | ![Home Screen](PLACEHOLDER_LINK_IMAGE_HOME) <br> Halaman utama menampilkan daftar berita terbaru dengan opsi tampilan List atau Grid. |
| **Profile Page** | ![Profile Screen](PLACEHOLDER_LINK_IMAGE_PROFILE) <br> Menampilkan informasi user, opsi edit profil, dan pengaturan tema. |
| **News Detail** | ![Detail Screen](PLACEHOLDER_LINK_IMAGE_DETAIL) <br> Tampilan lengkap berita beserta komentar pengguna lain. |

*Catatan: Gambar screenshot dapat dilampirkan manual pada placeholder di atas.*

### B. Alur Navigasi
Aplikasi menggunakan `BottomNavigationBar` di `MainPage` untuk navigasi utama:
1.  **Home**: Feed berita global.
2.  **My News**: Daftar berita yang dibuat pengguna sendiri.
3.  **Bookmarks**: Berita yang disimpan.
4.  **Profile**: Pengaturan akun.

---

## 7. Penggunaan AI

### AI yang Digunakan
-   **Google Gemini (via IDE Assistant)**

### Peran AI dalam Pengembangan
1.  **Struktur Boilerplate**: Membantu membuat struktur awal `Provider` dan `Service` untuk memisahkan logika bisnis dari UI.
2.  **Debugging**: Membantu menemukan solusi saat terjadi error, misalnya pada masalah *build version* atau logic *null safety* di Dart.
3.  **Refactoring Kode**: Memberikan saran untuk merapikan kode, seperti memisahkan widget besar menjadi widget-widget kecil (`NewsCard`, `AuthDialog`) agar lebih mudah dibaca dan `reusable`.
4.  **Dokumentasi**: Membantu menyusun laporan ini (`README.md`) berdasarkan analisis kode yang ada.
