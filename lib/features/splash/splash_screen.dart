import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({required this.onComplete, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Wave animation - continuous
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Scale animation for logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _startAnimation();
  }
  
  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _scaleController.forward();
    
    // Wait for splash to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    widget.onComplete();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
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
              Color(0xFF0D0D1A),
              Color(0xFF1A0A20),
              Color(0xFF0A1A1A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Waveform animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 280,
                  height: 80,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          progress: _waveController.value,
                          color1: const Color(0xFFFF6B9D), // Pink
                          color2: const Color(0xFF4ECDC4), // Cyan
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    '📼',
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // App name
              FadeTransition(
                opacity: _fadeAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFF6B9D),
                      Color(0xFF4ECDC4),
                      Color(0xFFFFB347),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'TapeShare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Wind to hear',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  WaveformPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 24;
    final barWidth = size.width / (barCount * 2);
    final maxHeight = size.height * 0.8;
    
    for (int i = 0; i < barCount; i++) {
      // Create wave effect with phase offset
      final phase = (progress * 2 * math.pi) + (i * 0.3);
      final heightFactor = 0.3 + 0.7 * ((math.sin(phase) + 1) / 2);
      final barHeight = maxHeight * heightFactor;
      
      // Gradient color based on position
      final t = i / (barCount - 1);
      final color = Color.lerp(color1, color2, t)!;
      
      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      
      final x = i * (barWidth * 2) + barWidth / 2;
      final y = (size.height - barHeight) / 2;
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
