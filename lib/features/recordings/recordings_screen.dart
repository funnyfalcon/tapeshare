import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screen_share.dart';

class RecordingScreen extends StatefulWidget {
  final String username;
  const RecordingScreen({required this.username, super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _savedFilePath;
  int _secondsElapsed = 0;
  Timer? _timer;

  // Animation for the pulsing glow effect while recording
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    _pulseController.stop(); // only animate while recording
  }

  // Format seconds into mm:ss display
  String get _timeDisplay {
    final mins = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _startRecording() async {
    // Ask for microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get a path to save the file
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/tape_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Start recording
    await _recorder.start(const RecordConfig(), path: path);

    // Start the timer
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
      _savedFilePath = path;
      _secondsElapsed = 0;
    });

    // Go to share screen with the saved file
    if (path != null && mounted) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShareScreen(
              filePath: path,
              username: widget.username,
            ),
          ),
        );
}
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _pulseController.dispose();
    _timer?.cancel();
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
          'New Tape',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const Spacer(),

          // ── STATUS TEXT ───────────────────────────────────
          Text(
            _isRecording ? 'Recording...' : 'Hold to Record',
            style: TextStyle(
              color: _isRecording ? Colors.orange : Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // ── TIMER ─────────────────────────────────────────
          Text(
            _timeDisplay,
            style: TextStyle(
              color: _isRecording ? Colors.white : Colors.grey[700],
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const Spacer(),

          // ── WAVEFORM BARS (decorative) ────────────────────
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(20, (i) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + (i * 30)),
                    width: 4,
                    height: _isRecording ? (10 + (i % 5) * 12).toDouble() : 4,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),

          const SizedBox(height: 40),

          // ── HOLD TO RECORD BUTTON ─────────────────────────
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
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
                      color: _isRecording
                          ? Colors.red
                          : Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.orange)
                              .withOpacity(0.5),
                          blurRadius: _isRecording ? 40 : 20,
                          spreadRadius: _isRecording ? 10 : 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _isRecording
                ? 'Release to stop'
                : 'Press and hold the button',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),

          const Spacer(),

          ],
        ),
      ),
    );
  }
}