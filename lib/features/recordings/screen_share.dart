import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ShareScreen extends StatefulWidget {
  final String filePath;
  final String username;

  const ShareScreen({
    required this.filePath,
    required this.username,
    super.key,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool _isUploading = true;
  String? _shareLink;
  final double _uploadProgress = 0;
  String _tapeTitle = 'Voice Tape';
  Color _selectedColor = Colors.orange;

  final List<Color> _tapeColors = [
    Colors.orange,
    Colors.deepPurple,
    Colors.teal,
    Colors.red,
    Colors.blue,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _uploadAndGenerateLink();
  }

  Future<void> _uploadAndGenerateLink() async {
    try {
      final tapeId = const Uuid().v4();
      final supabase = Supabase.instance.client;
      final file = File(widget.filePath);
      final bytes = await file.readAsBytes();

      await supabase.storage.from('tapes').uploadBinary(
        '$tapeId.m4a',
        bytes,
        fileOptions: const FileOptions(contentType: 'audio/m4a'),
      );

      final audioUrl = supabase.storage
          .from('tapes')
          .getPublicUrl('$tapeId.m4a');

      await FirebaseFirestore.instance
          .collection('tapes')
          .doc(tapeId)
          .set({
        'id': tapeId,
        'audioUrl': audioUrl,
        'sender': widget.username,
        'title': _tapeTitle,
        'color': _selectedColor.value.toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'playCount': 0,
      });

      setState(() {
        _shareLink = 'tapeshare://tape/$tapeId';
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareToSocials() {
    if (_shareLink == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: '🎙 I sent you a voice tape! Wind it to hear it 👇\n$_shareLink',
      ),
    );
  }

  void _copyLink() {
    if (_shareLink == null) return;
    Clipboard.setData(ClipboardData(text: _shareLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        title: const Text(
          'Share Your Tape',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isUploading ? _buildUploadingView() : _buildShareView(),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎞', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 32),
          const Text(
            'Uploading your tape...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: LinearProgressIndicator(
              value: _uploadProgress == 0 ? null : _uploadProgress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedColor.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Text('📼', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    _tapeTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From: ${widget.username}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Tape Title',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            style: const TextStyle(color: Colors.white),
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'Give your tape a name...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: TextStyle(color: Colors.grey[600]),
            ),
            onChanged: (val) => setState(() => _tapeTitle = val),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tape Color',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: _tapeColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Share Link',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shareLink ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _copyLink,
                  child: const Icon(Icons.copy, color: Colors.orange, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _shareToSocials,
              icon: const Icon(Icons.share, color: Colors.black),
              label: const Text(
                'Share Tape',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.mic, color: Colors.grey),
              label: const Text(
                'Record Another',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}