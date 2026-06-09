import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prato_do_dia/app.dart';

void main() {
  testWidgets('Valida o carregamento inicial da HomePage', (WidgetTester tester) async {
    // Reconstrói o app e dispara o frame.
    await tester.pumpWidget(const MyApp());

    // Verifica se o título "Prato do Dia" é exibido.
    expect(find.text('Prato do Dia'), findsWidgets);

    // Verifica se o texto de instrução inicial está presente.
    expect(
      find.text('Descubra as informações nutricionais do seu prato'),
      findsOneWidget,
    );

    // Verifica se os botões "Tirar Foto" e "Galeria" estão presentes.
    expect(find.text('Tirar Foto'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);

    // Verifica se o ícone ilustrativo de restaurante é exibido na inicialização.
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });
}

