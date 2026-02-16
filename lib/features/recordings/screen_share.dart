import 'dart:io';
import 'dart:math' as math;
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

class _ShareScreenState extends State<ShareScreen>
    with TickerProviderStateMixin {
  bool _isUploading = true;
  String? _shareLink;
  String _tapeTitle = 'Voice Tape';

  // Vintage color palette
  static const _amber = Color(0xFFFFB347);
  static const _cream = Color(0xFFFFF8E7);
  static const _rust = Color(0xFFD2691E);
  static const _teal = Color(0xFF4ECDC4);
  static const _coral = Color(0xFFFF6B6B);

  Color _selectedColor = const Color(0xFFFFB347);

  final List<Color> _tapeColors = [
    const Color(0xFFFFB347), // Amber
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFFFF6B9D), // Pink
    const Color(0xFFB19CD9), // Lavender
    const Color(0xFF5EEAD4), // Mint
    const Color(0xFFFF6B6B), // Coral
  ];

  late AnimationController _reelController;
  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _uploadAndGenerateLink();
  }

  @override
  void dispose() {
    _reelController.dispose();
    _successController.dispose();
    super.dispose();
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

      final audioUrl =
          supabase.storage.from('tapes').getPublicUrl('$tapeId.m4a');

      await FirebaseFirestore.instance.collection('tapes').doc(tapeId).set({
        'id': tapeId,
        'audioUrl': audioUrl,
        'sender': widget.username,
        'title': _tapeTitle,
        'color': _selectedColor.toARGB32().toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'playCount': 0,
      });

      setState(() {
        _shareLink = 'tapeshare://tape/$tapeId';
        _isUploading = false;
      });

      _successController.forward();
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: _coral,
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
      SnackBar(
        content: const Text('Link copied!'),
        backgroundColor: _teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1410),
              Color(0xFF0D0A08),
              Color(0xFF151210),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative glows
              ..._buildDecorations(),

              Column(
                children: [
                  // App bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [_amber, _cream],
                          ).createShader(bounds),
                          child: const Text(
                            'Share Your Tape',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _isUploading
                        ? _buildUploadingView()
                        : _buildShareView(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorations() {
    return [
      Positioned(
        top: -80,
        right: -80,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _amber.withValues(alpha: 0.15),
                _amber.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -100,
        left: -60,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _selectedColor.withValues(alpha: 0.1),
                _selectedColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildUploadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated cassette while uploading
          AnimatedBuilder(
            animation: _reelController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(260, 170),
                painter: VintageCassettePainter(
                  cassetteColor: _selectedColor,
                  reelRotation: _reelController.value * 2 * math.pi,
                  isPlaying: true,
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_cream, _amber],
            ).createShader(bounds),
            child: const Text(
              'Creating your tape...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(_amber),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
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
          // Vintage cassette preview
          Center(
            child: ScaleTransition(
              scale: _successScale,
              child: AnimatedBuilder(
                animation: _reelController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(300, 200),
                    painter: VintageCassettePainter(
                      cassetteColor: _selectedColor,
                      reelRotation: _reelController.value * 2 * math.pi,
                      isPlaying: false,
                      title: _tapeTitle,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Tape Title
          Text(
            'Tape Title',
            style: TextStyle(
              color: _cream,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _amber.withValues(alpha: 0.5)),
              ),
              counterStyle: TextStyle(color: Colors.grey[600]),
            ),
            onChanged: (val) => setState(() => _tapeTitle = val),
          ),

          const SizedBox(height: 8),
          Text(
            'Tape Style',
            style: TextStyle(
              color: _cream,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _tapeColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  width: isSelected ? 44 : 36,
                  height: isSelected ? 44 : 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.3)!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: _cream, width: 3)
                        : Border.all(color: Colors.white24, width: 1),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          Text(
            'Share Link',
            style: TextStyle(
              color: _cream,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _amber.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shareLink ?? '',
                    style: TextStyle(color: _teal, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _copyLink,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _amber.withValues(alpha: 0.2),
                    ),
                    child: Icon(Icons.copy_rounded, color: _amber, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [_amber, _rust],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _amber.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _shareToSocials,
                icon: const Icon(Icons.share_rounded, color: Colors.black87),
                label: const Text(
                  'Share Tape',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                side: BorderSide(color: _cream.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: Icon(Icons.mic_rounded, color: _cream.withValues(alpha: 0.7)),
              label: Text(
                'Record Another',
                style: TextStyle(
                  color: _cream.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Vintage Cassette Painter with stickers
class VintageCassettePainter extends CustomPainter {
  final Color cassetteColor;
  final double reelRotation;
  final bool isPlaying;
  final String? title;

  VintageCassettePainter({
    required this.cassetteColor,
    required this.reelRotation,
    this.isPlaying = false,
    this.title,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Main cassette body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(12),
    );

    // Body gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cassetteColor,
          Color.lerp(cassetteColor, Colors.black, 0.25)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRRect(bodyRect, bodyPaint);

    // Top edge highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(12, 2),
      Offset(w - 12, 2),
      highlightPaint,
    );

    // Label area (cream colored vintage label)
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.12, w * 0.8, h * 0.35),
      const Radius.circular(6),
    );
    final labelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF8E7),
          Color(0xFFEEE4D4),
        ],
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.12, w * 0.8, h * 0.35));
    canvas.drawRRect(labelRect, labelPaint);

    // Label text lines
    final linePaint = Paint()
      ..color = const Color(0xFFCCC0B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      final y = h * 0.18 + i * 12;
      canvas.drawLine(
        Offset(w * 0.15, y),
        Offset(w * 0.85, y),
        linePaint,
      );
    }

    // Title text on label
    final displayTitle = title ?? 'TAPE SHARE';
    final textPainter = TextPainter(
      text: TextSpan(
        text: displayTitle.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8B7355),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: w * 0.7);
    textPainter.paint(
      canvas,
      Offset(w / 2 - textPainter.width / 2, h * 0.35),
    );

    // Tape window (dark area showing tape)
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.52, w * 0.7, h * 0.32),
      const Radius.circular(8),
    );
    final windowPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRRect(windowRect, windowPaint);

    // Window inner shadow
    final windowInnerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(windowRect, windowInnerPaint);

    // Left reel
    _drawReel(
      canvas,
      Offset(w * 0.32, h * 0.68),
      w * 0.10,
      reelRotation,
    );

    // Right reel
    _drawReel(
      canvas,
      Offset(w * 0.68, h * 0.68),
      w * 0.10,
      -reelRotation,
    );

    // Tape between reels
    final tapePaint = Paint()
      ..color = const Color(0xFF3D2817)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(w * 0.40, h * 0.68),
      Offset(w * 0.60, h * 0.68),
      tapePaint,
    );

    // Stickers!
    _drawSticker(canvas, Offset(w * 0.82, h * 0.15), '⭐', 24, -0.15);
    _drawSticker(canvas, Offset(w * 0.12, h * 0.75), '🎵', 20, 0.2);
    _drawSticker(canvas, Offset(w * 0.88, h * 0.78), '❤️', 18, 0.1);

    // Corner screws
    _drawScrew(canvas, const Offset(16, 16));
    _drawScrew(canvas, Offset(w - 16, 16));
    _drawScrew(canvas, Offset(16, h - 16));
    _drawScrew(canvas, Offset(w - 16, h - 16));

    // Bottom edge detail
    final bottomEdgePaint = Paint()
      ..color = Color.lerp(cassetteColor, Colors.black, 0.4)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.3, h - 8, w * 0.4, 4),
        const Radius.circular(2),
      ),
      bottomEdgePaint,
    );
  }

  void _drawReel(Canvas canvas, Offset center, double radius, double rotation) {
    // Reel background
    final reelBgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4A4A4A),
          const Color(0xFF2A2A2A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, reelBgPaint);

    // Reel rim
    final rimPaint = Paint()
      ..color = const Color(0xFF5A5A5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, rimPaint);

    // Center hub
    final hubPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(center, radius * 0.35, hubPaint);

    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (int i = 0; i < 6; i++) {
      final angle = rotation + (i * math.pi / 3);
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 0.35,
        center.dy + math.sin(angle) * radius * 0.35,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * 0.85,
        center.dy + math.sin(angle) * radius * 0.85,
      );
      canvas.drawLine(inner, outer, spokePaint);
    }

    // Center hole
    final holePaint = Paint()..color = const Color(0xFF0A0A0A);
    canvas.drawCircle(center, radius * 0.15, holePaint);
  }

  void _drawScrew(Canvas canvas, Offset center) {
    // Screw base
    final screwPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7A7A7A),
          const Color(0xFF4A4A4A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 5));
    canvas.drawCircle(center, 5, screwPaint);

    // Screw slot
    final slotPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx - 3, center.dy),
      Offset(center.dx + 3, center.dy),
      slotPaint,
    );
  }

  void _drawSticker(
    Canvas canvas,
    Offset position,
    String emoji,
    double size,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(VintageCassettePainter oldDelegate) =>
      oldDelegate.cassetteColor != cassetteColor ||
      oldDelegate.reelRotation != reelRotation ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.title != title;
}