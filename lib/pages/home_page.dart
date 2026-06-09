import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prato_do_dia/main.dart';
import 'package:prato_do_dia/pages/camera_overlay_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String defaultApiBaseUrl = 'http://10.0.2.2:42917';
const String apiBaseUrlPreferenceKey = 'api_base_url';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  String _apiBaseUrl = defaultApiBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadApiBaseUrl();
  }

  Future<void> _loadApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final storedApiBaseUrl = prefs.getString(apiBaseUrlPreferenceKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _apiBaseUrl = storedApiBaseUrl ?? defaultApiBaseUrl;
    });
  }

  Future<void> _saveApiBaseUrl(String apiBaseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiBaseUrlPreferenceKey, apiBaseUrl);

    if (!mounted) {
      return;
    }

    setState(() {
      _apiBaseUrl = apiBaseUrl;
    });
  }

  Future<void> _openSettingsDialog() async {
    final controller = TextEditingController(text: _apiBaseUrl);

    final newApiBaseUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'API Base URL'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newApiBaseUrl == null || newApiBaseUrl.isEmpty) {
      return;
    }

    if (!_isValidApiBaseUrl(newApiBaseUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid API Base URL.')),
      );
      return;
    }

    await _saveApiBaseUrl(newApiBaseUrl);
  }

  bool _isValidApiBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return false;
    }

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

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
        actions: [
          IconButton(
            onPressed: _openSettingsDialog,
            icon: const Icon(Icons.settings),
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
