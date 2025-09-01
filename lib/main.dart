import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:prato_do_dia/app.dart';

// ✅ Torne a variável global (fora de qualquer classe)
List<CameraDescription> cameras = []; // Inicialize com lista vazia

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras(); // Preenche a variável global
  } catch (e) {
    print("Erro ao carregar câmeras: $e");
    cameras = []; // Mantém lista vazia em caso de erro
  }

  runApp(const MyApp());
}