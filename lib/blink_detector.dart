import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class BlinkDetector {
  final void Function() onBlink;
  late final FaceDetector _detector;
  CameraController? _controller;
  CameraController? get controller => _controller;

  bool _processing = false;
  DateTime _lastBlink = DateTime.now();

  BlinkDetector({required this.onBlink}) {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );

    _controller = CameraController(front, ResolutionPreset.low, enableAudio: false);
    await _controller!.initialize();
    await _controller!.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_processing || _controller == null || !_controller!.value.isInitialized) return;
    _processing = true;

    try {
      final inputImage = _toInputImage(image, _controller!);
      final faces = await _detector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final f = faces.first;
        final left = f.leftEyeOpenProbability ?? -1.0;
        final right = f.rightEyeOpenProbability ?? -1.0;

        if (left >= 0 && right >= 0 && left < 0.4 && right < 0.4) {
          if (DateTime.now().difference(_lastBlink).inMilliseconds > 800) {
            _lastBlink = DateTime.now();
            onBlink();
          }
        }
      } else {
      }
    } catch (e) {
    } finally {
      _processing = false;
    }
  }

  InputImage _toInputImage(CameraImage image, CameraController controller) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      final bytes = allBytes.done().buffer.asUint8List();
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final rotation = InputImageRotationValue.fromRawValue(
            controller.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      // Manually force NV21 format which MLKit supports
      const format = InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint("❌ Failed to convert image: $e");
      return InputImage.fromBytes(
        bytes: Uint8List(0),
        metadata: InputImageMetadata(
          size: const Size(0, 0),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 0,
        ),
      );
    }
  }

  void dispose() {
    _controller?.dispose();
    _detector.close();
  }
}
