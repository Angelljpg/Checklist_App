import 'package:flutter/material.dart';
import 'main_screen.dart';

class LoginSelectorScreen extends StatelessWidget {
  const LoginSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2440), Color(0xFF0D6480)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. SECCIÓN SUPERIOR: TÍTULO MÁS PEQUEÑO Y FINO
                  const Text('YATE DIAMOND',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5)),
                  const Text('SISTEMA OPERATIVO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 3)),
                  const SizedBox(height: 35),

                  // 2. LA FLOTA
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _imagenFlota('lib/img/Yate_main.png', 190, 280),
                      _imagenFlota('lib/img/Axopar.png', 130, 200),
                      _imagenFlota('lib/img/yate.png', 110, 160),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // 3. SECCIÓN INFERIOR: BOTONES DE ACCESO SIMÉTRICOS
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 30,
                    runSpacing: 30,
                    children: [
                      // TARJETA DE OPERACIÓN
                      // TARJETA DE OPERACIÓN
                      _tarjetaAcceso(
                        context: context,
                        titulo: 'CAPITÁN / TRIPULACIÓN',
                        subtitulo:
                            'Autorización, bitácora y logística general a bordo.',
                        icono: Icons.engineering,
                        esCapitan: true,
                        // ¡AQUÍ ESTÁ EL CAMBIO! Dejamos el azulito y pasamos a un Azul Océano elegante
                        colorAccent: Theme.of(context).colorScheme.primary,
                      ),

                      // TARJETA DE DUEÑO
                      _tarjetaAcceso(
                        context: context,
                        titulo: 'PROPIETARIO',
                        subtitulo:
                            'Supervisión de flota y revisión de reportes ejecutivos.',
                        icono: Icons.person_pin,
                        esCapitan: false,
                        colorAccent: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),

                  // 4. EL ÍCONO REUBICADO
                  const SizedBox(height: 60),
                  const Icon(Icons.diamond, size: 28, color: Colors.white24),
                  const SizedBox(height: 5),
                  const Text('DIAMOND OS v1.0',
                      style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Para mostrar las fotos de las naves
  Widget _imagenFlota(String ruta, double alto, double ancho) {
    return Container(
      height: alto,
      width: ancho,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          ruta,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white10,
            child: const Icon(Icons.directions_boat,
                color: Colors.white54, size: 40),
          ),
        ),
      ),
    );
  }

  // WIDGET: Tarjetas de acceso simétricas
  Widget _tarjetaAcceso({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required bool esCapitan,
    required Color colorAccent,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(esCapitan: esCapitan))),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: colorAccent, size: 50),
              const SizedBox(height: 15),

              // ¡LA MAGIA DE LA SIMETRÍA ESTÁ AQUÍ!
              // Forzamos un alto de 55 pixeles para ambos títulos.
              SizedBox(
                height: 55,
                child: Center(
                  child: Text(titulo,
                      textAlign: TextAlign.center,
                      // Redujimos un poco la fuente a 18 para que "Capitán / Tripulación" se vea estilizado
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 5),

              // Forzamos un alto fijo al subtítulo también por seguridad
              SizedBox(
                height: 40,
                child: Text(subtitulo,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13, height: 1.2),
                    textAlign: TextAlign.center),
              ),

              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colorAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorAccent.withOpacity(0.5)),
                ),
                child: Text('INGRESAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colorAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
