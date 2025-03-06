import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prato_do_dia/widgets/opacity_overlay_circle.dart';

class CameraOverlayPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraOverlayPage({super.key, required this.camera});

  @override
  _CameraOverlayPageState createState() => _CameraOverlayPageState();
}

class _CameraOverlayPageState extends State<CameraOverlayPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _controller.takePicture();
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Pictures/flutter_test';
      await Directory(dirPath).create(recursive: true);
      final String filePath =
          '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(image.path);
      final File newImage = await file.copy(filePath);
      if (mounted) {
        Navigator.pop(context, newImage);
      }
    } catch (e) {
      print("Erro ao tirar foto: $e");
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    Center(
                      child: CameraPreview(_controller),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: CircleOverlay(),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          onPressed: _takePicture,
                          child: Icon(Icons.camera_alt),
                        ),
                      ),
                    ),
                  ],
                );
              })),
    );
  }
}
