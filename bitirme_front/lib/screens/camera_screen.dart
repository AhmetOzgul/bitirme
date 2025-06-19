import 'package:bitirme_front/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import '../providers/detection_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/sound_provider.dart';
import '../providers/speed_provider.dart';
import '../services/ws_service.dart';
import '../widgets/expanding_action_button.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen(this.cameras, {super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late WsService _wsService;
  bool _isProcessing = false;
  bool _isDisposed = false;
  final _soundButtonController = ExpandingActionButtonController();
  final _vehicleButtonController = ExpandingActionButtonController();

  @override
  void initState() {
    super.initState();
    _wsService = WsService();
    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vehicleType = context.watch<VehicleProvider>().type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DetectionProvider>().setVehicleType(vehicleType);
      }
    });
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.cameras.first, ResolutionPreset.high);

    try {
      await _controller.initialize();
      if (!mounted || _isDisposed) return;

      final provider = context.read<DetectionProvider>();
      _wsService.listen(provider);

      await _controller.startImageStream((CameraImage img) {
        if (!mounted || _isDisposed) return;
        if (!_isProcessing) {
          _isProcessing = true;
          _wsService.sendFrame(img).whenComplete(() {
            if (mounted && !_isDisposed) {
              _isProcessing = false;
            }
          });
        }
      });

      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Kamera başlatılamadı: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isProcessing) _isProcessing = false;
    if (_controller.value.isStreamingImages) {
      _controller.stopImageStream();
    }
    _wsService.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSoundButton() {
    final soundMode = context.watch<SoundProvider>().mode;
    return ExpandingActionButton<SoundMode>(
      controller: _soundButtonController,
      selectedValue: soundMode,
      options:
          SoundMode.values
              .map((value) => (value: value, icon: value.icon))
              .toList(),
      onChanged: (mode) => context.read<SoundProvider>().setMode(mode),
      backgroundColor: Colors.white.withOpacity(0.9),
    );
  }

  Widget _buildVehicleButton() {
    final vehicleType = context.watch<VehicleProvider>().type;
    return ExpandingActionButton<VehicleType>(
      controller: _vehicleButtonController,
      selectedValue: vehicleType,
      options:
          VehicleType.values
              .map((value) => (value: value, icon: value.icon))
              .toList(),
      onChanged: (type) {
        context.read<VehicleProvider>().setType(type);
        context.read<DetectionProvider>().setVehicleType(type);
      },
      backgroundColor: Colors.white.withOpacity(0.9),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detections = context.watch<DetectionProvider>().detections;
    final vehicleType = context.watch<VehicleProvider>().type;
    final soundMode = context.watch<SoundProvider>().mode;
    final currentSpeed = context.watch<SpeedProvider>().currentSpeed;
    final isLocationEnabled =
        context.watch<SpeedProvider>().isLocationServiceEnabled;
    final lastSpeed = context.watch<DetectionProvider>().getLastSpeed(
      vehicleType,
    );

    final speeds =
        detections
            .map((d) => int.tryParse(d.text) ?? 0)
            .where((v) => v > 0)
            .toList()
          ..sort((b, a) => a.compareTo(b));

    int? selectedSpeed;
    if (speeds.isNotEmpty) {
      switch (vehicleType) {
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
    }
    final speedText =
        selectedSpeed?.toString() ?? lastSpeed?.toString() ?? '--';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Tespit'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                vehicleType.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _controller.value.isInitialized
              ? GestureDetector(
                onTap: () {
                  _soundButtonController.close?.call();
                  _vehicleButtonController.close?.call();
                  FocusScope.of(context).unfocus();
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.previewSize!.height,
                          height: _controller.value.previewSize!.width,
                          child: CameraPreview(_controller),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 175,
                      left: 270,
                      child: Transform.rotate(
                        angle: 1.57,
                        child: Speedometer(
                          isLocationEnabled: isLocationEnabled,
                          currentSpeed: currentSpeed,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: SpeedLimitSign(speedText: speedText),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      child: IgnorePointer(
                        ignoring: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildSoundButton(),
                            const SizedBox(height: 8),
                            _buildVehicleButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

class SpeedLimitSign extends StatelessWidget {
  const SpeedLimitSign({super.key, required this.speedText});

  final String speedText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 9),
      ),
      child: Center(
        child: Transform.rotate(
          angle: 1.57,
          child: Text(
            speedText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class Speedometer extends StatelessWidget {
  const Speedometer({
    super.key,
    required this.isLocationEnabled,
    required this.currentSpeed,
  });

  final bool isLocationEnabled;
  final double currentSpeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          isLocationEnabled
              ? '${currentSpeed.toStringAsFixed(1)} km/s'
              : 'GPS Kapalı',
          style: TextStyle(
            color: isLocationEnabled ? Colors.green : Colors.red,
            fontSize: 32,
            height: 1,
            fontFamily: 'Digital',
          ),
        ),
      ),
    );
  }
}

// class _DetectionPainter extends CustomPainter {
//   final List<Detection> detections;
//   _DetectionPainter(this.detections);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 2
//           ..color = Colors.red;
//     final textPainter = TextPainter(textDirection: TextDirection.ltr);

//     for (var det in detections) {
//       canvas.drawRect(det.box, paint);
//       final tp = TextSpan(
//         text: det.text,
//         style: const TextStyle(color: Colors.yellow, fontSize: 16),
//       );
//       textPainter.text = tp;
//       textPainter.layout();
//       textPainter.paint(
//         canvas,
//         Offset(det.box.left, det.box.top - textPainter.height - 4),
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _DetectionPainter old) =>
//       old.detections != detections;
// }
