import 'dart:async';
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
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();

  String _senderName = '';
  String _tapeTitle = '';
  String _audioUrl = '';
  Color _tapeColor = const Color(0xFFFF6B9D);
  bool _isLoading = true;
  bool _isFinished = false;
  String? _errorMessage;
  bool _isWinding = false;

  double _currentAngle = 0.0;
  double _totalRotation = 0.0;
  double _progress = 0.0;

  static const double _totalWinds = 4.0;

  // Aesthetic color palette
  static const _pink = Color(0xFFFF6B9D);
  static const _cyan = Color(0xFF4ECDC4);
  static const _lavender = Color(0xFFB19CD9);
  static const _mint = Color(0xFF5EEAD4);

  // Audio position subscription
  StreamSubscription<Duration>? _positionSubscription;

  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _finishedController;
  late Animation<double> _finishedAnimation;
  late AnimationController _knobRotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation for loading->player transition
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // Initialize finished card animation
    _finishedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _finishedAnimation = CurvedAnimation(
      parent: _finishedController,
      curve: Curves.elasticOut,
    );
    
    // Initialize knob rotation animation (continuous rotation while playing)
    _knobRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Pulse animation for the knob
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
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
      final colorValue =
          int.tryParse(data['color'] ?? '') ?? Colors.orange.toARGB32();

      setState(() {
        _senderName = data['sender'] ?? 'Unknown';
        _tapeTitle = data['title'] ?? 'Voice Tape';
        _audioUrl = data['audioUrl'] ?? '';
        _tapeColor = Color(colorValue);
        _isLoading = false;
      });
      
      // Start fade-in animation
      _fadeController.forward();

      await _player.setUrl(_audioUrl);
      await _player.pause();
      
      // Listen to audio position to sync progress
      _positionSubscription = _player.positionStream.listen((position) {
        final duration = _player.duration ?? Duration.zero;
        if (duration.inMilliseconds > 0) {
          final newProgress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
          final wasFinished = _isFinished;
          setState(() {
            _progress = newProgress;
            // Sync rotation with audio progress
            _totalRotation = _progress * _totalWinds * 2 * math.pi;
            _isFinished = _progress >= 0.99;
            
            if (_isFinished && !wasFinished) {
              _finishedController.forward();
            }
          });
        }
      });

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

  void _onWheelPanUpdate(DragUpdateDetails details, Offset center) {
    if (_isLoading || _audioUrl.isEmpty || _isFinished) return;

    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final newAngle = math.atan2(dy, dx);

    double delta = newAngle - _currentAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    // Only respond to forward (clockwise) winding
    if (delta > 0) {
      setState(() {
        _currentAngle = newAngle;
        _isWinding = true;
      });

      // Play audio at constant 1x speed - progress syncs via position stream
      if (!_player.playing && !_isFinished) {
        _player.play();
        _knobRotationController.repeat();
      }
    } else {
      setState(() {
        _currentAngle = newAngle;
      });
    }
  }

  void _onWheelPanEnd(DragEndDetails details) {
    _player.pause();
    _knobRotationController.stop();
    setState(() {
      _isWinding = false;
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _fadeController.dispose();
    _finishedController.dispose();
    _knobRotationController.dispose();
    _pulseController.dispose();
    _player.dispose();
    super.dispose();
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
              Color(0xFF1A0A15),
              Color(0xFF0D0D1A),
              Color(0xFF0A1515),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [_pink, _cyan],
                            ).createShader(bounds),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _tapeTitle.isEmpty ? 'Your Tape' : _tapeTitle,
                                key: ValueKey(_tapeTitle),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _isLoading
                          ? _buildLoadingView()
                          : _errorMessage != null
                              ? _buildErrorView()
                              : FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildPlayerView(),
                                ),
                    ),
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
      // Top right glow
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
                _pink.withValues(alpha: 0.15),
                _pink.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      // Bottom left glow
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
                _cyan.withValues(alpha: 0.12),
                _cyan.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      // Center right glow when winding
      if (_isWinding)
        Positioned(
          bottom: 60,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _tapeColor.withValues(alpha: 0.2),
                  _tapeColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated cassette icon
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_pink, _cyan, _lavender],
            ).createShader(bounds),
            child: const Text('📼', style: TextStyle(fontSize: 70)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: _pink,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_cyan, _pink],
            ).createShader(bounds),
            child: const Text(
              'Rewinding your tape...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
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
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [_pink, _lavender],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerView() {
    return Stack(
      children: [

        // ── MAIN CONTENT ───────────────────────────────────
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 180),
          child: Column(
            children: [

              // Sender info with gradient
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_lavender, _cyan],
                ).createShader(bounds),
                child: Text(
                  'From: $_senderName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Cassette (not interactive — just visual)
              Center(
                child: SizedBox(
                  width: 300,
                  height: 185,
                  child: CustomPaint(
                    painter: CassettePainter(
                      progress: _progress,
                      rotation: _totalRotation,
                      tapeColor: _tapeColor,
                      isFinished: _isFinished,
                      isWinding: _isWinding,
                      title: _tapeTitle,
                      sender: _senderName,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Progress bar with gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (_isFinished ? _mint : _tapeColor).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[900],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _isFinished ? _mint : _tapeColor),
                        minHeight: 8,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tapeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_progress * 100).toInt()}%',
                      style: TextStyle(
                        color: _tapeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _isFinished ? Icons.check_circle : Icons.touch_app,
                        color: _isFinished ? _mint : Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFinished ? 'Complete!' : 'Wind the knob',
                        style: TextStyle(
                          color: _isFinished ? _mint : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: _isFinished ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Finished card
              if (_isFinished) ...[
                const SizedBox(height: 32),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(_finishedAnimation),
                  child: FadeTransition(
                    opacity: _finishedAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _mint.withValues(alpha: 0.15),
                            _cyan.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _mint.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: _mint.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 44)),
                          const SizedBox(height: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [_mint, _cyan],
                            ).createShader(bounds),
                            child: const Text(
                              'You heard the whole tape!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Want to send one back to $_senderName?',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [_pink, _lavender],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pink.withValues(alpha: 0.4),
                                    blurRadius: 16,
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
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.mic_rounded, color: Colors.white),
                                label: const Text(
                                  'Record a Reply',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── WINDING WHEEL — bottom right for single-hand use ─
        Positioned(
          bottom: 24,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isWinding ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '↻ Turn to play',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isWinding ? 1.0 : _pulseAnimation.value,
                    child: _buildWindingWheel(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWindingWheel() {
    const wheelSize = 140.0;
    const center = Offset(wheelSize / 2, wheelSize / 2);
    return GestureDetector(
      onPanUpdate: (d) => _onWheelPanUpdate(d, center),
      onPanEnd: _onWheelPanEnd,
      child: AnimatedBuilder(
        animation: _knobRotationController,
        builder: (context, child) {
          return SizedBox(
            width: wheelSize,
            height: wheelSize,
            child: CustomPaint(
              painter: WindingWheelPainter(
                rotation: _knobRotationController.value * 2 * math.pi,
                isWinding: _isWinding,
                color: _tapeColor,
                isFinished: _isFinished,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CASSETTE PAINTER
// ═══════════════════════════════════════════════════════════
class CassettePainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color tapeColor;
  final bool isFinished;
  final bool isWinding;
  final String title;
  final String sender;

  // Aesthetic colors
  static const _mint = Color(0xFF5EEAD4);

  const CassettePainter({
    required this.progress,
    required this.rotation,
    required this.tapeColor,
    required this.isFinished,
    required this.isWinding,
    required this.title,
    required this.sender,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(5, 7, w, h), const Radius.circular(14)),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(14));

    // Body gradient — dark warm plastic
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2E2E), Color(0xFF1A1A1A), Color(0xFF252525)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Top edge shine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, w - 4, 3), const Radius.circular(12)),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Outline
    canvas.drawRRect(bodyRect,
        Paint()
          ..color = const Color(0xFF404040)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ── LABEL ─────────────────────────────────────────────
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.05, w * 0.84, h * 0.33),
      const Radius.circular(7),
    );

    canvas.drawRRect(
      labelRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tapeColor, Color.lerp(tapeColor, Colors.black, 0.35)!],
        ).createShader(
            Rect.fromLTWH(w * 0.08, h * 0.05, w * 0.84, h * 0.33)),
    );

    // Label ruled lines
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.11, h * 0.13 + i * 7.0),
        Offset(w * 0.89, h * 0.13 + i * 7.0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 0.8,
      );
    }

    // Label shine strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.08, h * 0.05, w * 0.84, h * 0.06),
          const Radius.circular(7)),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    _drawText(canvas, title.isEmpty ? 'Voice Tape' : title,
        Offset(w * 0.5, h * 0.14),
        fontSize: 10, bold: true, maxWidth: w * 0.78);

    _drawText(canvas, 'by $sender', Offset(w * 0.5, h * 0.26),
        fontSize: 8, color: Colors.white70, maxWidth: w * 0.78);

    // ── TAPE WINDOW ───────────────────────────────────────
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.84, h * 0.48),
      const Radius.circular(10),
    );
    canvas.drawRRect(
        windowRect, Paint()..color = const Color(0xFF0C0C0C));
    canvas.drawRRect(
        windowRect,
        Paint()
          ..color = const Color(0xFF303030)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Window inner surface
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.46, w * 0.8, h * 0.44),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF0A0A0A),
    );

    // ── REELS ─────────────────────────────────────────────
    final leftCenter = Offset(w * 0.31, h * 0.685);
    final rightCenter = Offset(w * 0.69, h * 0.685);
    final leftRadius = (22.0 - progress * 8).clamp(12.0, 22.0);
    final rightRadius = (13.0 + progress * 8).clamp(13.0, 23.0);

    _drawReel(canvas, leftCenter, leftRadius, -rotation * 0.6, isFinished);
    _drawReel(canvas, rightCenter, rightRadius, rotation, isFinished);

    // Tape path
    final tapePaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(leftCenter.dx, leftCenter.dy + leftRadius),
        Offset(leftCenter.dx, h * 0.89), tapePaint);
    canvas.drawLine(Offset(leftCenter.dx, h * 0.89),
        Offset(rightCenter.dx, h * 0.89), tapePaint);
    canvas.drawLine(Offset(rightCenter.dx, h * 0.89),
        Offset(rightCenter.dx, rightCenter.dy + rightRadius), tapePaint);

    // ── SCREWS ────────────────────────────────────────────
    _drawScrew(canvas, Offset(w * 0.065, h * 0.075));
    _drawScrew(canvas, Offset(w * 0.935, h * 0.075));
    _drawScrew(canvas, Offset(w * 0.065, h * 0.925));
    _drawScrew(canvas, Offset(w * 0.935, h * 0.925));

    // Bottom center notch
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.91, w * 0.24, h * 0.08),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF111111),
    );

    // Winding glow
    if (isWinding) {
      canvas.drawRRect(bodyRect,
          Paint()
            ..color = tapeColor.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }

    if (isFinished) {
      canvas.drawRRect(bodyRect,
          Paint()
            ..color = _mint.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
  }

  void _drawReel(Canvas canvas, Offset center, double radius,
      double rot, bool finished) {
    canvas.drawCircle(
        Offset(center.dx + 1, center.dy + 1),
        radius,
        Paint()..color = Colors.black54);

    canvas.drawCircle(
        center, radius, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = finished
              ? _mint.withValues(alpha: 0.8)
              : const Color(0xFF4A4A4A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < 3; i++) {
      final a = i * 2 * math.pi / 3;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * 0.62 * math.cos(a),
            center.dy + radius * 0.62 * math.sin(a)),
        Paint()
          ..color = finished ? _mint : const Color(0xFF686868)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();

    canvas.drawCircle(center, radius * 0.28,
        Paint()..color = finished ? _mint : const Color(0xFF555555));
    canvas.drawCircle(center, radius * 0.14,
        Paint()..color = const Color(0xFF0D0D0D));
  }

  void _drawScrew(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 5, Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(
        c,
        5,
        Paint()
          ..color = const Color(0xFF505050)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawLine(Offset(c.dx - 2.5, c.dy), Offset(c.dx + 2.5, c.dy),
        Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 1.2);
    canvas.drawLine(Offset(c.dx, c.dy - 2.5), Offset(c.dx, c.dy + 2.5),
        Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 1.2);
  }

  void _drawText(Canvas canvas, String text, Offset center,
      {double fontSize = 10,
      bool bold = false,
      Color color = Colors.white,
      double maxWidth = 200}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    tp.layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(CassettePainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.isFinished != isFinished ||
      old.isWinding != isWinding;
}

// ═══════════════════════════════════════════════════════════
// WINDING WHEEL PAINTER
// ═══════════════════════════════════════════════════════════
class WindingWheelPainter extends CustomPainter {
  final double rotation;
  final bool isWinding;
  final Color color;
  final bool isFinished;

  // Aesthetic colors
  static const _mint = Color(0xFF5EEAD4);

  const WindingWheelPainter({
    required this.rotation,
    required this.isWinding,
    required this.color,
    required this.isFinished,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final activeColor = isFinished ? _mint : color;

    // Outer glow when winding or finished
    if (isWinding || isFinished) {
      canvas.drawCircle(
        center,
        radius + 8,
        Paint()
          ..color = activeColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }

    // Drop shadow
    canvas.drawCircle(
      Offset(center.dx + 2, center.dy + 3),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Body — radial gradient for 3D sphere look
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: const [Color(0xFF4A4A4A), Color(0xFF252525), Color(0xFF151515)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Outer ring gradient
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isFinished
            ? _mint
            : (isWinding ? color : const Color(0xFF4A4A4A))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── RIDGED EDGE (24 notches for smoother look) ────────
    const notchCount = 24;
    for (int i = 0; i < notchCount; i++) {
      final angle = (i / notchCount) * 2 * math.pi + rotation;
      final notchColor = isFinished
          ? _mint.withValues(alpha: 0.6)
          : (isWinding ? color.withValues(alpha: 0.6) : Colors.grey[600]!);
      canvas.drawLine(
        Offset(center.dx + (radius - 1) * math.cos(angle),
            center.dy + (radius - 1) * math.sin(angle)),
        Offset(center.dx + (radius - 8) * math.cos(angle),
            center.dy + (radius - 8) * math.sin(angle)),
        Paint()
          ..color = notchColor
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── ROTATING INNER DESIGN (6 spokes) ──────────────────
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final spokeColor = isFinished
          ? _mint
          : (isWinding ? color : const Color(0xFF484848));
      canvas.drawLine(
        Offset(center.dx + radius * 0.25 * math.cos(a),
            center.dy + radius * 0.25 * math.sin(a)),
        Offset(center.dx + radius * 0.55 * math.cos(a),
            center.dy + radius * 0.55 * math.sin(a)),
        Paint()
          ..color = spokeColor
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    // Center cap with gradient
    canvas.drawCircle(
      center,
      16,
      Paint()
        ..shader = RadialGradient(
          colors: isFinished || isWinding
              ? [activeColor, Color.lerp(activeColor, Colors.black, 0.5)!]
              : const [Color(0xFF3A3A3A), Color(0xFF252525)],
        ).createShader(Rect.fromCircle(center: center, radius: 16)),
    );
    
    // Inner hole
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF0A0A0A));

    // Shine arc
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(center.dx - 6, center.dy - 6),
          radius: radius * 0.5),
      -math.pi * 0.75,
      math.pi * 0.45,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(WindingWheelPainter old) =>
      old.rotation != rotation ||
      old.isWinding != isWinding ||
      old.isFinished != isFinished ||
      old.color != color;
}