import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/enums.dart';

class SoundProvider extends ChangeNotifier {
  static const String _key = 'sound_mode';
  SoundMode _mode = SoundMode.tts;
  SoundMode get mode => _mode;

  SoundProvider() {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_key);
    if (savedMode != null) {
      _mode = SoundModeExtension.fromString(savedMode);
      notifyListeners();
    }
  }

  Future<void> setMode(SoundMode newMode) async {
    if (newMode == _mode) return;

    _mode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newMode.name);

    notifyListeners();
  }
}
