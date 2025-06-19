import 'package:bitirme_front/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'vehicle_provider.dart';
import 'sound_provider.dart';
import 'speed_provider.dart';

class Detection {
  final Rect box;
  final double score;
  final String text;
  Detection({required this.box, required this.score, required this.text});
}

class DetectionProvider extends ChangeNotifier {
  List<Detection> _detections = [];
  final Map<VehicleType, int?> _lastSpeeds = {
    VehicleType.car: null,
    VehicleType.bus: null,
    VehicleType.truck: null,
  };
  int? _lastAnnouncedSpeed;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  VehicleType _currentVehicleType = VehicleType.car;
  SoundProvider? _soundProvider;
  SpeedProvider? _speedProvider;
  bool _isAudioLoaded = false;

  List<Detection> get detections => _detections;
  int? getLastSpeed(VehicleType type) => _lastSpeeds[type];

  void setVehicleType(VehicleType type) {
    _currentVehicleType = type;
    notifyListeners();
  }

  void setSoundProvider(SoundProvider provider) => _soundProvider = provider;
  void setSpeedProvider(SpeedProvider provider) => _speedProvider = provider;

  DetectionProvider() {
    _initTts();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (_isAudioLoaded) return;

    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep1.mp3'));
      await _audioPlayer.setVolume(1.0);
      _isAudioLoaded = true;
    } catch (e) {
      debugPrint('Ses dosyası yüklenemedi: $e');
    }
  }

  Future<void> _playBeep() async {
    if (!_isAudioLoaded) {
      await _initAudio();
    }

    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep1.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      _isAudioLoaded = false;
      await _initAudio();
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('tr-TR');
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _announceSpeed(int speed) async {
    if (_soundProvider == null) return;

    try {
      switch (_soundProvider!.mode) {
        case SoundMode.tts:
          await _flutterTts.speak('Hız sınırı $speed kilometre');
          break;
        case SoundMode.beep:
          await _audioPlayer.stop();
          await Future.delayed(const Duration(milliseconds: 50));
          await _playBeep();
          break;
        case SoundMode.silent:
          break;
      }
    } catch (e) {
      debugPrint('Seslendirme yapılamadı: $e');
    }
  }

  void updateDetections(List<Detection> detections) {
    // Debug: Gelen detections'ları yazdır
    debugPrint('=== DETECTION PROVIDER - GELEN DETECTIONS ===');
    debugPrint('Detections count: ${detections.length}');
    for (int i = 0; i < detections.length; i++) {
      debugPrint(
        'Detection $i: text="${detections[i].text}", score=${detections[i].score}',
      );
    }

    _detections = detections;

    final speeds =
        detections
            .map((d) => int.tryParse(d.text) ?? 0)
            .where((v) => v > 0)
            .toList()
          ..sort((b, a) => a.compareTo(b));

    // Debug: Parse edilen hızları yazdır
    debugPrint('=== PARSE EDİLEN HIZLAR ===');
    debugPrint('Speeds: $speeds');
    debugPrint('Speeds count: ${speeds.length}');

    if (speeds.isNotEmpty) {
      int? selectedSpeed;
      switch (_currentVehicleType) {
        case VehicleType.car:
          selectedSpeed = speeds.elementAt(0);
          break;
        case VehicleType.bus:
          selectedSpeed = speeds.length > 1 ? speeds[1] : speeds.last;
          break;
        case VehicleType.truck:
          selectedSpeed = speeds.length > 2 ? speeds[2] : speeds.last;
          break;
      }

      // Debug: Seçilen hızı yazdır
      debugPrint('=== SEÇİLEN HIZ ===');
      debugPrint('Current vehicle type: ${_currentVehicleType.label}');
      debugPrint('Selected speed: $selectedSpeed');
      debugPrint('Last announced speed: $_lastAnnouncedSpeed');

      if (selectedSpeed != null) {
        if (_lastAnnouncedSpeed != selectedSpeed) {
          _lastAnnouncedSpeed = selectedSpeed;
          debugPrint('=== SESLENDİRME YAPILIYOR ===');
          debugPrint('Announcing speed: $selectedSpeed');
          _announceSpeed(selectedSpeed);
        }
        _lastSpeeds[_currentVehicleType] = selectedSpeed;
        _speedProvider?.setSpeedLimit(selectedSpeed);
      }
    } else {
      debugPrint('=== HIZ BULUNAMADI ===');
      debugPrint('No valid speeds found in detections');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
