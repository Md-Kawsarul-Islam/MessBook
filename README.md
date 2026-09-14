# 🍽️ MessBook — The Ultimate Mess & Meal Management Solution

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com)
[![Version](https://img.shields.io/badge/Version-4.2.0-blue.svg?style=for-the-badge)](https://github.com/Mustad-Afin-Shimanto/mess_meal_management_app/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Managing a mess or shared living arrangement (hostel/dorm) manually with spreadsheets and notebooks is outdated and error-prone. **MessBook** is a premium, cloud-native Flutter application designed to automate every aspect of mess management—from meal tracking and market duty scheduling to real-time financial transparency and group communication.

---

🦾 **AI Collaboration**: This project was created with **Vive coding using AI**. **I.d.E.** used **Antigravity** to architect, code, and document this entire solution.

---

<p align="center">
  <img src="assets/images/app_logo.png" width="400" alt="App Header">
</p>

### 📸 Screenshots

<p align="center">
  <img src="assets/images/screenshot_splash.png" width="220" alt="Splash Screen">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/images/screenshot_login.png" width="220" alt="Login Screen">
</p>

---

## 🌟 Why MessBook?

In a shared living environment, transparency and efficiency are paramount. **Mess Manager** bridges the gap between members and management through:
- **Zero Confusion**: Real-time meal counting and expense tracking.
- **Fairness**: Automated meal rate calculations and balanced market duty assignments.
- **Privacy & Security**: Secure user authentication and device integrity checks.
- **Reporting**: One-click professional PDF reports for monthly audits.

---

## 🔥 Key Features & Capabilities

### 🛡️ Role-Based Ecosystem
The app features a hierarchical access system to keep operations streamlined and secure.

#### 👑 **Admin (Super User)**
- **Global Management**: Oversee multiple hostels/messes from a single account.
- **Access Control**: Hand-pick Managers, reset member passwords, and manage user roles.
- **Data Safeguards**: Export full database backups to local storage for extra security.
- **Invitation System**: Generate unique **Hostel Invite Codes** for secure member onboarding.

#### 💼 **Manager (Operations Leader)**
- **Financial Control**: Log daily market expenses and member contributions (Hand Cash).
- **Meal Management**: Record daily breakfast, lunch, and dinner counts for all members.
- **Market Coordination**: Assign and track market duties to ensure fairness.
- **Request Processing**: Approve or reject expense requests submitted by members.
- **Communication**: Post urgent/normal notices to the mess bulletin board.

#### 👤 **Member (End User)**
- **Personal Dashboard**: View real-time personal balance, meal counts, and current meal rate.
- **Transparency**: Access personal history for meals, contributions, and expenses.
- **Engagement**: Rate daily meals and leave feedback for the Manager.
- **Shopping Requests**: Request funds for specific items (Entry Request) directly through the app.
- **Notifications**: Stay updated with push notifications for notices, approvals, and duties.

---

## 🚀 Specialized Modules

- **📊 Dynamic Analytics**: Interactive charts (powered by `fl_chart`) showing expense trends and meal consumption.
- **💬 Real-time Group Chat**: A dedicated secure channel for mess members to discuss daily operations without external apps.
- **📋 Smart Market Duty**: Automated or manual scheduling visible to everyone to prevent "who's turn is it?" arguments.
- **🧠 Expense Prediction**: Intelligent forecasting to estimate total monthly costs based on current spending patterns.
- **📄 Pro PDF Engine**: Generates professional, transparent financial receipts and monthly statements.

---

## 🛠️ Modern Technology Stack

| Component | Technology | Why we chose it? |
| :--- | :--- | :--- |
| **Frontend** | **Flutter SDK** | Cross-platform performance (Android/Web/Windows) with a stunning UI. |
| **Language** | **Dart** | Modern, type-safe language for robust application logic. |
| **Database** | **Firestore** | Real-time NoSQL cloud database with offline persistence. |
| **Auth** | **Firebase Auth** | Industry-standard secure login (Email/Password). |
| **Logic** | **Provider** | Clean state management for responsive real-time updates. |
| **Security** | **safe_device** | Blocks compromised (Rooted/Jailbroken) devices to prevent data scraping. |
| **Hashing** | **BCrypt** | Secure local data integrity and secondary password layers. |
| **Charts** | **fl_chart** | Beautiful, interactive data visualization. |

---

## 🔒 Security & Integrity
MessBook(v4.2+) implements enterprise-grade security to protect your mess data:

- **Root/Jailbreak Detection**: On startup, the app checks for compromised environments and blocks access if the device is not secure.
- **Release Obfuscation**: The production code is fully obfuscated (ProGuard & Dart Obfuscation), making reverse engineering nearly impossible.
- **Input Sanitization**: Strict validation on all financial inputs to prevent logic errors or malicious entries.

---

## 📂 Project Structure

```text
lib/
├── models/         # PODOs with Firestore (to/from) serialization
├── providers/      # ChangeNotifier state for meals, expenses, chat, etc.
├── screens/        # Organized UI (Admin/, Manager/, Member/, Shared/, Auth/)
├── services/       # Core logic: AuthService, ExpensePrediction, NotificationService
├── widgets/        # Reusable UI components (DashboardCards, Slidables, Drawers)
├── utils/          # Constants, currency formatters, and date helpers
├── routes.dart     # Centralized navigation mapping
└── main.dart       # App initialization and Global Provider setup
```

---

## ⚙️ Quick Start Guide

### 1️⃣ Prerequisites
- **Flutter SDK** (v3.7.2 or higher)
- **Firebase CLI** (`npm install -g firebase-tools`)
- A Firebase Project (with Firestore & Email Auth enabled)

### 2️⃣ Installation
```bash
# Clone the repository
git clone https://github.com/Mustad-Afin-Shimanto/mess_meal_management_app.git
cd mess_manager

# Install dependencies
flutter pub get
```

### 3️⃣ Firebase Setup
Ensure your Firebase project is configured across platforms. If using **FlutterFire CLI**:
```bash
flutterfire configure
```

### 4️⃣ Running the App
**For Development:**
```bash
# Mobile
flutter run

# Web
flutter run -d chrome --web-port=3000
```

---

## 📦 Building for Production

To build a secure, obfuscated release APK:
1. Ensure `build_release.bat` is configured for your environment.
2. Run the build command:
```powershell
.\build_release.bat
```
*This command triggers resource shrinking and Dart symbol obfuscation.*

---

## 🤝 Contributing & Support

We welcome contributions! Feel free to:
- 🐞 Report bugs via GitHub Issues.
- 💡 Propose new features (e.g., Image receipts, Global analytics).
- 🔧 Submit Pull Requests for optimizations.

**Project maintainer:** [Mustad Afin Shimanto](https://github.com/Mustad-Afin-Shimanto)  
**Developed with ❤️ for the student & mess community.**

---
© 2026 Mustad Afin Shimanto & Antigravity. Licensed under MIT.


