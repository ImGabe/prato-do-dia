import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prato_do_dia/widgets/opacity_overlay_circle.dart';

// Página que exibe a câmera com um overlay circular para enquadrar o prato
class CameraOverlayPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraOverlayPage({super.key, required this.camera});

  @override
  State<CameraOverlayPage> createState() => _CameraOverlayPageState();
}

class _CameraOverlayPageState extends State<CameraOverlayPage> {
  late CameraController _controller; // Controlador para gerenciar a câmera
  late Future<void> _initializeControllerFuture; // Future para inicialização da câmera

  // Função para capturar uma foto usando a câmera
  Future<void> _takePicture() async {
    // Verifica se o controlador da câmera está inicializado
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      // Captura a foto - retorna um arquivo XFile
      final XFile image = await _controller.takePicture();

      // Obtém o diretório de documentos do aplicativo
      final Directory extDir = await getApplicationDocumentsDirectory();

      // Define o caminho para salvar as imagens
      final String dirPath = '${extDir.path}/Pictures/prato_do_dia';

      // Cria o diretório se não existir (recursive: true cria subdiretórios)
      await Directory(dirPath).create(recursive: true);

      // Cria um nome único para o arquivo usando timestamp
      final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Converte XFile para File
      final File file = File(image.path);

      // Copia a imagem para o local permanente com nome único
      final File newImage = await file.copy(filePath);

      // Verifica se o widget ainda está montado antes de navegar
      if (mounted) {
        // Retorna para a tela anterior enviando a imagem capturada
        Navigator.pop(context, newImage);
      }
    } catch (e) {
      // Trata erros durante a captura da foto
      if (mounted) {
        // Exibe mensagem de erro para o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao tirar foto: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializa o controlador da câmera com a câmera fornecida e resolução muito alta
    _controller = CameraController(widget.camera, ResolutionPreset.veryHigh);

    // Inicializa o controlador - retorna um Future que completa quando a câmera estiver pronta
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Libera os recursos da câmera quando o widget for destruído
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto para modo câmera
      body: FutureBuilder(
        future: _initializeControllerFuture, // Future da inicialização da câmera
        builder: (context, snapshot) {
          // Verifica se a câmera ainda está inicializando
          if (snapshot.connectionState != ConnectionState.done) {
            // Mostra indicador de carregamento enquanto a câmera não está pronta
            return const Center(child: CircularProgressIndicator());
          }

          // Interface da câmera quando inicializada
          return Stack(
            children: [
              // Preview da câmera - mostra o que a câmera está vendo
              CameraPreview(_controller),

              // Overlay circular centralizado para ajudar no enquadramento
              const Align(
                alignment: Alignment.center,
                child: CircleOverlay(
                  circleDiameter: 250, // Diâmetro do círculo
                  opacity: 0.6, // Opacidade do overlay
                ),
              ),

              // Texto instrucional no topo da tela
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Centralize o prato no círculo", // Instrução para o usuário
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        // Sombra no texto para melhor contraste sobre o preview
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: const Offset(0, 0),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Botão de captura personalizado na parte inferior
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _takePicture, // Ao tocar, chama a função de captura
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Fundo transparente
                        border: Border.all(color: Colors.white, width: 4), // Borda branca
                        shape: BoxShape.circle, // Formato circular
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(6), // Margem interna
                        decoration: const BoxDecoration(
                          color: Colors.white, // Círculo interno branco
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}