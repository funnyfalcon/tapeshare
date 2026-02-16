import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapeshare/features/player/player_screen.dart';
import 'package:tapeshare/core/page_transitions.dart';
import '../recordings/recordings_screen.dart'; // Import the recording screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _username = '';
  late AnimationController _reelController;

  // Aesthetic colors
  static const _pink = Color(0xFFFF6B9D);
  static const _cyan = Color(0xFF4ECDC4);
  static const _peach = Color(0xFFFFB347);
  static const _lavender = Color(0xFFB19CD9);

  // Runs once when the screen loads — reads saved username
  @override
  void initState() {
    super.initState();
    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadUsername();
  }

  @override
  void dispose() {
    _reelController.dispose();
    super.dispose();
  }

  // Load username from device storage
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  // Save username to device storage
  Future<void> _saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    setState(() => _username = name);
  }

  // Popup dialog where user types their username
  void _showUsernameDialog() {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Set Your Username',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a username...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
            counterStyle: TextStyle(color: Colors.grey[500]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _saveUsername(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Bottom sheet options menu
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar at top
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _optionTile(Icons.person_outline, 'Change Username', _showUsernameDialog),
            _optionTile(Icons.play_circle_outline, 'Open a Tape', _showOpenTapeDialog),
            _optionTile(Icons.info_outline, 'About TapeShare', () {}),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Helper to build each row in the options menu
  Widget _optionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _pink),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () {
        Navigator.pop(context); // close the bottom sheet first
        onTap();
      },
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
              Color(0xFF0D0D1A),
              Color(0xFF1A0F1E),
              Color(0xFF0F1A1A),
              Color(0xFF0D0D1A),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating decorative elements
              ..._buildFloatingDecorations(),
              
              // Main content
              Column(
                children: [
                  // ── TOP BAR ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Username chip (tap to change)
                        GestureDetector(
                          onTap: _showUsernameDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _pink.withValues(alpha: 0.15),
                                  _cyan.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _pink.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: _pink, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _username.isEmpty ? 'Set Username' : _username,
                                  style: TextStyle(
                                    color: _username.isEmpty ? Colors.grey : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit, color: Colors.grey[600], size: 12),
                              ],
                            ),
                          ),
                        ),
                        // Options menu button
                        GestureDetector(
                          onTap: _showOptionsMenu,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _cyan.withValues(alpha: 0.15),
                                  _lavender.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _cyan.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.menu, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // ── MIDDLE: ANIMATED CASSETTE ─────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Cassette
                        AnimatedBuilder(
                          animation: _reelController,
                          builder: (context, child) {
                            return SizedBox(
                              width: 280,
                              height: 180,
                              child: CustomPaint(
                                painter: HomeCassettePainter(
                                  rotation: _reelController.value * 2 * math.pi,
                                  primaryColor: _pink,
                                  secondaryColor: _cyan,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // App name with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_pink, _cyan, _peach],
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
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Record. Share. Wind to hear.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  
                  // ── BOTTOM: RECORD BUTTON ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Column(
                      children: [
                        Text(
                          'Tap to start recording',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            if (_username.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please set a username first!'),
                                  backgroundColor: _pink,
                                ),
                              );
                              _showUsernameDialog();
                              return;
                            }
                            Navigator.push(
                              context,
                              SmoothPageRoute(page: RecordingScreen(username: _username)),
                            );
                          },
                          child: Hero(
                            tag: 'record_button',
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_pink, _peach],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pink.withValues(alpha: 0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.mic, color: Colors.white, size: 52),
                            ),
                          ),
                        ),
                      ],
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

  List<Widget> _buildFloatingDecorations() {
    return [
      // Top left glow
      Positioned(
        top: -50,
        left: -50,
        child: Container(
          width: 200,
          height: 200,
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
      // Bottom right glow
      Positioned(
        bottom: -80,
        right: -80,
        child: Container(
          width: 250,
          height: 250,
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
      // Center accent
      Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        right: -100,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _lavender.withValues(alpha: 0.08),
                _lavender.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  void _showOpenTapeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Open a Tape',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Paste tape ID here...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _pink),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _pink, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
            ),
            onPressed: () {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                final tapeId = input.contains('/')
                    ? input.split('/').last
                    : input;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  ScalePageRoute(page: PlayerScreen(tapeId: tapeId)),
                );
              }
            },
            child: const Text('Open', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HOME CASSETTE PAINTER - Animated cassette with spinning reels
// ═══════════════════════════════════════════════════════════
class HomeCassettePainter extends CustomPainter {
  final double rotation;
  final Color primaryColor;
  final Color secondaryColor;

  const HomeCassettePainter({
    required this.rotation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cassette body with gradient
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(16),
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 6, w, h),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Body gradient
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A3A),
            const Color(0xFF1A1A2A),
            const Color(0xFF252535),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Border glow
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.4),
            secondaryColor.withValues(alpha: 0.4),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Label area
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.35),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      labelRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ).createShader(Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.35)),
    );

    // Label lines
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.12, h * 0.15 + i * 8.0),
        Offset(w * 0.88, h * 0.15 + i * 8.0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
    }

    // Tape window
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.52, w * 0.7, h * 0.36),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      windowRect,
      Paint()..color = const Color(0xFF0A0A12),
    );
    canvas.drawRRect(
      windowRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Spinning reels
    _drawReel(canvas, Offset(w * 0.32, h * 0.70), 28, rotation, primaryColor);
    _drawReel(canvas, Offset(w * 0.68, h * 0.70), 28, -rotation, secondaryColor);

    // Tape between reels
    canvas.drawLine(
      Offset(w * 0.32, h * 0.70 - 28),
      Offset(w * 0.68, h * 0.70 - 28),
      Paint()
        ..color = const Color(0xFF3A3A4A)
        ..strokeWidth = 3,
    );
  }

  void _drawReel(Canvas canvas, Offset center, double radius, double rot, Color color) {
    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF1A1A2A),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner detail
    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()..color = const Color(0xFF0D0D18),
    );

    // Rotating spokes
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < 3; i++) {
      final angle = i * (2 * math.pi / 3);
      canvas.drawLine(
        center,
        Offset(
          center.dx + (radius * 0.55) * math.cos(angle),
          center.dy + (radius * 0.55) * math.sin(angle),
        ),
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    // Center dot
    canvas.drawCircle(center, 6, Paint()..color = color);
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF0A0A12));
  }

  @override
  bool shouldRepaint(HomeCassettePainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}