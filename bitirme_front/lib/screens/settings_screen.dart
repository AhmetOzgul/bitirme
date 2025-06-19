import 'package:bitirme_front/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/sound_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleType = context.watch<VehicleProvider>().type;
    final soundMode = context.watch<SoundProvider>().mode;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ayarlar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Araç Türü',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Tespit edilecek araç türünü seçin',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        ...VehicleType.values.map((vt) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await context.read<VehicleProvider>().setType(
                                  vt,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: RadioListTile<VehicleType>(
                                  title: Text(
                                    vt.label,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  value: vt,
                                  groupValue: vehicleType,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (newVt) async {
                                    if (newVt != null) {
                                      await context
                                          .read<VehicleProvider>()
                                          .setType(newVt);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ses Ayarları',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Hız limiti değiştiğinde veya aşıldığında verilecek uyarıyı seçin',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        ...SoundMode.values.map((mode) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await context.read<SoundProvider>().setMode(
                                  mode,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: RadioListTile<SoundMode>(
                                  title: Text(
                                    mode.label,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  value: mode,
                                  groupValue: soundMode,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (newMode) async {
                                    if (newMode != null) {
                                      await context
                                          .read<SoundProvider>()
                                          .setMode(newMode);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
