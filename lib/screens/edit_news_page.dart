import 'dart:io';
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

  // TODO: Ganti dengan Cloudinary Cloud name & upload preset Anda
  final CloudinaryService _cloudinary = CloudinaryService(
    cloudName: 'diyahzjpz',
    uploadPreset: 'unsigned_preset',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit News')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _image == null
                    ? (widget.currentCoverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.currentCoverUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Center(child: Text('Upload Cover Image')))
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
            SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: 'Headline'),
            ),
            SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _content,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(labelText: 'Article Content'),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : save,
              child: _loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
