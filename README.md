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
3. Configure Firebase and local secrets:
   - Copy `.env.example` to `.env` and fill in real values.
   - For web push notifications, copy `web/firebase-config.local.js.example` to `web/firebase-config.local.js` and fill values.
   - Place your Firebase Android config file at `android/app/google-services.json` (download from Firebase console).
   - Keep these files local only; do not commit them.
4. Run the app (recommended):
   ```bash
   flutter run --dart-define-from-file=.env
   ```

## Project Structure

- `lib/views/` UI screens (calendar, reminders, chat, quiz, profile, auth)
- `lib/controllers/` services and state logic
- `lib/main.dart` app bootstrap and Firebase initialization

## Deploy to GitHub Pages

This repo includes a workflow at `.github/workflows/deploy_pages.yml` that deploys the web app when `main` is updated.

1. In your GitHub repository, open **Settings -> Secrets and variables -> Actions**.
2. Add repository secrets for each key in `.env.production.example`:
   - `FIREBASE_WEB_API_KEY`
   - `FIREBASE_WEB_APP_ID`
   - `FIREBASE_WEB_MESSAGING_SENDER_ID`
   - `FIREBASE_WEB_PROJECT_ID`
   - `FIREBASE_WEB_AUTH_DOMAIN`
   - `FIREBASE_WEB_STORAGE_BUCKET`
   - `FIREBASE_WEB_MEASUREMENT_ID`
   - `FIREBASE_ANDROID_API_KEY`
   - `FIREBASE_ANDROID_APP_ID`
   - `FIREBASE_ANDROID_MESSAGING_SENDER_ID`
   - `FIREBASE_ANDROID_PROJECT_ID`
   - `FIREBASE_ANDROID_STORAGE_BUCKET`
3. In **Settings -> Pages**, set **Source** to **Deploy from a branch**, then choose branch `gh-pages` and folder `/ (root)`.
4. Push to `main` (or run the workflow manually from the Actions tab).

By default, the workflow builds with `--base-href /Study-Early/`. If your repository name changes, update that value in the workflow file.

## Contributing

1. Create a feature branch.
2. Make your changes and test locally.
3. Open a pull request with a clear description.

## License

This repository is for educational/coursework purposes.
