# 🎙 TapeShare

> *"Record. Share. Wind to hear."*

TapeShare is a Flutter-based mobile application that brings a nostalgic twist to voice messaging. Record voice messages and share them as virtual "cassette tapes" that recipients must physically wind to listen to - creating an engaging, gamified experience that makes voice sharing memorable.

[![Flutter](https://img.shields.io/badge/Flutter-3.11-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Features

### 🎤 Voice Recording
- **Hold-to-Record**: Intuitive long-press recording interface
- **Real-time Timer**: See recording duration as you speak
- **Visual Feedback**: Animated waveform and pulsing button animations
- **High-Quality Audio**: M4A format for optimal quality and compression

### 🎨 Tape Customization
- **Custom Titles**: Name your tapes (up to 30 characters)
- **Color Selection**: Choose from 6 vibrant color options
- **Sender Identity**: Automatically attach your username to each tape

### 🔗 Easy Sharing
- **Cloud Storage**: Automatic upload to secure cloud storage
- **Unique Links**: Each tape gets a unique shareable link
- **Multiple Share Options**: Copy to clipboard or share directly to social apps
- **Deep Linking**: Open tapes via `tapeshare://tape/{id}` URLs

### 🎵 Interactive Playback
- **Wind-to-Play Mechanic**: Novel circular gesture-based playback
- **Visual Progress**: Animated tape spool with progress indicator
- **Anticipation & Reward**: Four full rotations unlock the message
- **Custom Animation**: Hand-crafted CustomPainter for authentic tape reel visuals

### 👤 User Management
- **Persistent Identity**: Username stored locally across sessions
- **Play Tracking**: Monitor how many times your tapes are played

## 🛠 Technology Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material Design 3** - Modern UI components

### Backend & Services
- **Firebase Firestore** - NoSQL database for tape metadata
- **Supabase Storage** - Scalable audio file storage
- **Firebase Core** - Backend initialization and configuration

### Key Packages
| Package | Purpose |
|---------|---------|
| `firebase_core` & `cloud_firestore` | Database operations |
| `supabase_flutter` | File storage and management |
| `record` | Audio recording functionality |
| `just_audio` | High-quality audio playback |
| `permission_handler` | Microphone permissions |
| `share_plus` | Native share functionality |
| `shared_preferences` | Local data persistence |
| `uuid` | Unique identifier generation |

## 📱 Screenshots

> *Add screenshots of your app here*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.11 or higher)
- Dart SDK (3.0 or higher)
- Firebase project with Firestore enabled
- Supabase account with storage bucket configured
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/funnyfalcon/tapeshare.git
   cd tapeshare
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore Database
   - Download and add configuration files:
     - Android: `google-services.json` → `android/app/`
     - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Run FlutterFire CLI to generate `firebase_options.dart`:
     ```bash
     flutterfire configure
     ```

4. **Configure Supabase**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Create a storage bucket named `tapes` with public access
   - Update `lib/main.dart` with your Supabase credentials:
     ```dart
     await Supabase.initialize(
       url: 'YOUR_SUPABASE_URL',
       anonKey: 'YOUR_SUPABASE_ANON_KEY',
     );
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📖 Usage

### Recording a Tape

1. Open the app and set your username on the home screen
2. Tap the **"Record a Tape"** button
3. **Hold** the record button to start recording
4. **Release** to stop recording
5. Customize your tape with a title and color
6. Tap **"Share Tape"** to upload

### Sharing a Tape

1. After uploading, tap **"Copy Link"** to copy the shareable URL
2. Or use **"Share"** to send via social apps
3. Share the link with your recipient

### Playing a Tape

1. Open a tape link (or enter tape ID manually)
2. See the sender's name and tape title
3. **Wind the reel** by rotating your finger in a circle around the spool
4. Complete 4 full rotations to unlock playback
5. Audio plays automatically when complete

## 🏗 Project Structure

```
lib/
├── main.dart                      # App entry point, Firebase & Supabase init
├── firebase_options.dart          # Firebase configuration
├── core/                          # Core utilities and shared components
└── features/                      # Feature-based architecture
    ├── splash/
    │   └── splash_screen.dart     # Initial splash screen
    ├── home/
    │   └── home_screen.dart       # Main screen with username & navigation
    ├── recordings/
    │   ├── recordings_screen.dart # Recording functionality
    │   └── screen_share.dart      # Upload & share screen
    └── player/
        └── player_screen.dart     # Tape playback with wind gesture
```

## 🎯 How It Works

### Recording Flow
1. Request microphone permission
2. Start recording when long-press begins
3. Update timer and animate UI every second
4. Stop and save recording on release
5. Navigate to share screen with audio file

### Upload Flow
1. Generate unique UUID for tape
2. Read audio file as bytes
3. Upload to Supabase storage bucket
4. Get public URL for uploaded file
5. Store metadata in Firestore
6. Generate shareable link

### Playback Flow
1. Fetch tape metadata from Firestore
2. Display tape information and spool UI
3. Track circular gesture using trigonometry
4. Calculate rotation progress (4 rotations = 100%)
5. Seek audio based on progress percentage
6. Play audio when winding is complete
7. Increment play count in Firestore

### Wind-to-Play Algorithm

The innovative winding mechanic uses polar coordinate mathematics:

```dart
// Calculate angle from center point
final angle = atan2(dy, dx);

// Track rotation delta (handling π to -π wraparound)
double delta = newAngle - currentAngle;
if (delta > π) delta -= 2π;
if (delta < -π) delta += 2π;

// Accumulate clockwise rotation only
if (delta > 0) totalRotation += delta;

// Calculate progress (4 full rotations = 100%)
progress = (totalRotation / (4 × 2π)).clamp(0.0, 1.0);
```

## 🔧 Configuration

### Firestore Structure

**Collection:** `tapes`

**Document Fields:**
```javascript
{
  id: String,              // Unique tape ID (UUID v4)
  audioUrl: String,        // Public URL to audio file
  sender: String,          // Username of sender
  title: String,           // Custom tape title
  color: String,           // Color value as string
  createdAt: Timestamp,    // Creation timestamp
  playCount: Number        // Number of times played
}
```

### Supabase Storage

**Bucket:** `tapes`
- **Access:** Public
- **File Format:** M4A (AAC encoding)
- **Naming:** `{uuid}.m4a`

## 🔐 Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record voice messages</string>
```

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 🚀 Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🎓 Learning Resources

- [TapeShare Presentation Guide](TapeShare_Presentation_Guide.md) - Detailed technical documentation and Q&A
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Supabase Documentation](https://supabase.com/docs)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **funnyfalcon** - *Initial work* - [@funnyfalcon](https://github.com/funnyfalcon)

## 🙏 Acknowledgments

- Inspired by the nostalgic experience of cassette tapes
- Built with ❤️ using Flutter
- Thanks to the Flutter and Firebase communities

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

**Made with Flutter 💙**
