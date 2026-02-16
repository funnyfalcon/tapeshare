import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapeshare/core/page_transitions.dart';
import 'screen_share.dart';

class RecordingScreen extends StatefulWidget {
  final String username;
  const RecordingScreen({required this.username, super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  // Complementary colors - Mint/Emerald theme
  static const _mint = Color(0xFF5EEAD4);
  static const _emerald = Color(0xFF34D399);
  static const _coral = Color(0xFFFF7F7F);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController.stop();
  }

  String get _timeDisplay {
    final mins = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();

    if (!mounted) return;

    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission is required!'),
          backgroundColor: _coral,
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/tape_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });

    setState(() => _isRecording = true);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isRecording = false;
      _secondsElapsed = 0;
    });

    if (path != null && mounted) {
      Navigator.push(
        context,
        SmoothPageRoute(
          page: ShareScreen(
            filePath: path,
            username: widget.username,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
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
              Color(0xFF0D1A1A),
              Color(0xFF0A1515),
              Color(0xFF0D1A18),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating decorations
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
                        const Text(
                          'New Tape',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Status text with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: _isRecording 
                          ? [_coral, const Color(0xFFFF6B6B)]
                          : [_mint, _emerald],
                    ).createShader(bounds),
                    child: Text(
                      _isRecording ? 'Recording...' : 'Hold to Record',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Time display
                  Text(
                    _timeDisplay,
                    style: TextStyle(
                      color: _isRecording ? Colors.white : Colors.grey[600],
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 4,
                    ),
                  ),

                  const Spacer(),

                  // Waveform visualization
                  if (_isRecording)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return SizedBox(
                          height: 80,
                          child: CustomPaint(
                            size: Size(MediaQuery.of(context).size.width - 80, 80),
                            painter: WaveformVisualizerPainter(
                              progress: _waveController.value,
                              color1: _mint,
                              color2: _emerald,
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 40),

                  // Record button
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: Hero(
                      tag: 'record_button',
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isRecording ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _isRecording 
                                      ? [_coral, const Color(0xFFFF5252)]
                                      : [_mint, _emerald],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? _coral : _mint)
                                        .withValues(alpha: 0.5),
                                    blurRadius: _isRecording ? 40 : 25,
                                    spreadRadius: _isRecording ? 10 : 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    _isRecording ? 'Release to stop' : 'Press and hold the button',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),

                  const Spacer(),
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
        top: -60,
        right: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _mint.withValues(alpha: 0.15),
                _mint.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      // Bottom left glow
      Positioned(
        bottom: -80,
        left: -80,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _emerald.withValues(alpha: 0.12),
                _emerald.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      // Center accent
      if (_isRecording)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _coral.withValues(alpha: 0.1),
                  _coral.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}

// Waveform visualizer painter
class WaveformVisualizerPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  WaveformVisualizerPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 30;
    final barWidth = size.width / (barCount * 1.8);
    final maxHeight = size.height * 0.9;

    for (int i = 0; i < barCount; i++) {
      final phase = (progress * 2 * math.pi) + (i * 0.25);
      final heightFactor = 0.2 + 0.8 * ((math.sin(phase) + 1) / 2);
      final barHeight = maxHeight * heightFactor;

      final t = i / (barCount - 1);
      final color = Color.lerp(color1, color2, t)!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      final x = i * (barWidth * 1.8) + barWidth / 2;
      final y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformVisualizerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}