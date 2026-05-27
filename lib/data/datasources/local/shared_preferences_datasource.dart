import 'package:habitshare/core/errors/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDataSource {
  SharedPreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'onboarding_complete';
  static const _lastSyncKey = 'last_sync_at';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeKey, mode);
  }

  String? getThemeMode() => _prefs.getString(_themeKey);

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  bool isOnboardingComplete() => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setLastSyncAt(DateTime dateTime) async {
    await _prefs.setString(_lastSyncKey, dateTime.toIso8601String());
  }

  DateTime? getLastSyncAt() {
    final value = _prefs.getString(_lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> clearAll() async {
    final success = await _prefs.clear();
    if (!success) {
      throw const CacheException('Failed to clear preferences');
    }
  }
}
