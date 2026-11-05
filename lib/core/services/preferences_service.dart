import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract for persistent and in-memory key-value settings.
abstract class PreferencesService {
  /// Reads a boolean value stored at [key], defaulting to [defaultValue].
  bool getBool(String key, {bool defaultValue = false});

  /// Persists a boolean [value] at [key].
  Future<bool> setBool(String key, bool value);

  /// Reads a list of strings stored at [key], or null if unset.
  List<String>? getStringList(String key);

  /// Persists a list of strings [value] at [key].
  Future<bool> setStringList(String key, List<String> value);

  /// Reads an integer value stored at [key], defaulting to [defaultValue].
  int getInt(String key, {int defaultValue = 0});

  /// Persists an integer [value] at [key].
  Future<bool> setInt(String key, int value);
}

/// Persistent implementation of [PreferencesService] backed by [SharedPreferences].
class SharedPrefsPreferencesService implements PreferencesService {
  final SharedPreferences _prefs;

  const SharedPrefsPreferencesService(this._prefs);

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  @override
  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  @override
  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }
}

/// In-memory implementation of [PreferencesService] for testing and fallback environments.
class InMemoryPreferencesService implements PreferencesService {
  final Map<String, dynamic> _storage;

  InMemoryPreferencesService([Map<String, dynamic>? initial])
      : _storage = Map.of(initial ?? {});

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return _storage[key] as bool? ?? defaultValue;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) {
    final val = _storage[key];
    if (val is List) {
      return val.cast<String>();
    }
    return null;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = List<String>.from(value);
    return true;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    return _storage[key] as int? ?? defaultValue;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }
}

/// Provides the active [PreferencesService] instance.
/// Defaults to [InMemoryPreferencesService] so tests run with zero boilerplate,
/// while [main.dart] overrides it with [SharedPrefsPreferencesService].
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return InMemoryPreferencesService();
});
