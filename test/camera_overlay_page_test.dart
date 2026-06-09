import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prato_do_dia/pages/camera_overlay_page.dart';

void main() {
  testWidgets('shows error state when camera initialization fails',
      (WidgetTester tester) async {
    const camera = CameraDescription(
      name: 'test-camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );
    final controller = CameraController(camera, ResolutionPreset.high);

    await tester.pumpWidget(
      MaterialApp(
        home: CameraOverlayPage(
          camera: camera,
          controller: controller,
          initializeControllerFuture: Future<void>.error(
            CameraException('CameraAccessDenied', 'Permission denied'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'Permissão de câmera negada. Por favor, habilite o acesso nas configurações do aparelho.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
  });
}
