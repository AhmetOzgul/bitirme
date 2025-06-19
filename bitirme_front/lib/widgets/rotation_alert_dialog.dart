import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RotationDialogModel extends ChangeNotifier {
  static const _prefKey = 'dont_show_rotation_alert';
  bool dontShowAgain = false;

  void toggleDontShowAgain(bool? value) {
    if (value != null) {
      dontShowAgain = value;
      notifyListeners();
    }
  }

  Future<void> savePreference() async {
    if (dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    }
  }

  static Future<bool> shouldShowAlert() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefKey) ?? false);
  }
}

class RotationAlertDialog extends StatelessWidget {
  const RotationAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => RotationDialogModel(),
      child: Consumer<RotationDialogModel>(
        builder: (context, model, _) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/rotate.gif', width: 180, height: 180),
                  const SizedBox(height: 24),
                  // Text(
                  //   'Kamera Yatay Modda',
                  //   style: theme.textTheme.titleLarge?.copyWith(
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  const SizedBox(height: 12),
                  Text(
                    'Akıcı bir deneyim için lütfen telefonunuzu yatay konuma getirip arabanın ön konsoluna sabitleyin.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: model.dontShowAgain,
                        onChanged: model.toggleDontShowAgain,
                      ),
                      Text(
                        'Bir daha gösterme',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          await model.savePreference();
                          if (context.mounted) {
                            context.pop(true);
                          }
                        },
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
