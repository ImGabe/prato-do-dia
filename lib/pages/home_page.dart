import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  // Carrega a URL da API salva anteriormente no storage local
  Future<void> _loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiBaseUrl = prefs.getString('api_base_url') ?? 'http://10.0.2.2:42917';
    });
  }

  // Abre um diálogo para alterar a URL base da API
  void _showSettingsDialog() {
    final controller = TextEditingController(text: _apiBaseUrl);
    showDialog(
      context: context,
      builder: (context) {
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
                });
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('api_base_url', newUrl);
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('URL da API salva: $_apiBaseUrl')),
                );
              },
              child: const Text("Salvar"),
            ),
          ],
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
        ],
      ),
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
        builder: (context) => CameraOverlayPage(camera: cameras.first),
      ),
    );

    // Se retornou uma imagem, processa ela
    if (result != null && result is File) {
      _processImage(result);
    }
  }

  // Função para selecionar imagem da galeria
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    // Abre a galeria para seleção de imagem
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // Se selecionou uma imagem, processa ela
    if (pickedFile != null) {
      _processImage(File(pickedFile.path));
    }
  }

  // Processa a imagem (envia para API e recebe os dados reais)
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true; // Ativa indicador de carregamento
      _selectedImage = imageFile; // Armazena a imagem
      _foodData = null; // Limpa dados anteriores
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/meals/analyze'),
      );
      
      // Adiciona o arquivo de imagem à requisição
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
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
            const SizedBox(height: 20), // Espaçamento
            // Texto explicativo
            const Text(
              "Descubra as informações nutricionais do seu prato",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 30), // Espaçamento

            // Se há imagem selecionada, mostra ela
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16), // Borda arredondada
                  child: Image.file(
                    _selectedImage!, // Imagem selecionada
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover, // Preenche o espaço
                  ),
                ),
              ),
              const SizedBox(height: 20), // Espaçamento
            ],

            // Se está processando, mostra indicador de carregamento
            if (_isProcessing) ...[
              const Column(
                children: [
                  CircularProgressIndicator( // Indicador circular
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 16), // Espaçamento
                  Text(
                    "Analisando seu prato...", // Texto de carregamento
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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