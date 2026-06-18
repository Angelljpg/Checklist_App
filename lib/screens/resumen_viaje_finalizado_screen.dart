import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ver_reporte_screen.dart';

class ResumenViajeFinalizadoScreen extends StatefulWidget {
  final String viajeId;
  final String nombreViaje;

  const ResumenViajeFinalizadoScreen({super.key, required this.viajeId, required this.nombreViaje});

  @override
  State<ResumenViajeFinalizadoScreen> createState() => _ResumenViajeFinalizadoScreenState();
}

class _ResumenViajeFinalizadoScreenState extends State<ResumenViajeFinalizadoScreen> {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _cargarDatosHistoricos() async {
    // Consultamos los datos globales del viaje y las notas de bitácora ligadas al mismo tiempo
    final respuestas = await Future.wait([
      supabase.from('viajes').select().eq('id', widget.viajeId).single(),
      supabase.from('bitacora_diaria').select().eq('viaje_id', widget.viajeId).order('fecha', ascending: true)
    ]);

    return {
      'viaje': respuestas[0] as Map<String, dynamic>,
      'bitacora': respuestas[1] as List<dynamic>
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: Text('AUDITORÍA: ${widget.nombreViaje.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cargarDatosHistoricos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar el histórico del viaje.'));
          }

          final viaje = snapshot.data!['viaje'];
          final bitacora = snapshot.data!['bitacora'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row( // <-- VISTA EN DOS COLUMNAS IDEAL PARA TABLET
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLUMNA IZQUIERDA: RESUMEN EJECUTIVO Y FIRMAS
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.fact_check, color: Color(0xFF1E293B)),
                                    SizedBox(width: 10),
                                    Text('Información de Cierre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  ],
                                ),
                                const Divider(height: 25),
                                
                                // ¡NUEVO BOTÓN PARA VER EL REPORTE EN LA APP!
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                      ),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => VerReporteScreen(viajeId: widget.viajeId)
                                        ));
                                      },
                                      icon: const Icon(Icons.assignment, color: Colors.white),
                                      label: const Text('VER REPORTE DE CIERRE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                _buildInfoRow(Icons.location_on, 'Destino', '${viaje['destino'] ?? 'No registrado'}'),
                                _buildInfoRow(Icons.person, 'Capitán Responsable', '${viaje['nombre_capitan_cierre'] ?? 'Sin firmar'}'),
                                _buildInfoRow(Icons.calendar_today, 'Fecha de Cierre', viaje['fecha_cierre'] != null 
                                    ? DateTime.parse(viaje['fecha_cierre']).toLocal().toString().substring(0, 16)
                                    : 'Sin fecha'),
                                _buildInfoRow(Icons.people, 'Pasajeros / Tripulación', '${viaje['cantidad_pasajeros'] ?? 0} invitados • ${viaje['tripulantes'] ?? 0} tripulantes'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Card(
                          elevation: 2,
                          color: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blue.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 10),
                                    Text('Bitácora Logística (Info. Tripulación)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                  ],
                                ),
                                const Divider(height: 20, color: Colors.blueAccent),
                                // Aquí el Capitán siempre verá el texto original pegado por el tripulante
                                Text(
                                  viaje['menu_especiales'] ?? 'No se proporcionó información logística.',
                                  style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),

                // COLUMNA DERECHA: LÍNEA DE TIEMPO DE LA BITÁCORA DIARIA
                Expanded(
                  flex: 5,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history_edu, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Text('Bitácora Operativa de Navegación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          const Divider(height: 25),
                          Expanded(
                            child: bitacora.isEmpty
                                ? const Center(child: Text('No se registraron notas de bitácora durante este viaje.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                                : ListView.builder(
                                    itemCount: bitacora.length,
                                    itemBuilder: (context, index) {
                                      final entrada = bitacora[index];
                                      final bool esIncidencia = entrada['nota_operativa']?.toString().contains('🚨') ?? false;
                                      final String hora = entrada['fecha'] != null 
                                          ? DateTime.parse(entrada['fecha']).toLocal().toString().substring(11, 16)
                                          : '--:--';

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: esIncidencia ? Colors.red.shade50 : Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: esIncidencia ? Colors.red.shade200 : Colors.grey.shade200)
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(entrada['nota_operativa'] ?? '', style: TextStyle(fontSize: 14, color: esIncidencia ? Colors.red.shade900 : Colors.black87)),
                                                    if (entrada['foto_url'] != null) ...[
                                                      const SizedBox(height: 8),
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network(entrada['foto_url'], height: 100, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                                                      )
                                                    ]
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}