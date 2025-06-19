import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/enums.dart';

class VehicleProvider extends ChangeNotifier {
  static const String _key = 'vehicle_type';
  VehicleType _type = VehicleType.car;
  VehicleType get type => _type;

  VehicleProvider() {
    _loadType();
  }

  Future<void> _loadType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(_key);
    if (savedType != null) {
      _type = VehicleTypeExtension.fromString(savedType);
      notifyListeners();
    }
  }

  Future<void> setType(VehicleType newType) async {
    if (newType == _type) return;

    _type = newType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newType.name);

    notifyListeners();
  }
}
