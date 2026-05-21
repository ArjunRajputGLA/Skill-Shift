# Skill Shift

Skill Shift is an innovative, community-driven platform designed to connect individuals based on their skills and expertise. Whether you're a designer looking to learn programming, or a developer wanting to improve your marketing skills, Skill Shift helps you find the perfect match to exchange knowledge and collaborate.

## ✨ Key Features

- **Authentication**: Secure sign-up, login, and password management powered by Firebase Authentication.
- **Skill Profiles**: Comprehensive user profiles displaying offered skills and desired skills.
- **Dynamic Explore Screen**: Discover new users based on their skills, with real-time search functionality.
- **Community Posts**: Share updates, accomplishments, and requests in a public feed.
- **Real-Time Messaging**: Engage in seamless 1-on-1 real-time chats with other users.
- **Push Notifications**: Stay connected even when the app is closed! Serverless Vercel backend and Firebase Cloud Messaging handle lightning-fast push notifications.
- **Interactive UI**: Gorgeous glassmorphism design, sleek dark/light mode toggles, and smooth micro-animations.
- **Unread Indicators**: Smart dot indicators in the chat list and navigation bar to ensure you never miss a message.

## 🛠️ Technology Stack

- **Frontend**: Flutter & Dart
- **Backend & Database**: Firebase Firestore (NoSQL Document Database)
- **Authentication**: Firebase Auth
- **Storage**: Firebase Cloud Storage (Profile pictures, media)
- **Push Notifications API**: Vercel Serverless Functions (Node.js) & Firebase Admin SDK

## 🚀 Getting Started

Follow these steps to set up the project on your local machine.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.0+)
- [Node.js](https://nodejs.org/) (Version 24.x or above for Vercel backend)
- A Firebase Project

### 1. Clone the repository

```bash
git clone https://github.com/your-username/skill-shift.git
cd skill-shift
```

### 2. Configure Firebase

1. Create a new Firebase project at the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firestore**, **Firebase Authentication**, and **Firebase Storage**.
3. Register your Android/iOS apps in the Firebase console and download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS).
4. Place the configuration files in their respective directories (`android/app/` and `ios/Runner/`).

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Setup Vercel Backend (For Push Notifications)

1. Navigate to the `vercel_backend` directory:
   ```bash
   cd vercel_backend
   npm install
   ```
2. Deploy to Vercel:
   ```bash
   npx vercel
   ```
3. Generate a Firebase Admin Service Account Key from your Firebase Console (Project Settings > Service Accounts > Generate New Private Key).
4. In your Vercel Dashboard, go to your project settings and add a new Environment Variable named `FIREBASE_SERVICE_ACCOUNT_KEY` containing the stringified JSON content of your Service Account Key.
5. In your Flutter codebase, update the endpoint URL in `lib/services/firebase_notification_service.dart` to match your new Vercel deployment URL.

### 5. Run the App

```bash
flutter run
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the issues page if you want to contribute.

## 📝 License

This project is open-source and available under the [MIT License](LICENSE).
