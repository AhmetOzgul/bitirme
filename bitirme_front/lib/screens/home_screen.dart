import 'package:bitirme_front/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../widgets/rotation_alert_dialog.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen(this.cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.speed, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Tabela Tanıma Sistemi',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hız tabelalarını otomatik olarak tespit edin',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),

                const Spacer(),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CustomButton(
                          theme: theme,
                          title: 'Canlı Tespit Başlat',
                          icon: Icons.camera_alt,
                          onPressed: () => _handleCameraButtonPress(context),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          theme: theme,
                          title: 'Ayarlar',
                          icon: Icons.settings,
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _handleCameraButtonPress(BuildContext context) async {
  final shouldShow = await RotationDialogModel.shouldShowAlert();

  if (!shouldShow) {
    if (context.mounted) {
      context.push('/camera');
    }
    return;
  }

  if (context.mounted) {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RotationAlertDialog(),
    );

    if (result == true && context.mounted) {
      context.push('/camera');
    }
  }
}
