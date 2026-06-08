import 'dart:io'; //
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Processa a imagem (simula envio para API e recebimento de dados)
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true; // Ativa indicador de carregamento
      _selectedImage = imageFile; // Armazena a imagem
      _foodData = null; // Limpa dados anteriores
    });

    try {
      // Simula tempo de processamento da API (2 segundos)
      await Future.delayed(const Duration(seconds: 2));

      // Dados simulados da API (substituir por chamada real)
      final simulatedResponse = {
        'name': 'Prato Feito',
        'calories': 650,
        'protein': 25,
        'carbs': 45,
        'fat': 15,
        'ingredients': ['Arroz', 'Feijão', 'Frango', 'Salada'],
        'score': 8.2,
      };

      setState(() {
        _foodData = simulatedResponse; // Armazena os dados recebidos
        _isProcessing = false; // Desativa indicador de carregamento
      });
    } catch (e) {
      setState(() {
        _isProcessing = false; // Desativa carregamento em caso de erro
      });
      // Mostra mensagem de erro para o usuário
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar imagem: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prato do Dia"), // Título do app
        centerTitle: true, // Centraliza o título
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
                  onPressed: _takePicture, // Abre câmera
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
                  onPressed: _selectImage, // Abre galeria
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