import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_library;
import 'package:web_socket_channel/io.dart';

import 'package:camera/camera.dart';
import '../providers/detection_provider.dart';

class WsService {
  static const _wsUrl = 'ws://192.168.1.62:8000/ws/json_detect';
  //'ws://172.20.10.8:8000/ws/json_detect'; //'ws://192.168.1.185:8000/ws/json_detect';
  //'ws://37.27.92.232:8000/ws/json_detect'; //'ws://192.168.1.62:8000/ws/json_detect';
  static const _jpegQuality = 70;

  IOWebSocketChannel? _channel;
  bool _isDisposed = false;

  WsService() {
    _channel = IOWebSocketChannel.connect(_wsUrl);
  }

  void listen(DetectionProvider provider) {
    if (_isDisposed || _channel == null) return;

    _channel!.stream.listen(
      (msg) {
        if (_isDisposed) return;

        // Debug: Ham mesajı yazdır
        debugPrint('=== SERVERDAN GELEN HAM VERİ ===');
        debugPrint('Mesaj: $msg');

        final data = jsonDecode(msg);

        // Debug: JSON parse edilmiş veriyi yazdır
        debugPrint('=== PARSE EDİLMİŞ VERİ ===');
        debugPrint('Data: $data');

        final List detections = data['detections'];

        // Debug: Detections array'ini yazdır
        debugPrint('=== DETECTIONS ARRAY ===');
        debugPrint('Detections: $detections');
        debugPrint('Detections length: ${detections.length}');

        final List<Detection> list =
            detections.map((d) {
              // Debug: Her detection'ı yazdır
              debugPrint('=== DETECTION ===');
              debugPrint('Detection data: $d');
              debugPrint('Text: ${d['text']}');
              debugPrint('Score: ${d['score']}');
              debugPrint(
                'Box: x=${d['x']}, y=${d['y']}, w=${d['w']}, h=${d['h']}',
              );

              return Detection(
                box: Rect.fromLTWH(
                  (d['x'] as num).toDouble(),
                  (d['y'] as num).toDouble(),
                  (d['w'] as num).toDouble(),
                  (d['h'] as num).toDouble(),
                ),
                score: (d['score'] as num).toDouble(),
                text: d['text'] as String,
              );
            }).toList();

        // Debug: Oluşturulan Detection listesini yazdır
        debugPrint('=== OLUŞTURULAN DETECTION LİSTESİ ===');
        debugPrint('List length: ${list.length}');
        for (int i = 0; i < list.length; i++) {
          debugPrint(
            'Detection $i: text="${list[i].text}", score=${list[i].score}',
          );
        }

        provider.updateDetections(list);
      },
      onError: (error) {
        debugPrint('WebSocket bağlantı hatası: $error');
      },
      onDone: () {
        debugPrint('WebSocket bağlantısı kapandı');
      },
    );
  }

  Future<void> sendFrame(CameraImage image) async {
    if (_isDisposed || _channel == null) return;

    try {
      final jpeg = await convertToJpeg(image);
      final msg = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'image': base64Encode(jpeg),
      });
      _channel!.sink.add(msg);
    } catch (e) {
      debugPrint('Kare gönderilemedi: $e');
    }
  }

  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _channel?.sink.close();
      _channel = null;
    }
  }

  Future<Uint8List> convertToJpeg(CameraImage image) async {
    return await compute(_encodeJpeg, image);
  }

  static Uint8List _encodeJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel;
    final img = image_library.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yp = image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
        final up =
            image.planes[1].bytes[(y >> 1) * uvRowStride +
                (x >> 1) * uvPixelStride!];
        final vp =
            image.planes[2].bytes[(y >> 1) * uvRowStride +
                (x >> 1) * uvPixelStride];
        // YUV → RGB dönüşümü
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return Uint8List.fromList(
      image_library.encodeJpg(img, quality: _jpegQuality),
    );
  }
}
