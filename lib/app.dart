import 'package:flutter/material.dart';
import 'package:prato_do_dia/pages/home_page.dart';

// Classe principal do aplicativo que configura e iniciatodo o projeto
// StatelessWidget porque não precisa manter estado - é apenas configuracão
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Construtor com key opcional para identificação de widget

  @override
  Widget build(BuildContext context) {
    // MaterialApp é o widget raiz que configura o aplicativo Flutter
    return MaterialApp(
      title: 'Prato do Dia', // Nome do aplicativo (aparece no task manager)

      // Tema visual personalizado do aplicativo
      theme: ThemeData(
        primarySwatch: Colors.orange, // Cor primária laranja (tema alimentar)
        fontFamily: 'Poppins', // Fonte moderna e legível paratodo o app

        // Personalização específica da AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange, // Cor de fundo laranja
          foregroundColor: Colors.white, // Cor do texto e ícones (branco)
          elevation: 0, // Remove sombra para visual mais plano e moderno
        ),
      ),

      // Define a tela inicial do aplicativo
      home: const HomePage(), // HomePage é a primeira tela que o usuário vê
    );
  }
}