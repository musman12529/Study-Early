# Study-Early

Study-Early is a Flutter + Firebase app that helps students organize coursework, generate quizzes, track study progress, and stay consistent with reminders.

## Features

- Authentication with Firebase (sign up, sign in, onboarding, and role selection)
- Course and material management
- Quiz generation and quiz attempts workflow
- Calendar-based event planning
- Reminder scheduling and notifications
- Study progress overview widgets
- Chat page and profile management

## Tech Stack

- Flutter (Dart)
- Firebase:
  - Authentication
  - Cloud Firestore
  - Cloud Functions
  - Cloud Storage
  - Cloud Messaging
- Riverpod for state management
- GoRouter for navigation

## Prerequisites

- Flutter SDK (matching project Dart SDK constraints)
- A configured Firebase project
- Platform setup for Flutter (Android Studio/Xcode as needed)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/musman12529/Study-Early.git
   cd Study-Early
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Ensure `lib/firebase_options.dart` is present and matches your Firebase project.
   - Verify required Firebase services are enabled in console.
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/views/` UI screens (calendar, reminders, chat, quiz, profile, auth)
- `lib/controllers/` services and state logic
- `lib/main.dart` app bootstrap and Firebase initialization

## Contributing

1. Create a feature branch.
2. Make your changes and test locally.
3. Open a pull request with a clear description.

## License

This repository is for educational/coursework purposes.
