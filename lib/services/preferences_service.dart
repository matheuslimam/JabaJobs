import 'package:shared_preferences/shared_preferences.dart';

class SavedConnection {
  const SavedConnection({
    required this.host,
    required this.username,
    required this.rememberHostAndUser,
  });

  final String host;
  final String username;
  final bool rememberHostAndUser;
}

class PreferencesService {
  PreferencesService._(this._prefs);

  static const _hostKey = 'connection.host';
  static const _usernameKey = 'connection.username';
  static const _rememberKey = 'connection.remember';

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async {
    return PreferencesService._(await SharedPreferences.getInstance());
  }

  SavedConnection loadConnection() {
    final remember = _prefs.getBool(_rememberKey) ?? false;
    return SavedConnection(
      host: remember ? (_prefs.getString(_hostKey) ?? '') : '',
      username: remember ? (_prefs.getString(_usernameKey) ?? '') : '',
      rememberHostAndUser: remember,
    );
  }

  Future<void> saveConnection({
    required String host,
    required String username,
    required bool remember,
  }) async {
    await _prefs.setBool(_rememberKey, remember);
    if (!remember) {
      await _prefs.remove(_hostKey);
      await _prefs.remove(_usernameKey);
      return;
    }

    await _prefs.setString(_hostKey, host);
    await _prefs.setString(_usernameKey, username);
  }
}
