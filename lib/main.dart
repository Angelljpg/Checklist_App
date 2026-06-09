import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTAMOS LA PANTALLA PRINCIPAL
import 'screens/main_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dhgryxgpsmmjfiqqijnu.supabase.co',
    anonKey: 'sb_publishable_j2Jj6SfzaHS-kUNCqN2TzQ_pdiBYfrT',
  );

  // 1. FORZAMOS QUE LAS BARRAS DEL SISTEMA SEAN NEGRAS (Batería y Navegación)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Franja negra arriba
      systemNavigationBarColor: Colors.black, // Franja negra abajo
      statusBarIconBrightness: Brightness.light, // Íconos blancos (hora, batería)
      systemNavigationBarIconBrightness: Brightness.light, 
    ),
  );

  // 2. FORZAMOS LA ORIENTACIÓN HORIZONTAL
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const DiamondApp());
  });
}

final supabase = Supabase.instance.client;

class DiamondApp extends StatelessWidget {
  const DiamondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Operativo Diamond',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      
      // =========================================================
      // SOLUCIÓN TABLET: SAFE AREA CON BORDES NEGROS
      // =========================================================
      builder: (context, child) {
        return Scaffold(
          // El fondo negro se verá en los espacios que deje el SafeArea
          backgroundColor: Colors.black, 
          body: SafeArea(
            // SafeArea evita físicamente que tu app se encime con los botones de abajo o la cámara de arriba
            bottom: true,
            top: true,
            left: true,
            right: true,
            child: ClipRRect(
              // Le damos un borde ligeramente redondeado a la app para separarla de las barras negras
              borderRadius: BorderRadius.circular(12),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      // =========================================================

      home: const MainScreen(),
    );
  }
}