import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/news_provider.dart';
import '../services/cloudinary_service.dart';

class AddNewsPage extends StatefulWidget {
  @override
  State<AddNewsPage> createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  XFile? _image;
  bool _loading = false;
  final picker = ImagePicker();
  Timer? _autosaveTimer;

  final CloudinaryService _cloudinary = CloudinaryService(
    cloudName: 'diyahzjpz',
    uploadPreset: 'unsigned_preset',
    apiKey: '627376456298499',
    apiSecret: '4z2kjd-qtzOI2cvA695-SuFTy0I',
  );

  static const _draftKeyTitle = 'draft_title';
  static const _draftKeyContent = 'draft_content';

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _title.addListener(_scheduleAutosave);
    _content.addListener(_scheduleAutosave);
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(Duration(seconds: 3), _saveDraft);
  }

  Future _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKeyTitle, _title.text);
    await prefs.setString(_draftKeyContent, _content.text);
  }

  Future _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_draftKeyTitle);
    final c = prefs.getString(_draftKeyContent);
    if (t != null) _title.text = t;
    if (c != null) _content.text = c;
  }

  Future _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKeyTitle);
    await prefs.remove(_draftKeyContent);
  }

  Future pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) setState(() => _image = picked);
  }

  Future publish() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('You must login to publish')));
      return;
    }

    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Headline and Content are required')),
      );
      return;
    }

    setState(() => _loading = true);
    String? url;
    try {
      if (_image != null) {
        url = await _cloudinary.uploadImage(_image!);
      }

      await Provider.of<NewsProvider>(context, listen: false).createNews({
        'title': _title.text.trim(),
        'content': _content.text.trim(),
        'coverUrl': url,
        'authorId': auth.user!.id,
        'authorName': auth.user!.name.isEmpty
            ? auth.user!.email
            : auth.user!.name,
      });

      await _clearDraft();
      setState(() => _loading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      final err = e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error publishing: $err')));
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _title.removeListener(_scheduleAutosave);
    _content.removeListener(_scheduleAutosave);
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Add News',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Section
            Text(
              'Cover Image',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: pickImage,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: Colors.grey.shade300,
                  strokeWidth: 1.5,
                  gap: 5.0,
                ),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Upload Cover Image',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tap to select from gallery or take a photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _image!.path,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Headline Section
            Text(
              'Headline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                hintText: 'Enter an engaging title...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Article Content Section
            Text(
              'Article Content',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: 'Write your story here...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),

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
                contentPadding: EdgeInsets.all(16),
              ),
            ),
            SizedBox(height: 32),

            // Publish Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E50F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Publish Article',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(12),
      ),
    );

    Path dashPath = Path();
    double dashWidth = 5.0;
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
