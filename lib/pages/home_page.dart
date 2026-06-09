import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:prato_do_dia/pages/camera_overlay_page.dart';
import 'package:prato_do_dia/main.dart';

// Página principal do aplicativo - Home Screen
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage; // Armazena a imagem selecionada/tiranda
  bool _isProcessing = false; // Controla o estado de processamento
  Map<String, dynamic>? _foodData; // Armazena os dados nutricionais recebidos
  String _apiBaseUrl = 'http://10.0.2.2:42917'; // URL base padrão da API (Android Emulator)
  bool _showOverlay = true; // Controla se mostra a imagem de overlay ou original
  String _processingStatus = "Analisando seu prato..."; // Mensagem de processamento
  bool _isDevCollectorMode = false; // Modo desenvolvedor para coletar fotos do dataset

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  // Carrega a URL da API e configurações salvas anteriormente no storage local
  Future<void> _loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiBaseUrl = prefs.getString('api_base_url') ?? 'http://10.0.2.2:42917';
      _isDevCollectorMode = prefs.getBool('is_dev_collector_mode') ?? false;
    });
  }

  // Abre um diálogo para alterar a URL base da API
  void _showSettingsDialog() {
    final controller = TextEditingController(text: _apiBaseUrl);
    bool localDevMode = _isDevCollectorMode;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Configurações da API"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Insira a URL base da API FastAPI (ex: http://10.0.2.2:42917 no emulador Android ou o IP do computador na rede local para celular físico):",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "URL Base da API",
                      hintText: "http://<IP_DO_COMPUTADOR>:<PORTA>",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Modo Coletor (Dev)"),
                    subtitle: const Text("Salva fotos brutas originais localmente na pasta do dataset sem enviar à API"),
                    value: localDevMode,
                    activeThumbColor: Colors.orange,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        localDevMode = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newUrl = controller.text.trim();
                    final uri = Uri.tryParse(newUrl);
                    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL inválida. Use o formato: http://ip:porta'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _apiBaseUrl = newUrl;
                      _isDevCollectorMode = localDevMode;
                    });
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('api_base_url', newUrl);
                    await prefs.setBool('is_dev_collector_mode', localDevMode);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Configurações salvas! Modo Coletor: ${localDevMode ? "Ativado" : "Desativado"}')),
                    );
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Constrói o widget que exibe as informações nutricionais do prato
  Widget _buildFoodInfo() {
    return Container(
      width: double.infinity, // Ocupa toda a largura disponível
      padding: const EdgeInsets.all(16), // Espaçamento interno
      margin: const EdgeInsets.only(top: 20), // Margem superior
      decoration: BoxDecoration(
        color: Colors.grey[50], // Cor de fundo cinza claro
        borderRadius: BorderRadius.circular(16), // Bordas arredondadas
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)), // Borda laranja
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento à esquerda
        children: [
          // Nome do prato
          Text(
            _foodData!['name'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16), // Espaçamento

          // Linha de cartões nutricionais (Calorias e Proteínas)
          Row(
            children: [
              _buildNutritionCard("Calorias", "${_foodData!['calories']} kcal"),
              const SizedBox(width: 12), // Espaçamento entre cartões
              _buildNutritionCard("Proteínas", "${_foodData!['protein']}g"),
            ],
          ),
          const SizedBox(height: 12), // Espaçamento

          // Linha de cartões nutricionais (Carboidratos e Gorduras)
          Row(
            children: [
              _buildNutritionCard("Carboidratos", "${_foodData!['carbs']}g"),
              const SizedBox(width: 12), // Espaçamento entre cartões
              _buildNutritionCard("Gorduras", "${_foodData!['fat']}g"),
            ],
          ),
          const SizedBox(height: 16), // Espaçamento

          // Título dos ingredientes
          const Text(
            "Ingredientes principais:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8), // Espaçamento

          // Lista de ingredientes em formato de chips
          Wrap(
            spacing: 8, // Espaçamento entre chips
            children: List<Widget>.from(
              _foodData!['ingredients'].map((ingredient) => Chip(
                label: Text(ingredient),
                backgroundColor: Colors.orange.withValues(alpha: 0.1), // Fundo laranja claro
              )),
            ),
          ),
          const SizedBox(height: 16), // Espaçamento

          // Pontuação nutricional
          Row(
            children: [
              const Text(
                "Pontuação nutricional: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8), // Espaçamento
              Text(
                "${_foodData!['score']}/10", // Exibe a pontuação
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  // Cor verde se score > 7, laranja caso contrário
                  color: _foodData!['score'] > 7 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildDetectionDetails(),
        ],
      ),
    );
  }

  // Constrói a lista detalhada de componentes identificados pela IA
  Widget _buildDetectionDetails() {
    final List<dynamic>? components = _foodData!['components'];
    if (components == null || components.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Componentes Identificados (IA):",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...components.map((comp) {
          final double confidence = (comp['confidence'] as num).toDouble() * 100;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone ilustrativo com cor dinâmica baseada na confiança
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (confidence > 80 ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: confidence > 80 ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            comp['label'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "${confidence.toStringAsFixed(0)}% conf.",
                            style: TextStyle(
                              fontSize: 12,
                              color: confidence > 80 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${comp['calories']} kcal | Prot: ${comp['protein']}g | Carb: ${comp['carbs']}g | Gord: ${comp['fat']}g",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Constrói um cartão individual de informação nutricional
  Widget _buildNutritionCard(String title, String value) {
    return Expanded( // Ocupa espaço igual na linha
      child: Container(
        padding: const EdgeInsets.all(12), // Espaçamento interno
        decoration: BoxDecoration(
          color: Colors.white, // Fundo branco
          borderRadius: BorderRadius.circular(12), // Bordas arredondadas
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1), // Sombra sutil
              blurRadius: 4, // Desfoque da sombra
              offset: const Offset(0, 2), // Direção da sombra (para baixo)
            )
          ],
        ),
        child: Column(
          children: [
            // Título do nutriente (ex: "Calorias")
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4), // Pequeno espaçamento
            // Valor do nutriente (ex: "650 kcal")
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Auxiliar para obter a pasta do dataset em modo desenvolvedor
  Future<Directory?> _getDatasetDirectory() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${documentsDir.path}/dataset');
    await dir.create(recursive: true);
    return dir;
  }

  // Função para abrir a câmera e tirar uma foto
  Future<void> _takePicture() async {
    // Verifica se há câmeras disponíveis
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma câmera disponível.')),
      );
      return;
    }

    // Navega para a tela da câmera e aguarda o resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraOverlayPage(
          camera: cameras.first,
          isDevMode: _isDevCollectorMode,
        ),
      ),
    );

    if (!mounted) return;

    // Se retornou uma imagem, processa ela (apenas no modo normal)
    if (!_isDevCollectorMode && result != null && result is File) {
      _processImage(result);
    } else if (_isDevCollectorMode) {
      // Notifica o término da sessão no modo desenvolvedor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão de coleta encerrada. Fotos salvas no dispositivo.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Função para selecionar imagem da galeria
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    // Abre a galeria para seleção de imagem
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // Se selecionou uma imagem, processa ela
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (_isDevCollectorMode) {
        try {
          final Directory? extDir = await _getDatasetDirectory();
          if (extDir != null) {
            final String fileName = 'img_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final String filePath = '${extDir.path}/$fileName';
            await file.copy(filePath);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imagem da galeria salva no dataset: $fileName'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao salvar imagem no dataset: $e'), backgroundColor: Colors.redAccent),
            );
          }
        }
      } else {
        _processImage(file);
      }
    }
  }

  // Corta e comprime a imagem em quadrado central de 640x640 com 80% de qualidade
  Future<File> _optimizeImage(File originalFile) async {
    setState(() {
      _processingStatus = "Otimizando imagem...";
    });

    final bytes = await originalFile.readAsBytes();
    
    // Decodifica a imagem usando a biblioteca 'image'
    final image = img.decodeImage(bytes);
    if (image == null) return originalFile;

    final int width = image.width;
    final int height = image.height;
    
    // O tamanho do crop box corresponde a 85% do menor lado da foto (combinando com o overlay circular de 85% da tela)
    final int referenceWidth = width < height ? width : height;
    final int cropSize = (referenceWidth * 0.85).round();

    final int x = (width - cropSize) ~/ 2;
    final int y = (height - cropSize) ~/ 2;

    // Corta a imagem para o quadrado correspondente ao overlay
    final cropped = img.copyCrop(image, x: x, y: y, width: cropSize, height: cropSize);

    // Redimensiona para a resolução nativa do YOLO (640x640)
    final resized = img.copyResize(cropped, width: 640, height: 640);

    // Comprime para JPEG com qualidade 80
    final compressedBytes = img.encodeJpg(resized, quality: 80);

    // Salva em um arquivo temporário permanente na sessão
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  // Processa a imagem (envia para API e recebe os dados reais)
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true; // Ativa indicador de carregamento
      _selectedImage = imageFile; // Armazena a imagem
      _foodData = null; // Limpa dados anteriores
      _showOverlay = true; // Exibe o overlay por padrão
    });

    File optimizedFile = imageFile;
    try {
      optimizedFile = await _optimizeImage(imageFile);
      setState(() {
        _selectedImage = optimizedFile;
        _processingStatus = "Analisando seu prato...";
      });
    } catch (e) {
      debugPrint("Erro ao otimizar imagem: $e");
      setState(() {
        _processingStatus = "Analisando seu prato...";
      });
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/meals/analyze'),
      );
      
      // Adiciona o arquivo de imagem otimizado à requisição
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          optimizedFile.path,
        ),
      );

      // Envia a requisição com tempo limite de 15 segundos
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _foodData = responseData; // Armazena os dados recebidos
          _isProcessing = false; // Desativa indicador de carregamento
        });
      } else {
        throw HttpException(
          'Erro no servidor (${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException catch (_) {
      setState(() {
        _isProcessing = false; // Desativa carregamento em caso de erro
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Tempo limite de conexão esgotado (15s). Servidor indisponível.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false; // Desativa carregamento em caso de erro
      });
      // Mostra mensagem de erro para o usuário
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar imagem: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prato do Dia"), // Título do app
        centerTitle: true, // Centraliza o título
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Configurações da API",
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView( // Permite rolagem
        padding: const EdgeInsets.all(16), // Padding geral
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Centraliza horizontalmente
          children: [
            if (_isDevCollectorMode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.developer_mode, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "MODO DEV: COLETOR ATIVO",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          Text(
                            "As fotos tiradas serão salvas brutas no dispositivo para treino.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 20), // Espaçamento
            // Texto explicativo
            const Text(
              "Descubra as informações nutricionais do seu prato",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 30), // Espaçamento

            // Se há imagem selecionada, mostra ela (com suporte a alternar overlay)
            if (_selectedImage != null) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), // Borda arredondada
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3), // Sombra
                      blurRadius: 10, // Desfoque
                      offset: const Offset(0, 4), // Direção
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16), // Borda arredondada
                      child: (_showOverlay && _foodData != null && _foodData!['overlay_url'] != null)
                          ? Image.network(
                              '$_apiBaseUrl${_foodData!['overlay_url']}',
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.file(
                                  _selectedImage!,
                                  width: 250,
                                  height: 250,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.file(
                              _selectedImage!, // Imagem selecionada local
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (_foodData != null && _foodData!['overlay_url'] != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FloatingActionButton.small(
                          onPressed: () {
                            setState(() {
                              _showOverlay = !_showOverlay;
                            });
                          },
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          tooltip: _showOverlay ? "Ver Foto Original" : "Ver Segmentação",
                          child: Icon(_showOverlay ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // Espaçamento
            ],

            // Se está processando, mostra indicador de carregamento
            if (_isProcessing) ...[
              Column(
                children: [
                  const CircularProgressIndicator( // Indicador circular
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  const SizedBox(height: 16), // Espaçamento
                  Text(
                    _processingStatus, // Texto de carregamento dinâmico
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ],

            // Se há dados nutricionais, mostra as informações
            if (_foodData != null) _buildFoodInfo(),

            // Se não há imagem selecionada, mostra ícone ilustrativo
            if (_selectedImage == null) ...[
              const SizedBox(height: 50), // Espaçamento
              Icon(
                Icons.restaurant, // Ícone de restaurante
                size: 150,
                color: Colors.orange.withValues(alpha: 0.7), // Cor laranja
              ),
              const SizedBox(height: 30), // Espaçamento
            ],

            const SizedBox(height: 30), // Espaçamento

            // Botões de ação (Tirar Foto e Galeria)
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centraliza botões
              children: [
                // Botão para tirar foto
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _takePicture, // Desabilita se processando
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Tirar Foto"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Fundo laranja
                    foregroundColor: Colors.white, // Texto branco
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16), // Espaçamento entre botões

                // Botão para selecionar da galeria
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _selectImage, // Desabilita se processando
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Galeria"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Fundo branco
                    foregroundColor: Colors.orange, // Texto laranja
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: Colors.orange), // Borda laranja
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}