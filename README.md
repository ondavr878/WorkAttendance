# Work Attendance 📍

A modern iOS app for tracking work attendance with biometric authentication, location verification, and real-time widgets.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-yellow.svg)
![SwiftData](https://img.shields.io/badge/SwiftData-Enabled-green.svg)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔐 **Multi-Auth** | Phone OTP, Email/Password, Google Sign-In, Anonymous |
| 👤 **Biometric Security** | FaceID/TouchID before check-in/out |
| 📍 **Geo-Fencing** | Office proximity validation (configurable radius) |
| ⏱️ **Live Activity** | Dynamic Island timer during work session |
| 🔔 **Smart Reminders** | Check-in/out notifications + geo-triggered alerts |
| ☁️ **Cloud Sync** | Firebase Firestore with local SwiftData fallback |
| 📊 **Monthly Reports** | Track hours, averages, and work patterns |

---

## 📱 Screenshots

| Home | Auth | Widget |
|------|------|--------|
| Check-in/out with live timer | Dark glassmorphism design | Real-time status |

---

## 🏗️ Architecture

```
Work Attendance/
├── Models/
│   ├── Attendance.swift          # SwiftData model
│   └── AttendanceAttributes.swift # Live Activity
├── Services/
│   ├── AuthManager.swift         # Firebase auth state
│   ├── AuthService.swift         # Auth operations
│   ├── LocalAttendanceRepository.swift  # SwiftData
│   ├── RemoteAttendanceRepository.swift # Firestore
│   ├── LocationManager.swift     # Geo-fencing
│   ├── NotificationManager.swift # Reminders
│   └── BiometricService.swift    # FaceID/TouchID
├── ViewModels/
│   ├── AttendanceViewModel.swift
│   ├── AuthViewModel.swift
│   └── MonthlyMonitoringViewModel.swift
├── Views/
│   ├── AuthView.swift
│   ├── HomeView.swift
│   ├── SettingsView.swift
│   └── MonthlyMonitoringView.swift
└── AttendanceWidget/
    └── AttendanceWidget.swift    # Home screen + Dynamic Island
```

---

## ⚙️ Setup

### Prerequisites
- Xcode 15+
- iOS 17.0+
- Firebase Project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/WorkAttendance.git
   cd WorkAttendance
   ```

2. **Configure Firebase**
   - Add `GoogleService-Info.plist` to the project
   - Enable Phone, Email, and Google auth in Firebase Console

3. **Update App Group**
   - Replace `group.com.yourname.WorkAttendance` with your identifier
   - Update in both main app and widget extension entitlements

4. **Build & Run**
   ```bash
   open "Work Attendance.xcodeproj"
   ```

---

## 🔧 Configuration

### Office Location
Settings → Office Location → Tap on map to set coordinates

### Data Storage
Settings → Data Storage → Choose Local or Cloud

### Notifications
Automatic reminders:
- Check-in: 9:15 AM
- Check-out: 5:45 PM
- Incomplete session: 7:00 PM

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| Firebase Auth | Authentication |
| Firebase Firestore | Cloud database |
| GoogleSignIn | OAuth |
| SwiftData | Local persistence |
| WidgetKit | Home screen widget |
| ActivityKit | Live Activity |
| LocalAuthentication | Biometrics |
| CoreLocation | Geo-fencing |

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👨‍💻 Author

**Davron Usmanov**  
Built with ❤️ using SwiftUI
