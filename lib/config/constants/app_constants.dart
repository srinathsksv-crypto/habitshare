class AppConstants {
  AppConstants._();

  // Root collections
  static const String usersCollection = 'users';
  static const String habitLogsCollection = 'habit_logs';
  static const String sharedHabitsCollection = 'shared_habits';

  // Subcollections under users/{userId}
  static const String habitsSubcollection = 'habits';
  static const String postsSubcollection = 'posts';
  static const String notificationsSubcollection = 'notifications';
  static const String followersSubcollection = 'followers';
  static const String followingSubcollection = 'following';
  static const String likesSubcollection = 'likes';
  static const String commentsSubcollection = 'comments';
  static const String privateSubcollection = 'private';
  static const String privateProfileDoc = 'profile';

  static const int maxBioLength = 150;
  static const int maxPostCaptionLength = 500;

  static const String followStatusPending = 'pending';
  static const String followStatusAccepted = 'accepted';

  static const int habitsPageSize = 20;
  static const int maxHabitTitleLength = 80;
  static const int maxHabitDescriptionLength = 500;

  static const String syncQueueTable = 'sync_queue';
  static const String habitsTable = 'habits_local';
  static const String habitLogsTable = 'habit_logs_local';
}
