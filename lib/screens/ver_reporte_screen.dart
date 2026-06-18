import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerReporteScreen extends StatefulWidget {
  final String viajeId;

  const VerReporteScreen({super.key, required this.viajeId});

  @override
  State<VerReporteScreen> createState() => _VerReporteScreenState();
}

class _VerReporteScreenState extends State<VerReporteScreen> {
  final supabase = Supabase.instance.client;

  // AHORA PEDIMOS UNA LISTA DE REPORTES, NO SOLO UNO
  Future<List<Map<String, dynamic>>> _cargarReportes() async {
    final response = await supabase
        .from('reportes_finales')
        .select()
        .eq('viaje_id', widget.viajeId)
        .order('created_at', ascending: true); // Para que salgan en orden (Inventario -> Zarpe -> etc)
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Historial de Reportes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cargarReportes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final reportes = snapshot.data ?? [];
          
          if (reportes.isEmpty) {
            return const Center(
              child: Text('Aún no hay reportes firmados para este viaje.', 
                style: TextStyle(fontSize: 16, color: Colors.blueGrey)
              )
            );
          }

          // CREAMOS UNA LISTA CON TODOS LOS REPORTES ENCONTRADOS
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final data = reportes[index];
              final String capitan = data['capitan_nombre'] ?? 'Sin nombre';
              final String faltantes = data['faltantes_lista'] ?? '';
              final String observaciones = data['observaciones'] ?? '';
              final String firmaJson = data['firma_datos'] ?? '[]';
              final String fase = data['fase'] ?? 'DESCONOCIDA';
              final String fecha = data['created_at'] != null 
                  ? DateTime.parse(data['created_at']).toLocal().toString().substring(0, 16) 
                  : 'Fecha desconocida';

              // Reconstruir los puntos de la firma desde el JSON
              List<Offset?> puntosFirma = [];
              try {
                final List<dynamic> jsonList = jsonDecode(firmaJson);
                puntosFirma = jsonList.map((p) {
                  if (p == null) return null;
                  return Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble());
                }).toList();
              } catch (e) {
                puntosFirma = [];
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text('REPORTE: $fase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ),
                      const Divider(height: 30, thickness: 2),
                      
                      Text('Fecha de emisión: $fecha', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      if (faltantes.isNotEmpty) ...[
                        Text('INCIDENCIAS / FALTANTES:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(faltantes),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (observaciones.isNotEmpty) ...[
                        Text('OBSERVACIONES:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(observaciones),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Divider(height: 30),
                      const Text('Firma de Autorización:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      // LIENZO DONDE SE REDIBUJA LA FIRMA
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CustomPaint(
                            painter: SignaturePainterViewer(points: puntosFirma),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(child: Text(capitan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Pintor para dibujar la firma (Solo lectura)
class SignaturePainterViewer extends CustomPainter {
  final List<Offset?> points;
  SignaturePainterViewer({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainterViewer oldDelegate) => oldDelegate.points != points;
}