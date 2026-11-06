# IIT JAM & CUET-PG Academic Android App 📐

A high-performance, buttery-smooth Android application for **IIT JAM Mathematics (MA)** and **CUET-PG Mathematics** aspirants.

<p align="center">
  <a href="https://github.com/vaibhavgeometer/Vaibhav-Android-App/releases/latest">
    <img src="https://img.shields.io/badge/Download-Latest%20Android%20APK-2ea44f?style=for-the-badge&logo=android&logoColor=white" alt="Download Latest Android APK" height="42">
  </a>
  &nbsp;&nbsp;
  <a href="https://github.com/vaibhavgeometer/Vaibhav-Android-App/releases">
    <img src="https://img.shields.io/badge/Releases-All%20Versions-blue?style=for-the-badge&logo=github" alt="All Releases" height="42">
  </a>
</p>

Taking design and performance inspiration from **[lichess-org/mobile](https://github.com/lichess-org/mobile)**, this application is crafted with Flutter for a 60/120 FPS native experience, sleek dark-mode aesthetics, tactile haptic feedback, and an offline-first architecture with zero login barriers.

---

## 📥 Download & Installation

You can download and install the latest APK directly onto any Android device:

| File | Description | Download Link |
| :--- | :--- | :--- |
| **`app-release.apk`** | Production build (optimized, signed) | [**⬇️ Download Latest APK**](https://github.com/vaibhavgeometer/Vaibhav-Android-App/releases/latest) |
| **All Releases** | Previous builds & changelogs | [**📦 View Releases Archive**](https://github.com/vaibhavgeometer/Vaibhav-Android-App/releases) |

### 📱 How to Install:
1. Tap the **Download Latest Android APK** button above to download the `.apk` file to your device.
2. Open the downloaded file from your Downloads folder or notification tray.
3. If prompted by Android, enable **"Allow from this source"** (or *Install unknown apps* permission).
4. Tap **Install** and enjoy full offline access!

---

## 🚀 Key Features Ported from the Academic Portal

### 🏛️ 1. Complete 22-Year Mock Test Series (2005–2026)
* **58 Mock Test Suites** available offline:
  * **12 CBT Era Tests (2015–2026):** Full 60-question authentic examination pattern (MCQ, MSQ, and NAT).
  * **10 Classic Era Tests (2005–2014):** Subjective & objective transition archives.
  * **27 Subtopic Test Suites:** Focused topic drills across the 3 historical eras.
  * **9 Comprehensive Archive Topic Tests.**
* **Two Test Modes:**
  * **⚡ Official CBT Simulator:** Full timed exam with live countdown, question palette, question status tracking, and auto-submit.
  * **🎯 Practice Mode:** Untimed, self-paced exploration with instant review.

### ⚡ 2. Authentic CBT Exam Simulator
* **Interactive Option Selectors:**
  * **MCQ:** Single-choice radio selector with immediate selection feedback.
  * **MSQ:** Multi-select checkboxes with zero partial-marking penalty rules.
  * **NAT (Numerical Answer Type):** Numerical input pad and direct numeric input supporting exact values and ranges (e.g. `1.9 to 2.1`).
* **Official Question Palette:** Real-time color-coded question grid matching official examination conventions:
  * 🟢 **Answered**
  * 🔴 **Not Answered**
  * 🟣 **Marked for Review**
  * 🟣 (Badge) **Answered & Marked for Review**
  * ⚪ **Not Visited**
* **Instant Score Report & Review:**
  * Accurate official scoring rules (+1 / -0.33, +2 / -0.66, MSQ no negative, NAT no negative).
  * Overall score, percentage, accuracy rate, and time taken.
  * Question-by-question review with official screenshots, student responses, official master keys, and explanations.

### 🖩 3. Built-In Virtual Scientific Calculator
* Official IIT JAM examination style scientific calculator modal sheet.
* Trigonometric (`sin`, `cos`, `tan`), Inverse (`asin`, `acos`, `atan`), and Hyperbolic (`sinh`, `cosh`, `tanh`) functions.
* Radian and Degree angle modes.
* Logarithmic (`ln`, `log`), Exponential (`e^x`, `10^x`), and Power (`x^y`, `x^2`, `x^3`, `sqrt`, `cbrt`) functions.
* Memory registers (`MC`, `MR`, `MS`, `M+`, `M-`) and history expressions.

### 🎯 4. PYQ Tracker & Question Bank (885 Questions)
* Search and track all **885 official examination questions** across 22 years (2005–2026).
* **Instant Search:** Find questions instantly by Year and Question number (e.g. `2013 Q17`, `2005 7`), by Mathematical keyword (e.g. `differential equations`, `matrices`), or by unique question ID.
* **Filter Chips:** Filter by Solved, Unsolved, Out of Syllabus (87 questions), Core Topics, and Difficulty levels.
* **5-Level Difficulty Taxonomy:** Very Easy, Easy, Medium, Hard, and Hardest with exam-pattern fallback inference.
* **Persistent Progress:** All progress and notes are stored locally on the device using `SharedPreferences`.

### 📊 5. Study Statistics & Analytics
* **🔥 Active Streak Counter:** Tracks day-by-day solving streaks.
* **📈 Velocity Tracking:** Solved today, solved this week, and daily solving pace.
* **⏳ Finish Forecast:** Dynamically predicts syllabus completion date based on your solving velocity.
* **🎯 Topic Mastery Progress Bars:** Real Analysis (286 Qs), Multivariable Calculus & Differential Equations (257 Qs), and Linear Algebra & Algebra (255 Qs).
* **📊 22-Year Project Statistics Report:** Access the comprehensive empirical study report PDF directly inside the app.

### 📚 6. Study Materials Hub & CUET-PG Archive (Exact Website Parity)
* **⏳ IIT JAM 2027 Live Countdown:** Real-time ticking countdown timer targeting Sunday, February 14, 2027 (09:30 AM IST).
* **📊 Project Statistics & Analytics (2005–2026):** Full comprehensive analytical report breakdown across 22 years, 885 questions, cognitive difficulties, and topic weightages.
* **📜 Official IIT JAM Syllabus:** Complete verified syllabus document across Real Analysis, Calculus, ODE, Linear Algebra, and Groups.
* **🏛️ 22-Year PYQ Archive (2005–2026):** Complete historical original question paper archive spanning all 22 examination years.
* **🎓 CUET-PG Mathematics Master Archive:** Complete official master question papers for 2024, 2025, and 2026.
* **🛠️ Custom Mock Test Generator:** Tailor your own practice test by picking specific topics, question counts (10, 20, 30, 45, 60), and difficulty tiers with instant CBT mode or practice drill.

---

## 🛠️ Technology Stack & Architecture

```
lib/
├── core/
│   ├── models/           # Data models (Question, MockTest, PyqItem, TestResult)
│   ├── services/         # DataService, TrackerService, CloudSyncService, CalculatorEngine, PdfHelper
│   └── theme/            # Lichess-inspired dark theme, typography & palette
├── presentation/
│   ├── screens/
│   │   ├── main_shell.dart         # Bottom Navigation Shell
│   │   ├── tests/                  # 22-Year Papers, 27 Subtopics & Custom Test Generator
│   │   ├── tracker/                # 885 PYQs with Screenshots by Default & Cloud Sync
│   │   ├── simulator/              # CBT Simulator, Calculator & Results
│   │   ├── stats/                  # Study Velocity, Streaks & Topic Analytics
│   │   └── study_hub/              # Official Syllabus, Analytics, PYQ Archive & Countdown
│   └── widgets/                    # Interactive zoomable screenshot viewer, difficulty chips
└── main.dart
```

* **Framework:** Flutter 3.29.2 (Dart 3.7.2)
* **Fonts:** Outfit (headings) & Inter (body) via `google_fonts`
* **Local Persistence:** `shared_preferences`
* **Gestures & Zoom:** Native `InteractiveViewer` with pinch-to-zoom for examination screenshots
* **Tactile Feedback:** `HapticFeedback` on tab switches and option selections

---

## 📦 Building the App

```bash
# Get dependencies
flutter pub get

# Run on connected Android device or emulator
flutter run

# Build release APK
flutter build apk --release
```

---

## 📄 License
MIT License. All examination papers, questions, and master keys belong to their respective conducting authorities (IITs and NTA).
