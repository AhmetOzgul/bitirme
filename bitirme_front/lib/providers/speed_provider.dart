import 'package:bitirme_front/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'sound_provider.dart';

class SpeedProvider extends ChangeNotifier {
  double _currentSpeed = 0.0;
  bool _isLocationServiceEnabled = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  SoundProvider? _soundProvider;
  int? _lastSpeedLimit;
  DateTime? _lastWarningTime;
  static const _warningCooldown = Duration(minutes: 1);

  double get currentSpeed => _currentSpeed;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  void setSoundProvider(SoundProvider provider) => _soundProvider = provider;

  void setSpeedLimit(int? limit) {
    if (_lastSpeedLimit != limit) {
      _lastSpeedLimit = limit;
      _checkSpeedLimit();
    }
  }

  SpeedProvider() {
    _initLocationService();
    _initTts();
    _initAudio();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('tr-TR');
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep1.mp3'));
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Ses dosyası yüklenemedi: $e');
    }
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 50));
      await _audioPlayer.setSource(AssetSource('sounds/beep1.mp3'));
      await _audioPlayer.resume();
      await Future.delayed(const Duration(milliseconds: 300));
      await _audioPlayer.setSource(AssetSource('sounds/beep1.mp3'));
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Bip sesi çalınamadı: $e');
    }
  }

  Future<void> _announceSpeedWarning(int speedLimit) async {
    if (_soundProvider == null) return;

    final now = DateTime.now();
    if (_lastWarningTime != null &&
        now.difference(_lastWarningTime!) < _warningCooldown) {
      return;
    }

    try {
      switch (_soundProvider!.mode) {
        case SoundMode.tts:
          await _flutterTts.speak(
            'Hız sınırını aştınız. Limit $speedLimit kilometre',
          );
          break;
        case SoundMode.beep:
          await _playBeep();
          break;
        case SoundMode.silent:
          break;
      }
      _lastWarningTime = now;
    } catch (e) {
      debugPrint('Uyarı seslendirilemedi: $e');
    }
  }

  void _checkSpeedLimit() {
    if (_lastSpeedLimit == null || _soundProvider == null) return;
    if (_currentSpeed > _lastSpeedLimit!) {
      _announceSpeedWarning(_lastSpeedLimit!);
    }
  }

  Future<void> _initLocationService() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationServiceEnabled = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _isLocationServiceEnabled = false;
          notifyListeners();
          return;
        }
      }

      _isLocationServiceEnabled = true;
      _startLocationUpdates();
      notifyListeners();
    } catch (e) {
      _isLocationServiceEnabled = false;
      notifyListeners();
    }
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        try {
          double speed = position.speed * 3.6;
          if (speed < 1.0) speed = 0.0;

          if (speed != _currentSpeed) {
            _currentSpeed = speed;
            _checkSpeedLimit();
            notifyListeners();
          }
        } catch (e) {
          _currentSpeed = 0.0;
          notifyListeners();
        }
      },
      onError: (error) {
        _isLocationServiceEnabled = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
