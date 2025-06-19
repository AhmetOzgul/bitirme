import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'providers/vehicle_provider.dart';
import 'providers/detection_provider.dart';
import 'providers/tts_provider.dart';
import 'providers/sound_provider.dart';
import 'providers/speed_provider.dart';
import 'core/router.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final cameras = await availableCameras();
    final router = createRouter(cameras);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final ttsProvider = TtsProvider();
    final soundProvider = SoundProvider();
    final detectionProvider = DetectionProvider();
    final speedProvider = SpeedProvider();

    detectionProvider.setSoundProvider(soundProvider);
    detectionProvider.setSpeedProvider(speedProvider);
    speedProvider.setSoundProvider(soundProvider);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ttsProvider),
          ChangeNotifierProvider.value(value: soundProvider),
          ChangeNotifierProvider.value(value: detectionProvider),
          ChangeNotifierProvider.value(value: speedProvider),
          ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ],
        child: MyApp(router: router),
      ),
    );
  } catch (e) {
    debugPrint('Uygulama başlatılamadı: $e');
  }
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({required this.router, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hız Tespiti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      routerConfig: router,
    );
  }
}
