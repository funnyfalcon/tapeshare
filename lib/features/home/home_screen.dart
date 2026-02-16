import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapeshare/features/player/player_screen.dart';
import '../recordings/recordings_screen.dart'; // Import the recording screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';

  // Runs once when the screen loads — reads saved username
  @override
  void initState() {
    super.initState();
    _loadUsername();
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
      leading: Icon(icon, color: Colors.orange),
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
      backgroundColor: const Color(0xFF0D0D1A), // dark background
      body: SafeArea(
        child: Column(
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
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.orange, size: 16),
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
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // ── MIDDLE: APP TITLE ─────────────────────────────
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎙', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 12),
                  Text(
                    'TapeShare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Record. Share. Wind to hear.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ),
            // ── BOTTOM: RECORD BUTTON ─────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                children: [
                  const Text(
                    'Tap to start recording',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      if (_username.isEmpty) {
                        // Force username before recording
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please set a username first!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        _showUsernameDialog();
                        return;
                      }
                      // Navigate to recording screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecordingScreen(username: _username),
                        ),
                      );
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 52),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
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
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                // Extract tape ID from full link or raw ID
                final tapeId = input.contains('/')
                    ? input.split('/').last
                    : input;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(tapeId: tapeId),
                  ),
                );
              }
            },
            child: const Text('Open', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}