import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTAMOS LA PANTALLA PRINCIPAL Y EL LOGIN
import 'screens/main_screen.dart'; 
import 'screens/login_selector_screen.dart'; // <-- NUEVO IMPORT

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase
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
        useMaterial3: true,
        // ESTA ES LA PALETA GLOBAL
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A2440), // Azul Marino
          primary: const Color(0xFF0A2440),    // Color principal
          secondary: const Color(0xFFF97316),  // Naranja Premium
        ),
        // ESTO HARÁ QUE TODOS LOS APPBAR SE VEAN IGUAL
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A2440),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black, 
          body: SafeArea(
            bottom: true,
            top: true,
            left: true,
            right: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },

      // ¡INICIAMOS EN EL SELECTOR DE ROL EN LUGAR DEL MAIN SCREEN!
      home: const LoginSelectorScreen(),
    );
  }
}