// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:yate_diamond/main.dart';

void main() {
  testWidgets('Mi app carga correctamente', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: 'https://dhgryxgpsmmjfiqqijnu.supabase.co',
      anonKey: 'sb_publishable_j2Jj6SfzaHS-kUNCqN2TzQ_pdiBYfrT',
    );

    // Construimos la app
    await tester.pumpWidget(const DiamondApp());
    await tester.pumpAndSettle();

    // Verificamos que la pantalla principal muestra el texto de bienvenida.
    expect(find.text('DIAMOND'), findsOneWidget);
  });
}
