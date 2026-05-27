# HabitShare

Flutter habit-sharing app with Firebase, Riverpod, and clean architecture.

## Quick Start

1. Copy `.env.example` to `.env`
2. Run `flutterfire configure` (generates `lib/firebase_options.dart`)
3. `flutter pub get`
4. `dart run build_runner build --delete-conflicting-outputs`
5. **Deploy Firestore rules** (required — see below)
6. `flutter run`

## Fix: "Missing or insufficient permissions"

This error means **Firestore security rules** are blocking writes. The app code is fine; you must deploy rules to your Firebase project.

### Option A — Firebase Console (fastest)

1. Open [Firebase Console](https://console.firebase.google.com/) → your project
2. Go to **Firestore Database** → **Rules**
3. Replace all rules with the contents of `firestore.rules` in this repo
4. Click **Publish**

### Option B — Firebase CLI

```bash
npm install -g firebase-tools
firebase login
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules,firestore:indexes
```

After publishing rules, **hot restart** the app and try **Add Habit** again. You should see documents in:

- `habits` — your habits
- `posts` — feed posts (when "Share as post" is on)
- `users` — profiles (created on login)

## App structure

- **Habits** — create and view your habits (fixed-width add dialog with multiline description)
- **Feed** — posts from you and accepted followers; like and comment in real time
- **Profile** — followers/following counts, follow requests, user search, sign out

## Social features

- **Google sign-in** on the login screen (alongside email/password)
- **Follow requests** — send request → other user accepts/declines on Profile
- **Posts** — only visible to accepted followers (and your own posts in your feed)
- **Likes & comments** — live updates via Firestore streams

After pulling these changes, **re-deploy `firestore.rules`** (new rules for likes, comments, follow requests).
