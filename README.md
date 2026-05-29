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

## Project Structure

```
habitshare/
├── .env.example                # Template for environment variables (APP_ENV, SENTRY_DSN, etc.)
├── .env                        # Local env overrides (git-ignored)
├── firebase.json               # Firebase CLI project config (hosting, deploy targets)
├── firestore.rules             # Firestore security rules — deploy before using the app
├── firestore.indexes.json      # Composite Firestore indexes (feed queries, etc.)
├── storage.rules               # Firebase Storage security rules (profile pics, post images)
├── pubspec.yaml                # Flutter dependencies & project metadata
│
└── lib/
    ├── main.dart                       # Dev entry point — Firebase init, dotenv, DI setup, error zone
    ├── main_prod.dart                  # Production entry point — same bootstrap, quieter error logging
    ├── app.dart                        # Root widget — AdaptiveTheme, GoRouter, auth-gate redirect
    ├── firebase_options.dart           # Auto-generated Firebase config (flutterfire configure)
    │
    ├── config/                         # ── App-wide configuration ──
    │   ├── app_config.dart             # Environment enum (dev/staging/prod), feature flags, analytics toggles
    │   ├── firebase_options.dart       # Alternate/fallback Firebase options
    │   ├── constants/
    │   │   └── app_constants.dart      # Firestore collection names, field limits, follow statuses, local DB table names
    │   ├── router/
    │   │   └── app_router.dart         # GoRouter routes (splash → login → home) with auth redirect logic
    │   └── theme/
    │       ├── app_colors.dart         # Colour palette constants (primary, accent, surface, etc.)
    │       ├── app_theme.dart          # Light & dark ThemeData builders
    │       └── app_typography.dart     # Text style definitions (headline, body, caption)
    │
    ├── core/                           # ── Shared utilities & cross-cutting concerns ──
    │   ├── di/
    │   │   └── service_locator.dart    # GetIt DI — registers all datasources, repositories as singletons
    │   ├── errors/
    │   │   ├── exceptions.dart         # Data-layer exception types (Server, Cache, Auth, Network, Sync)
    │   │   ├── failure.dart            # Domain-layer failure types returned via Either<Failure, T>
    │   │   └── error_mapper.dart       # Maps exceptions → failures; special-cases permission-denied
    │   ├── extensions/
    │   │   └── context_extensions.dart # BuildContext helpers (theme, text-theme, media-query shortcuts)
    │   ├── logger/
    │   │   └── app_logger.dart         # Centralized logger (debug, info, error) wrapping dart:developer
    │   └── utils/
    │       ├── date_utils.dart         # Date formatting ("5m ago", "Mar 12"), same-day comparison
    │       ├── firestore_parse_utils.dart  # Safely parse Timestamp/String/int → DateTime; normalize doc IDs
    │       └── image_crop_utils.dart   # Crop image to 4:5 aspect ratio using image_cropper plugin
    │
    ├── domain/                         # ── Business logic layer (pure Dart, no Flutter/Firebase imports) ──
    │   ├── entities/
    │   │   ├── user_entity.dart        # User profile (id, name, email, photoUrl, bio)
    │   │   ├── habit_entity.dart       # Habit with status (active/quit), start/end dates, archive flag
    │   │   ├── habit_log_entity.dart   # Single habit completion log entry (habitId, date, note)
    │   │   ├── habit_post_entity.dart  # Feed post (habit title, message, image, like count, comment count)
    │   │   ├── post_comment_entity.dart # Comment on a post (author, text, timestamp)
    │   │   ├── follow_entity.dart      # Follow relationship (follower ↔ following, status: pending/accepted)
    │   │   ├── shared_habit_entity.dart # Shared habit between users (owner, recipient, habit ref)
    │   │   └── notification_entity.dart # In-app notification (type: like/comment/follow_accept, read flag)
    │   ├── repositories/               # Abstract repository interfaces (contracts for the data layer)
    │   │   ├── auth_repository.dart    # Sign in, sign up, sign out, Google sign-in, watch auth state
    │   │   ├── habit_repository.dart   # CRUD habits, watch habits stream for a user
    │   │   ├── habit_log_repository.dart # Log habit completions, fetch logs by date range
    │   │   ├── social_repository.dart  # Posts, likes, comments, follows, user search, notifications, profile
    │   │   ├── sharing_repository.dart # Share/unshare habits with specific users
    │   │   ├── sync_repository.dart    # Push local changes to Firestore (offline-first sync)
    │   │   └── import_export_repository.dart # CSV import/export of habit data
    │   └── usecases/                   # Single-responsibility use cases wrapping repository calls
    │       ├── auth/
    │       │   ├── login_usecase.dart           # Email+password login
    │       │   ├── register_usecase.dart         # Create account with email+password
    │       │   ├── logout_usecase.dart           # Sign out current user
    │       │   └── get_current_user_usecase.dart # Fetch the currently authenticated user
    │       ├── habits/
    │       │   ├── create_habit_usecase.dart     # Create a new habit
    │       │   ├── update_habit_usecase.dart     # Update habit title/description/dates
    │       │   ├── delete_habit_usecase.dart     # Permanently delete a habit
    │       │   ├── get_habits_usecase.dart       # Fetch all habits for a user
    │       │   ├── log_habit_usecase.dart        # Record a habit completion for a day
    │       │   └── get_habit_stats_usecase.dart  # Calculate streaks, completion rates, stats
    │       ├── sharing/
    │       │   ├── share_habit_usecase.dart      # Share a habit with another user
    │       │   └── get_shared_habits_usecase.dart # List habits shared with the current user
    │       ├── import_export/
    │       │   ├── export_usecase.dart           # Export habits to CSV
    │       │   └── import_usecase.dart           # Import habits from CSV
    │       └── sync/
    │           └── sync_usecase.dart             # Trigger offline → Firestore sync
    │
    ├── data/                           # ── Data layer (Firebase, SQLite, CSV implementations) ──
    │   ├── datasources/
    │   │   ├── remote/
    │   │   │   ├── firestore_paths.dart          # Centralized Firestore collection/document path helpers
    │   │   │   ├── firestore_datasource.dart     # All Firestore reads/writes (habits, posts, follows, notifications)
    │   │   │   ├── firebase_auth_datasource.dart # Firebase Auth operations (email, Google, sign-out, auth stream)
    │   │   │   └── firebase_storage_datasource.dart # Upload/download files to Firebase Storage
    │   │   └── local/
    │   │       ├── local_database.dart            # SQLite (sqflite) database for offline habit & log caching
    │   │       ├── csv_datasource.dart            # Read/write habit data as CSV files
    │   │       └── shared_preferences_datasource.dart # Key-value storage for app settings & flags
    │   ├── models/                     # Freezed data models with JSON serialization (Firestore ↔ Dart)
    │   │   ├── user_model.dart         # UserModel — Firestore ↔ UserEntity mapping
    │   │   ├── habit_model.dart        # HabitModel — includes status, dates, archive fields
    │   │   ├── habit_log_model.dart    # HabitLogModel — completion log with date & note
    │   │   ├── shared_habit_model.dart # SharedHabitModel — habit sharing records
    │   │   ├── notification_model.dart # NotificationModel — notification type, sender info, read state
    │   │   └── *.freezed.dart / *.g.dart # Auto-generated immutable classes & JSON codegen
    │   ├── repositories/               # Concrete repository implementations
    │   │   ├── auth_repository_impl.dart        # Firebase Auth + Firestore user profile creation on sign-up
    │   │   ├── habit_repository_impl.dart       # Firestore + local DB habit CRUD with Either<Failure,T> returns
    │   │   ├── habit_log_repository_impl.dart   # Firestore habit log writes & queries
    │   │   ├── social_repository_impl.dart      # Posts, likes, comments, follows, search, notifications, profile updates
    │   │   ├── sharing_repository_impl.dart     # Firestore shared-habit subcollection management
    │   │   ├── sync_repository_impl.dart        # Sync queue: push pending local changes to Firestore
    │   │   └── import_export_repository_impl.dart # Delegates CSV read/write to CsvDataSource
    │   └── services/
    │       └── sync_service.dart       # Background sync service interface (periodic offline→cloud push)
    │
    └── presentation/                   # ── UI layer (Flutter widgets, state management) ──
        ├── providers/                  # Riverpod providers — bridge between UI and domain/data
        │   ├── auth_provider.dart      # Exposes IAuthRepository & auth state stream to widgets
        │   ├── habit_provider.dart     # Exposes habit list (Future + Stream) by userId
        │   ├── social_provider.dart    # Feed stream, followers/following lists, user search, follow status
        │   ├── notification_provider.dart # Notification stream & unread count by userId
        │   └── user_profile_provider.dart # Fetch any user's profile by userId
        ├── controllers/               # Action handlers — orchestrate multi-step operations
        │   ├── auth_controller.dart    # Logout action (calls auth repository)
        │   ├── habit_controller.dart   # Create / quit / delete habit + optional post creation
        │   └── social_controller.dart  # Like, comment, follow/unfollow, bio update, profile photo, notifications
        ├── pages/                      # Full-screen page widgets (routes)
        │   ├── splash/
        │   │   └── splash_page.dart            # Initial loading screen while auth state resolves
        │   ├── auth/
        │   │   └── login_page.dart             # Email/password + Google sign-in login screen
        │   └── home/
        │       ├── main_shell_page.dart         # Bottom navigation shell (Habits / Feed / Profile tabs)
        │       ├── home_page.dart               # Legacy/wrapper home page
        │       └── tabs/
        │           ├── habits_tab.dart          # Habit list with add button; shows active/archived habits
        │           ├── feed_tab.dart            # Social feed of posts from user + accepted followers
        │           └── profile_tab.dart         # User profile, bio, followers/following, pending requests, sign out
        ├── screens/                    # Secondary screens (pushed on top of pages)
        │   ├── habit_details_screen.dart    # Habit detail view with logs, streaks, quit/delete actions
        │   ├── habit_list_screen.dart       # Stub/redirect for habit listing
        │   ├── notifications_screen.dart    # Full notification list with mark-as-read
        │   └── user_profile_sheet.dart      # Other user's profile bottom sheet (follow/unfollow, bio, posts)
        └── widgets/                    # Reusable UI components
            ├── create_habit_dialog.dart      # Dialog for creating a new habit (title, description, dates, share toggle)
            ├── create_post_sheet.dart        # Bottom sheet for composing a post (message, image picker + crop)
            ├── habit_card.dart              # Card widget displaying a single habit's info and status
            ├── post_card.dart               # Feed post card with image, like button, comment count
            ├── post_comments_sheet.dart      # Bottom sheet showing comments list + add-comment input
            ├── google_sign_in_button.dart    # Styled Google sign-in button widget
            ├── app_notification_button.dart  # Bell icon with unread badge for the app bar
            ├── user_connections_sheet.dart   # Bottom sheet listing followers or following with actions
            └── user_tile.dart               # Compact user avatar + name row used in lists
```

## App Features

- **Habits** — create and view your habits (fixed-width add dialog with multiline description)
- **Feed** — posts from you and accepted followers; like and comment in real time
- **Profile** — followers/following counts, follow requests, user search, sign out

## Social Features

- **Google sign-in** on the login screen (alongside email/password)
- **Follow requests** — send request → other user accepts/declines on Profile
- **Posts** — only visible to accepted followers (and your own posts in your feed)
- **Likes & comments** — live updates via Firestore streams

After pulling these changes, **re-deploy `firestore.rules`** (new rules for likes, comments, follow requests).
