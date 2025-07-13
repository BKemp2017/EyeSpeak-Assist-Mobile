import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // for WriteBuffer
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class BlinkDetector {
  final void Function() onBlink;
  late final FaceDetector _detector;
  CameraController? _controller;
  bool _processing = false;
  DateTime _lastBlink = DateTime.now();

  BlinkDetector({required this.onBlink}) {
    _detector = FaceDetector(options: FaceDetectorOptions());
    _initialize();
  }

  Future<void> _initialize() async {
    final cams = await availableCameras();
    if (cams.isEmpty) return;
    _controller = CameraController(cams.first, ResolutionPreset.medium);
    await _controller!.initialize();
    await _controller!.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_processing) return;
    _processing = true;
    try {
      final inputImage = _toInputImage(image, _controller!);
      final faces = await _detector.processImage(inputImage);
      if (faces.isNotEmpty) {
        final f = faces.first;
        final left = f.leftEyeOpenProbability ?? 1.0;
        final right = f.rightEyeOpenProbability ?? 1.0;
        if (left < 0.4 && right < 0.4) {
          if (DateTime.now().difference(_lastBlink).inMilliseconds > 500) {
            _lastBlink = DateTime.now();
            onBlink();
          }
        }
      }
    } catch (_) {
      // Log error if needed
    } finally {
      _processing = false;
    }
  }

  InputImage _toInputImage(CameraImage image, CameraController controller) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final rotation = InputImageRotationValue.fromRawValue(
          controller.description.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  void dispose() {
    _controller?.dispose();
    _detector.close();
  }
}
