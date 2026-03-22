# Breathe — Meditation & Breathing App

A complete, evidence-based iOS meditation app built with SwiftUI. Combines the best features from breathing research literature into a single, beautifully simple app.

## Features

### 9 Research-Backed Breathing Techniques

| Technique | Pattern | Primary Benefit | Source |
|---|---|---|---|
| **Box Breathing** | 4-4-4-4 | Focus & stress | Navy SEALs / Dr. Mark Divine |
| **4-7-8 Breathing** | 4-7-8 | Relaxation & sleep | Dr. Andrew Weil |
| **Coherent Breathing** | 5.5-5.5 | Max HRV | Stephen Elliott / James Nestor |
| **Wim Hof Method** | 30 breaths + retention | Energy & immunity | Wim Hof Institute |
| **Triangle Breathing** | 4-4-4 | Anxiety relief | Yoga tradition |
| **2:1 Breathing** | 4-8 | Parasympathetic activation | Pranayama / HRV research |
| **Diaphragmatic** | 4-6 | Foundation breath | Universal consensus |
| **Cardiac Coherence** | 5-5 | Heart rhythm sync | HeartMath Institute |
| **Physiological Sigh** | Double inhale + long exhale | Fastest anxiety relief | Stanford / Dr. Andrew Huberman |

### Session Features
- **Animated breathing circle** — expands on inhale, contracts on exhale, glows by phase
- **Live countdown** inside the circle with phase progress arc
- **Dynamic background** — shifts color with each phase (blue→inhale, purple→exhale)
- **Voice cues** — spoken instructions via AVSpeechSynthesizer ("Breathe In", "Breathe Out", "Hold")
- **Transition tones** — soft bell sounds at each phase change
- **Pause/resume** with session continuity
- **Session save** — auto-saves on completion or early exit

### Audio
- Voice cues using on-device TTS (no network required)
- Ambient sound options: Rain, Ocean Waves, Forest, White Noise, Tibetan Bowl, Soft Piano
- Independent volume controls for voice and ambient
- Background audio — continues when screen locks (`UIBackgroundModes: audio`)

### Session History
- All sessions persisted to UserDefaults (JSON encoded)
- Sessions grouped by day (Today / Yesterday / N days ago)
- Completion rings showing % of target duration completed
- Stats: total sessions, total minutes, current streak, longest streak, favorite technique

### Settings
- Toggle voice cues on/off
- Toggle transition tones on/off
- Voice & ambient volume sliders
- Keep screen on during sessions
- Haptic feedback toggle
- Daily reminder (local notification)
- Technique reference guide

## Project Structure

```
MeditationApp/
├── MeditationApp.xcodeproj/
│   └── project.pbxproj
└── MeditationApp/
    ├── MeditationApp.swift       # @main entry point
    ├── ContentView.swift         # Tab navigation
    ├── Info.plist
    ├── Models/
    │   ├── BreathingTechnique.swift   # Technique library + phase data
    │   └── MeditationSession.swift    # Session model + stats
    ├── Managers/
    │   ├── AudioManager.swift         # AVFoundation + TTS
    │   ├── SessionManager.swift       # Persistence + statistics
    │   └── BreathingPhaseManager.swift # Timer + phase transitions
    ├── Views/
    │   ├── HomeView.swift             # Technique/duration/sound picker
    │   ├── BreathingSessionView.swift # Full-screen session UI
    │   ├── BreathingCircleView.swift  # Animated breathing orb
    │   ├── TechniqueDetailView.swift  # Technique info sheet
    │   ├── HistoryView.swift          # Session history + stats
    │   └── SettingsView.swift         # App settings
    └── Resources/
        └── Assets.xcassets/
            ├── AccentTeal.colorset    # #33E5D8 primary accent
            ├── BackgroundDeep.colorset
            ├── InhaleColor.colorset
            ├── ExhaleColor.colorset
            └── HoldColor.colorset
```

## Requirements
- Xcode 15+
- iOS 17.0+
- Swift 5.9+

## Setup

1. Open `MeditationApp.xcodeproj` in Xcode
2. Set your Team in Signing & Capabilities
3. Build and run on device or simulator

### Optional: Add Ambient Sound Files

Add `.mp3` or `.wav` files to the Resources group matching these names:
- `rain_ambient`
- `ocean_ambient`
- `forest_ambient`
- `whitenoise_ambient`
- `tibetan_bowl_ambient`
- `piano_ambient`

Without audio files, the app functions fully — ambient sound plays silence, voice cues and tones still work.

### Optional: Add Transition Tone Files

- `tone_inhale.wav`
- `tone_exhale.wav`
- `tone_hold.wav`

Without these files the app falls back to system sounds (`AudioServicesPlaySystemSound`).

## Design Notes

- **Dark-only** UI — optimal for low-light meditation environments
- **50ms timer tick** for smooth circle animation
- **Wim Hof special mode** — separate state machine for 30-breath rounds + retention
- All audio runs on `.playback` AVAudioSession with `.duckOthers` so music apps lower when cues fire
- Sessions are saved even when the user exits early; completion percentage is tracked
