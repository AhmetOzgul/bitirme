import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsProvider extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController textController = TextEditingController();
  bool _isSpeaking = false;
  String? _error;
  String? _selectedEngine;
  String? _selectedVoice;

  bool get isSpeaking => _isSpeaking;
  String? get error => _error;

  TtsProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      final engines = await _flutterTts.getEngines;

      if (engines.isEmpty) {
        _error = 'TTS motoru bulunamadı';
        notifyListeners();
        return;
      }

      _selectedEngine = engines.firstWhere(
        (engine) => engine.toString().toLowerCase().contains('google'),
        orElse: () => engines.first,
      );

      await _flutterTts.setEngine(_selectedEngine!);

      final languages = await _flutterTts.getLanguages;

      final hasTurkish = languages.any(
        (lang) =>
            lang.toString().toLowerCase().contains('tr') ||
            lang.toString().toLowerCase().contains('turkish'),
      );

      if (!hasTurkish) {
        await _flutterTts.setLanguage('en-US');
      } else {
        await _flutterTts.setLanguage('tr-TR');
      }

      final voices = await _flutterTts.getVoices;

      if (voices.isNotEmpty) {
        final turkishVoice = voices.firstWhere(
          (voice) =>
              voice.toString().toLowerCase().contains('tr') ||
              voice.toString().toLowerCase().contains('turkish'),
          orElse: () => voices.first,
        );
        _selectedVoice = turkishVoice.toString();

        if (_selectedVoice != null) {
          await _flutterTts.setVoice({
            "name": _selectedVoice!,
            "locale": "tr-TR",
          });
        }
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((error) {
        _error = error;
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> speakText() async {
    if (textController.text.isEmpty) return;

    try {
      if (_isSpeaking) {
        await _flutterTts.stop();
        _isSpeaking = false;
      } else {
        _isSpeaking = true;
        _error = null;

        await _flutterTts.stop();
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await _flutterTts.speak(textController.text);

        if (result != 1) {
          _error = 'Konuşma başlatılamadı (kod: $result)';
          _isSpeaking = false;
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSpeaking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
