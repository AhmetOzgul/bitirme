import 'package:flutter/material.dart';

enum VehicleType { car, bus, truck }

extension VehicleTypeExtension on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.car:
        return 'Otomobil';
      case VehicleType.bus:
        return 'Ticari / Minibüs';
      case VehicleType.truck:
        return 'Ağır Vasıta';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.bus:
        return Icons.directions_bus;
      case VehicleType.truck:
        return Icons.local_shipping;
    }
  }

  static VehicleType fromString(String value) {
    switch (value) {
      case 'bus':
        return VehicleType.bus;
      case 'truck':
        return VehicleType.truck;
      case 'car':
      default:
        return VehicleType.car;
    }
  }
}

enum SoundMode { tts, beep, silent }

extension SoundModeExtension on SoundMode {
  String get label {
    switch (this) {
      case SoundMode.tts:
        return 'Sesli Uyarı (TTS)';
      case SoundMode.beep:
        return 'Yalnızca Uyarı';
      case SoundMode.silent:
        return 'Sessiz';
    }
  }

  IconData get icon {
    switch (this) {
      case SoundMode.tts:
        return Icons.record_voice_over;
      case SoundMode.beep:
        return Icons.notifications_active;
      case SoundMode.silent:
        return Icons.volume_off;
    }
  }

  String get value {
    switch (this) {
      case SoundMode.tts:
        return 'tts';
      case SoundMode.beep:
        return 'beep';
      case SoundMode.silent:
        return 'silent';
    }
  }

  static SoundMode fromString(String value) {
    switch (value) {
      case 'tts':
        return SoundMode.tts;
      case 'beep':
        return SoundMode.beep;
      case 'silent':
      default:
        return SoundMode.silent;
    }
  }
}
