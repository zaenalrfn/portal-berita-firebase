import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../providers/news_provider.dart';
import '../services/cloudinary_service.dart';
import '../widgets/guest_placeholder.dart';
import '../providers/theme_provider.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        backgroundColor: Colors.white,
        body: GuestPlaceholder(
          title: 'Profile Locked',
          message: 'Login to view and edit your profile information.',
          icon: Icons.person_off_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Optional: Settings menu could go here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Icon(Icons.person, size: 60, color: Colors.orange)
                  : null,
            ),
            SizedBox(height: 16),

            // Name
            Text(
              user.name.isEmpty ? 'User' : user.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                // color: Colors.black87, // Use theme default
              ),
            ),
            SizedBox(height: 4),

            // Email/Role Subtitle
            Text(
              user.email,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 24),

            // Edit Profile Button
            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _EditProfileDialog(user: user),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                    0xFF1E50F8,
                  ), // Matches the blue in mockup
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),

            // Contact Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTACT INFORMATION',
                    style: TextStyle(
                      color: Color(0xFF1E50F8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Email Item
                  _buildContactItem(
                    context,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  SizedBox(height: 16),

                  // Password/Security Item (Custom addition for "Update Password")
                  _buildContactItem(
                    context,
                    icon: Icons.lock_outline,
                    label: 'Security',
                    value: 'Update Password',
                    isLink: true,
                    onTap: () => _showChangePasswordDialog(context, auth),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Settings Section
            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: Color(0xFF1E50F8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF2C2C2C)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          secondary: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey[800]
                                  : Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.dark_mode_outlined,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Color(0xFF1E50F8),
                              size: 20,
                            ),
                          ),
                          value: themeProvider.isDarkMode,
                          activeColor: Color(0xFF1E50F8),
                          onChanged: (val) {
                            themeProvider.toggleTheme(val);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    // Go back to home, ensuring we are in a clean state (Home checks auth)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: Icon(Icons.logout, color: Colors.red),
                  label: Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2C2C2C) : Colors.grey[50], // Dynamic bg
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1E1E1E)
                    : Color(0xFFE8EEFF), // Dynamic icon bg
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF1E50F8), size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isLink
                          ? Color(0xFF1E50F8)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            if (isLink) Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Password'),
        content: TextField(
          controller: passCtrl,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await auth.changePassword(passCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password updated successfully')),
                );
              } catch (e) {
                if (e.toString().contains('requires-recent-login') ||
                    (e is FirebaseAuthException &&
                        e.code == 'requires-recent-login')) {
                  Navigator.pop(ctx); // Close current dialog
                  _showReauthDialog(context, auth, passCtrl.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showReauthDialog(
    BuildContext context,
    AuthProvider auth,
    String newPassword,
  ) {
    final currentPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Security Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter your CURRENT password to continue.'),
            SizedBox(height: 16),
            TextField(
              controller: currentPassCtrl,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  if (auth.user?.email != null) {
                    Navigator.pop(ctx);
                    try {
                      await auth.resetPassword(auth.user!.email!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reset link sent to ${auth.user!.email}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending reset email: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final pwd = currentPassCtrl.text.trim();
                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await auth.reauthenticate(pwd);
                Navigator.pop(ctx); // Close reauth dialog

                // Retry changing password
                try {
                  await auth.changePassword(newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating password: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                String msg = 'Incorrect password. Please try again.';
                if (e is FirebaseAuthException) {
                  msg = e.message ?? msg;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final AppUser user;
  const _EditProfileDialog({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameCtrl;
  XFile? _image;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  // Credentials reused from CloudinaryService example
  final CloudinaryService _cloudinary = CloudinaryService(
    cloudName: 'diyahzjpz',
    uploadPreset: 'unsigned_preset',
    apiKey: '627376456298499',
    apiSecret: '4z2kjd-qtzOI2cvA695-SuFTy0I',
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  String? _getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      // pathSegments example: ['demo', 'image', 'upload', 'v1234567890', 'sample.jpg']
      // We want 'sample' (or 'folder/sample' if nested, but usually just filename here)
      // Standard Cloudinary upload gives last segment as filename.
      if (pathSegments.isNotEmpty) {
        final filename = pathSegments.last;
        final publicId = filename.split('.').first;
        return publicId;
      }
    } catch (e) {
      print('Error parsing public ID: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: _image != null
                    ? (kIsWeb
                          ? NetworkImage(_image!.path)
                          : FileImage(File(_image!.path)) as ImageProvider)
                    : (widget.user.photoUrl != null
                          ? NetworkImage(widget.user.photoUrl!)
                          : null),
                child: (_image == null && widget.user.photoUrl == null)
                    ? Icon(Icons.add_a_photo, color: Colors.grey[600])
                    : (_image != null
                          ? null
                          : (widget.user.photoUrl != null
                                ? null
                                : Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey[600],
                                  ))),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _uploading
              ? null
              : () async {
                  setState(() => _uploading = true);
                  try {
                    String? newPhotoUrl = widget.user.photoUrl;

                    if (_image != null) {
                      // 1. Check if there is an existing photo to delete
                      if (widget.user.photoUrl != null) {
                        final oldPublicId = _getPublicIdFromUrl(
                          widget.user.photoUrl!,
                        );
                        if (oldPublicId != null) {
                          await _cloudinary.deleteImage(oldPublicId);
                        }
                      }

                      // 2. Upload the new image
                      newPhotoUrl = await _cloudinary.uploadImage(_image!);
                    }

                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).updateProfile(
                      name: _nameCtrl.text.trim(),
                      photoUrl: newPhotoUrl,
                    );

                    // Refresh news to reflect name change locally/immediately
                    await Provider.of<NewsProvider>(
                      context,
                      listen: false,
                    ).fetchFirstPage();

                    Navigator.pop(context);
                  } catch (e) {
                    setState(() => _uploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                },
          child: _uploading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Save'),
        ),
      ],
    );
  }
}
