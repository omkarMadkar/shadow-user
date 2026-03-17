# Shadow Sentinel — Zero Trust Continuous Authentication Platform

A Flutter desktop application for real-time cybersecurity monitoring with behavioral biometrics simulation.

![Flutter](https://img.shields.io/badge/Flutter-3.32+-blue) ![Dart](https://img.shields.io/badge/Dart-3.8+-blue) ![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-green)

---

## Features

- **Trust Score Gauge** — Animated radial dial (CustomPaint) showing live Identity Confidence (0-100%)
- **Sentinel Modules** — Keystroke Monitor (WPM, drift, pattern) + Neural Image Detection (countdown, scan animation)
- **Live Event Log** — Terminal-style scrolling feed with severity badges (CRIT/WARN/OK/INFO)
- **Productivity Heatmap** — 5-day × 13-hour interactive grid (Deep Work, Focused, Distracted, Burnout Risk)
- **Threat Overview** — Active threat counts + online user roster with trust scores
- **Responsive Layout** — Wide (multi-column) and narrow (single-column) modes
- **"Zero Trust" Aesthetic** — Dark mode (#0A0E17), glassmorphism, cyber-blue neon accents, JetBrains Mono

---

## Prerequisites

1. **Flutter SDK** >= 3.22 — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Windows** — Visual Studio 2022 with "Desktop development with C++" workload
3. **macOS** — Xcode 15+ with command-line tools

Verify your setup:

```bash
flutter doctor
```

---

## Quick Start

### 1. Extract the ZIP

```
Unzip shadow_sentinel_flutter.zip to any directory.
```

### 2. Install Dependencies

```bash
cd shadow_sentinel_flutter
flutter pub get
```

### 3. Run the App

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

### 4. Build a Release Binary

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

The release binary will be in:

- **Windows:** `build\windows\x64\runner\Release\shadow_sentinel.exe`
- **macOS:** `build/macos/Build/Products/Release/shadow_sentinel.app`

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, Provider setup, navigation shell
├── models/
│   └── models.dart                    # All data classes and enums
├── providers/
│   └── sentinel_provider.dart         # Central state (~10 real-time timers)
├── theme/
│   └── sentinel_theme.dart            # Design system, colors, glass cards
├── screens/
│   ├── dashboard_screen.dart          # Main responsive dashboard layout
│   ├── email_threat_screen.dart       # Email fraud detection tab
│   └── neural_camera_screen.dart      # Neural camera monitoring tab
└── widgets/
    ├── camera_log_widget.dart         # Camera detection history timeline
    ├── email_stats_panel.dart         # Email scanning statistics panel
    ├── email_threat_card.dart         # Individual email threat card
    ├── event_log_terminal.dart        # Terminal-style event log
    ├── face_scan_widget.dart          # Animated face scan (radar + CustomPaint)
    ├── productivity_heatmap.dart      # 5x13 interactive heatmap
    ├── sentinel_header.dart           # Header bar with clock
    ├── sentinel_status_card.dart      # Module status cards
    ├── threat_overview_panel.dart     # Threats + online users
    └── trust_gauge.dart               # Radial dial (CustomPaint)
```

---

## State Management

Uses **Provider** (`ChangeNotifierProvider`) with a single `SentinelProvider` that:

- Manages 7 independent `Timer` instances for simulated real-time data
- Smoothly interpolates the trust score for fluid UI updates
- Generates security events from 15 templates with randomized parameters
- Tracks camera polling countdowns and captures
- Updates keystroke metrics (WPM, drift, hold time, flight time)
- Mutates threat counts and productivity heatmap cells

### Extending with Real Data

Replace the simulation timers in `SentinelProvider` with real `Stream<T>` connections:

```dart
void connectStreams({
  required Stream<KeystrokeMetrics> keystrokeStream,
  required Stream<NeuralScanResult> scanStream,
  required Stream<SecurityEvent> eventStream,
}) {
  keystrokeStream.listen(_onKeystrokeData);
  scanStream.listen(_onScanResult);
  eventStream.listen(_onSecurityEvent);
}
```

---

## Dependencies

| Package        | Version | Purpose                     |
| -------------- | ------- | --------------------------- |
| `provider`     | ^6.1.2  | State management            |
| `google_fonts` | ^6.2.1  | Inter + JetBrains Mono      |
| `ffi`          | ^2.1.3  | Native keyboard hook bridge |
| `fl_chart`     | ^0.69.2 | Future chart widgets        |
| `intl`         | ^0.19.0 | Timestamp formatting        |

---

## License

This is a prototype / proof-of-concept. Use at your own discretion.
