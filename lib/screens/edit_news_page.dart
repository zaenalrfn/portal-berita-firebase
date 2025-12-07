import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../services/cloudinary_service.dart';

class EditNewsPage extends StatefulWidget {
  final String newsId;
  final String currentTitle;
  final String currentContent;
  final String? currentCoverUrl;

  EditNewsPage({
    required this.newsId,
    required this.currentTitle,
    required this.currentContent,
    this.currentCoverUrl,
  });

  @override
  _EditNewsPageState createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  late TextEditingController _title;
  late TextEditingController _content;
  XFile? _image;
  bool _loading = false;
  final picker = ImagePicker();

  final CloudinaryService _cloudinary = CloudinaryService(
    cloudName: 'diyahzjpz',
    uploadPreset: 'unsigned_preset',
    apiKey: '627376456298499',
    apiSecret: '4z2kjd-qtzOI2cvA695-SuFTy0I',
  );

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.currentTitle);
    _content = TextEditingController(text: widget.currentContent);
  }

  Future pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) setState(() => _image = picked);
  }

  Future save() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Headline and Content are required')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String? url = widget.currentCoverUrl;
      if (_image != null) {
        url = await _cloudinary.uploadImage(_image!);
      }

      await Provider.of<NewsProvider>(context, listen: false).updateNews(
        widget.newsId,
        {
          'title': _title.text.trim(),
          'content': _content.text.trim(),
          'coverUrl': url,
        },
      );

      setState(() => _loading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      final err = e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating: $err')));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // Use theme
      appBar: AppBar(
        // backgroundColor: Colors.white, // Use theme
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Use theme color
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Edit News',
          style: TextStyle(
            // color: Colors.black, // Use theme
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? (widget.currentCoverUrl != null &&
                                widget.currentCoverUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.currentCoverUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
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
                                      // color: Colors.black87, // Use theme
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
                              ))
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

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : save,
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
                        'Save Changes',
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
