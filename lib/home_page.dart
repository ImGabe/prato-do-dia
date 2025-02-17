import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_overlay_page.dart';
import 'main.dart'; // Import the camera page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;

  Future<void> _takePicture() async {
    if (cameras.isEmpty) {
      // Handle the case where no cameras are available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera available.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraOverlayPage(camera: cameras.last),
      ),
    );

    if (result != null && result is File) {
      setState(() {
        _selectedImage = result;
      });
    }
  }

  Future<void> _selectImage() async {
    // TODO: Implement image selection from gallery
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prato do dia"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImage != null
                ? Image.file(
              _selectedImage!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            )
                : const Text("Nenhuma imagem selecionada"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePicture,
              child: const Text("Tirar Foto"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectImage,
              child: const Text("Selecionar da Galeria"),
            ),
          ],
        ),
      ),
    );
  }
}