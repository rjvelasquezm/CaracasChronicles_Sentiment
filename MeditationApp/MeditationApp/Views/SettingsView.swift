import SwiftUI

struct SettingsView: View {
    @ObservedObject private var audioManager = AudioManager.shared
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("keepScreenOn") private var keepScreenOn = true
    @AppStorage("defaultDuration") private var defaultDuration = 300
    @AppStorage("defaultSound") private var defaultSoundRaw = AmbientSound.rain.rawValue
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 7
    @AppStorage("reminderMinute") private var reminderMinute = 30

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.07, blue: 0.14),
                             Color(red: 0.03, green: 0.12, blue: 0.18)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Audio
                        SettingsSection(title: "Audio") {
                            SettingsToggleRow(
                                icon: "waveform.and.person.filled",
                                title: "Voice Cues",
                                subtitle: "Spoken breathing instructions",
                                isOn: $audioManager.isVoiceEnabled
                            )
                            SettingsDivider()
                            SettingsToggleRow(
                                icon: "bell.and.waveform.fill",
                                title: "Transition Tones",
                                subtitle: "Soft bell at phase changes",
                                isOn: $audioManager.isToneEnabled
                            )
                            SettingsDivider()
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color("AccentTeal"))
                                        .frame(width: 28)
                                    Text("Voice Volume")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(audioManager.cueVolume * 100))%")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Slider(value: $audioManager.cueVolume, in: 0...1)
                                    .accentColor(Color("AccentTeal"))
                            }
                            .padding(.vertical, 4)
                            SettingsDivider()
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "cloud.rain.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color("AccentTeal"))
                                        .frame(width: 28)
                                    Text("Ambient Volume")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(audioManager.ambientVolume * 100))%")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Slider(value: $audioManager.ambientVolume, in: 0...1)
                                    .accentColor(Color("AccentTeal"))
                            }
                            .padding(.vertical, 4)
                        }

                        // Session Defaults
                        SettingsSection(title: "Session Defaults") {
                            SettingsToggleRow(
                                icon: "iphone.and.arrow.forward",
                                title: "Keep Screen On",
                                subtitle: "Prevent auto-lock during sessions",
                                isOn: $keepScreenOn
                            )
                            SettingsDivider()
                            SettingsToggleRow(
                                icon: "hand.tap.fill",
                                title: "Haptic Feedback",
                                subtitle: "Subtle vibration at phase changes",
                                isOn: $hapticEnabled
                            )
                        }

                        // Daily Reminder
                        SettingsSection(title: "Daily Reminder") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Daily Reminder",
                                subtitle: "Gentle nudge to practice",
                                isOn: $reminderEnabled
                            )
                            if reminderEnabled {
                                SettingsDivider()
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color("AccentTeal"))
                                        .frame(width: 28)
                                    Text("Reminder Time")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    DatePicker(
                                        "",
                                        selection: reminderBinding,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                }
                            }
                        }

                        // Technique Reference
                        SettingsSection(title: "Technique Reference") {
                            ForEach(BreathingTechnique.allTechniques) { technique in
                                TechniqueRefRow(technique: technique)
                                if technique.id != BreathingTechnique.allTechniques.last?.id {
                                    SettingsDivider()
                                }
                            }
                        }

                        // About
                        SettingsSection(title: "About") {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color("AccentTeal"))
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Breathe — Meditation & Breathing")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    Text("Version 1.0  ·  Evidence-based techniques")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var reminderBinding: Binding<Date> {
        Binding(
            get: {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                reminderHour = Calendar.current.component(.hour, from: date)
                reminderMinute = Calendar.current.component(.minute, from: date)
            }
        )
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.leading, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(14)
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.white.opacity(0.08))
            .padding(.vertical, 8)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("AccentTeal"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color("AccentTeal"))
        }
    }
}

struct TechniqueRefRow: View {
    let technique: BreathingTechnique

    var patternText: String {
        technique.phases.map { p in
            "\(p.type.shortInstruction) \(Int(p.duration))s"
        }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: technique.systemIcon)
                .font(.system(size: 15))
                .foregroundColor(Color("AccentTeal"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(technique.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(patternText)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer()

            DifficultyBadge(difficulty: technique.difficulty)
        }
    }
}
