import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prato_do_dia/main.dart';
import 'package:prato_do_dia/pages/camera_overlay_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  String _apiBaseUrl = '';

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

  Future<void> _showSettingsDialog() async {
    final controller = TextEditingController(text: _apiBaseUrl);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('API Settings'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'API URL',
                  hintText: 'http://192.168.1.15:42917',
                  errorText: errorText,
                ),
                keyboardType: TextInputType.url,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final input = controller.text.trim();
                    final uri = Uri.tryParse(input);
                    final isValidUri = uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https') &&
                        uri.host.isNotEmpty;

                    if (!isValidUri) {
                      setDialogState(() {
                        errorText =
                            'Enter a valid URL with http:// or https://';
                      });
                      return;
                    }

                    setState(() {
                      _apiBaseUrl = input;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prato do dia"),
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
            tooltip: 'API Settings',
          ),
        ],
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
