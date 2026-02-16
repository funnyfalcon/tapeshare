import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerScreen extends StatefulWidget {
  final String tapeId;
  const PlayerScreen({required this.tapeId, super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();

  String _senderName = '';
  String _tapeTitle = '';
  String _audioUrl = '';
  Color _tapeColor = Colors.orange;
  bool _isLoading = true;
  bool _isFinished = false;
  String? _errorMessage;

  double _currentAngle = 0.0;
  double _totalRotation = 0.0;
  double _progress = 0.0;

  static const double _totalWinds = 4.0;

  @override
  void initState() {
    super.initState();
    _loadTape();
  }

  Future<void> _loadTape() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tapes')
          .doc(widget.tapeId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'This tape does not exist or has expired.';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final colorValue = int.tryParse(data['color'] ?? '') ?? Colors.orange.value;

      setState(() {
        _senderName = data['sender'] ?? 'Unknown';
        _tapeTitle = data['title'] ?? 'Voice Tape';
        _audioUrl = data['audioUrl'] ?? '';
        _tapeColor = Color(colorValue);
        _isLoading = false;
      });

      await _player.setUrl(_audioUrl);
      await _player.pause();

      await FirebaseFirestore.instance
          .collection('tapes')
          .doc(widget.tapeId)
          .update({'playCount': FieldValue.increment(1)});

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tape: $e';
        _isLoading = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    if (_isLoading || _audioUrl.isEmpty) return;

    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final newAngle = math.atan2(dy, dx);

    double delta = newAngle - _currentAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    setState(() {
      _currentAngle = newAngle;
      if (delta > 0) _totalRotation += delta;
      final totalRadians = _totalWinds * 2 * math.pi;
      _progress = (_totalRotation / totalRadians).clamp(0.0, 1.0);
      _isFinished = _progress >= 1.0;
    });

    _seekAudio();
  }

  void _onPanEnd(DragEndDetails details) {
    _player.pause();
  }

  Future<void> _seekAudio() async {
    final duration = _player.duration ?? Duration.zero;
    if (duration == Duration.zero) return;
    final seekTo = duration * _progress;
    await _player.seek(seekTo);
    if (!_isFinished) {
      _player.play();
    } else {
      _player.pause();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Tape',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildPlayerView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📼', style: TextStyle(fontSize: 60)),
          SizedBox(height: 24),
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Loading your tape...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💔', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _tapeColor.withOpacity(0.4), width: 2),
            ),
            child: Column(
              children: [
                const Text('📼', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  _tapeTitle,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $_senderName',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            _isFinished ? 'You\'ve heard the full tape!' : 'Wind the reel to hear the tape',
            style: TextStyle(
              color: _isFinished ? Colors.green : Colors.grey,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(_tapeColor),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(_progress * 100).toInt()}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(
                _isFinished ? 'Complete!' : 'Keep winding...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // THE WINDING ROD
          LayoutBuilder(builder: (context, constraints) {
            const size = 240.0;
            const center = Offset(size / 2, size / 2);
            return GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, center),
              onPanEnd: _onPanEnd,
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: SpoolPainter(
                    rotation: _totalRotation,
                    progress: _progress,
                    color: _tapeColor,
                    isFinished: _isFinished,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          Text(
            _isFinished ? 'Tape complete!' : 'Drag your finger in circles\naround the reel',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),

          const SizedBox(height: 40),

          if (_isFinished) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text('🎉 You finished the tape!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Want to send one back?',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.mic, color: Colors.black),
                      label: const Text('Record a Reply',
                          style: TextStyle(
                              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// THE SPOOL PAINTER
class SpoolPainter extends CustomPainter {
  final double rotation;
  final double progress;
  final Color color;
  final bool isFinished;

  const SpoolPainter({
    required this.rotation,
    required this.progress,
    required this.color,
    required this.isFinished,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      Paint()
        ..color = isFinished ? Colors.green : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final spokePaint = Paint()
      ..color = isFinished ? Colors.green : color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * math.pi / 3;
      final spokeEnd = Offset(
        center.dx + (radius * 0.55) * math.cos(angle),
        center.dy + (radius * 0.55) * math.sin(angle),
      );
      canvas.drawLine(center, spokeEnd, spokePaint);
      canvas.drawCircle(spokeEnd, 6, Paint()..color = isFinished ? Colors.green : color);
    }

    canvas.restore();

    canvas.drawCircle(center, 22, Paint()..color = isFinished ? Colors.green : color);
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF0D0D1A));
  }

  @override
  bool shouldRepaint(SpoolPainter old) =>
      old.rotation != rotation ||
      old.progress != progress ||
      old.isFinished != isFinished;
}
