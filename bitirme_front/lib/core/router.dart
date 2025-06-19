import 'package:flutter/material.dart';
import 'package:bitirme_front/screens/camera_screen.dart';
import 'package:bitirme_front/screens/home_screen.dart';
import 'package:bitirme_front/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';

final navigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(List<CameraDescription> cameras) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomeScreen(cameras)),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => CameraScreen(cameras),
      ),
    ],
  );
}
