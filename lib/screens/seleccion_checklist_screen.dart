import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'items_checklist_screen.dart';

class SeleccionChecklistScreen extends StatefulWidget {
  final String viajeId;
  final String nombreViaje;
  final String tipoFase;
  final bool esCapitan;

  const SeleccionChecklistScreen(
      {super.key,
      required this.viajeId,
      required this.nombreViaje,
      required this.tipoFase,
      required this.esCapitan});

  @override
  State<SeleccionChecklistScreen> createState() =>
      _SeleccionChecklistScreenState();
}

class _SeleccionChecklistScreenState extends State<SeleccionChecklistScreen> {
  final supabase = Supabase.instance.client;
  bool _cargando = true;
  Map<String, List<Map<String, dynamic>>> _categoriasPorMacroArea = {};
  List<Offset?> _puntosFirma = [];
  final _responsableController = TextEditingController();
  final _cosasFaltantesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final data = await supabase.from('checklist_categorias').select('*');
      final Map<String, List<Map<String, dynamic>>> agrupado = {};

      for (var row in data) {
        final String macroLimpio =
            (row['macro_area']?.toString() ?? 'OTROS').trim().toUpperCase();

        if (widget.tipoFase == 'ZARPE' &&
            !macroLimpio.contains('ANTES DE PARTIR')) continue;
        if (widget.tipoFase == 'DURANTE' && !macroLimpio.contains('DURANTE'))
          continue;
        if (widget.tipoFase == 'CIERRE' &&
            !macroLimpio.contains('CIERRE DE VIAJE')) continue;
        if (widget.tipoFase == 'INVENTARIO') {
          if (macroLimpio.contains('ANTES DE PARTIR') ||
              macroLimpio.contains('DURANTE') ||
              macroLimpio.contains('CIERRE DE VIAJE')) continue;
        }

        final macroOriginal = row['macro_area'] ?? 'OTROS';
        if (!agrupado.containsKey(macroOriginal)) agrupado[macroOriginal] = [];
        agrupado[macroOriginal]!.add(row);
      }

      if (mounted)
        setState(() {
          _categoriasPorMacroArea = agrupado;
          _cargando = false;
        });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // BOTÓN DE LOGÍSTICA (REFACTURADO PARA QUE SEA GRANDE Y LIMPIO)
  void _mostrarLogistica() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logística del Viaje', style: TextStyle(fontWeight: FontWeight.bold)),
        content: FutureBuilder<Map<String, dynamic>>(
          // Asegúrate de que los campos coincidan exactamente con tu tabla de Supabase
          future: supabase.from('viajes').select('menu_especiales, preferencias_bebidas, preferencias_especiales').eq('id', widget.viajeId).single(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const Text('Error al cargar la logística.');
            }
            if (!snapshot.hasData) {
              return const Text('Sin información disponible.');
            }
            
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: ListBody(
                children: [
                  const Text('🍸 Preferencias Bar:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(data['preferencias_bebidas'] ?? 'N/A'),
                  const SizedBox(height: 15),
                  const Text('🎵 Música:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(data['preferencias_especiales'] ?? 'N/A'),
                  const SizedBox(height: 15),
                  const Text('📋 Bitácora Alimentos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(data['menu_especiales'] ?? 'N/A'),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  Future<void> _generarReporteMaestro() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      final todasRespuestas = await supabase
          .from('checklist_respuestas')
          .select('item_id, completado')
          .eq('viaje_id', widget.viajeId)
          .eq('fase', widget.tipoFase);
      final mapRespuestas = {
        for (var r in todasRespuestas)
          r['item_id'].toString(): r['completado'] == true
      };

      List<String> listaFaltantesAutomaticos = [];
      int totalExistentes = 0;

      for (var macro in _categoriasPorMacroArea.values) {
        for (var cat in macro) {
          final items = await supabase
              .from('checklist_items')
              .select('*')
              .eq('categoria_id', cat['id']);
          for (var item in items) {
            if (mapRespuestas[item['id'].toString()] == true) {
              totalExistentes++;
            } else {
              listaFaltantesAutomaticos
                  .add('• [${cat['nombre']}] - ${item['nombre']}');
            }
          }
        }
      }

      Navigator.pop(context);
      _mostrarPanelFirmaMaestra(totalExistentes, listaFaltantesAutomaticos);
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void _mostrarPanelFirmaMaestra(
      int totalExistentes, List<String> listaFaltantesAutomaticos) {
    // Limpiar campos de una sesión anterior
    _puntosFirma.clear();
    _responsableController.clear();
    _cosasFaltantesController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // ¡Muy importante para que no se corte!
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              // Definimos una altura fija o porcentual clara
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // CABECERA DEL MODAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("REPORTE MAESTRO", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  
                  // CONTENIDO CON SCROLL
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (listaFaltantesAutomaticos.isNotEmpty) ...[
                            Text("Pendientes (${listaFaltantesAutomaticos.length}):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                            const SizedBox(height: 5),
                            Container(
                              height: 100,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
                              child: Scrollbar(child: ListView(children: listaFaltantesAutomaticos.map((e) => Text(e, style: const TextStyle(color: Colors.black87))).toList())),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const Text("Firma de autorización:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          
                          // ÁREA DE FIRMA CORRECTA Y DELIMITADA
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                            ),
                            child: ClipRRect( // <--- LA TIJERA QUE CORTA LO QUE SE SALE
                              borderRadius: BorderRadius.circular(10),
                              child: Builder(
                                builder: (BuildContext context) {
                                  return GestureDetector(
                                    onPanStart: (details) {
                                      setModalState(() {
                                        final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                        _puntosFirma.add(renderBox.globalToLocal(details.globalPosition));
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      setModalState(() {
                                        final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                        _puntosFirma.add(renderBox.globalToLocal(details.globalPosition));
                                      });
                                    },
                                    onPanEnd: (details) => setModalState(() => _puntosFirma.add(null)),
                                    child: Container(
                                      color: Colors.transparent, // <--- DETECTA EL TOQUE EN EL FONDO BLANCO
                                      child: CustomPaint(
                                        painter: SignaturePainter(points: _puntosFirma),
                                        size: Size.infinite,
                                      ),
                                    ),
                                  );
                                }
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => setModalState(() => _puntosFirma.clear()),
                                icon: const Icon(Icons.clear, color: Colors.red),
                                label: const Text('Limpiar firma', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 10),
                          TextField(controller: _responsableController, decoration: const InputDecoration(labelText: "Nombre del Capitán", border: OutlineInputBorder())),
                          const SizedBox(height: 20),
                          TextField(controller: _cosasFaltantesController, decoration: const InputDecoration(labelText: "Comentarios u observaciones adicionales", border: OutlineInputBorder()), maxLines: 3),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // BOTÓN FIJO AL FINAL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 20)),
                      onPressed: () async {
                        if (_puntosFirma.where((p) => p != null).length < 5 ||
                            _responsableController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La firma y el nombre del capitán son obligatorios.')));
                          return;
                        }

                        showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

                        try {
                          // 1. Convertimos el trazo de la firma a texto JSON
                          final firmaJson = jsonEncode(_puntosFirma.map((p) => p == null ? null : {'dx': p.dx, 'dy': p.dy}).toList());

                          // 2. GUARDAMOS DIRECTO EN LA NUEVA TABLA (Súper rápido, sin PDFs)
                          await supabase.from('reportes_finales').insert({
                            'viaje_id': widget.viajeId,
                            'capitan_nombre': _responsableController.text.trim(),
                            'observaciones':
                                _cosasFaltantesController.text.trim(),
                            'faltantes_lista': listaFaltantesAutomaticos.join(
                                '\n'), // La lista de errores en texto
                            'firma_datos': firmaJson,
                            'fase': widget.tipoFase,
                          });

                          // 3. Actualizamos el estado del viaje
                          String nuevoEstado = '';
                          if (widget.tipoFase == 'INVENTARIO') nuevoEstado = 'POR_ZARPAR';
                          if (widget.tipoFase == 'ZARPE') nuevoEstado = 'EN_NAVEGACION';
                          if (widget.tipoFase == 'DURANTE') nuevoEstado = 'POR_CERRAR'; // <-- ¡AQUÍ ESTÁ LA MAGIA QUE FALTABA!
                          if (widget.tipoFase == 'CIERRE') nuevoEstado = 'FINALIZADO';

                          final updateData = <String, dynamic>{};
                          if (nuevoEstado.isNotEmpty) {
                            updateData['estado'] = nuevoEstado;
                          }

                          // Solo marcamos el viaje como cerrado oficialmente si es la última fase
                          if (widget.tipoFase == 'CIERRE') {
                            updateData['nombre_capitan_cierre'] = _responsableController.text.trim();
                            updateData['fecha_cierre'] = DateTime.now().toIso8601String();
                          }

                          if (updateData.isNotEmpty) {
                            await supabase.from('viajes').update(updateData).eq('id', widget.viajeId);
                          }

                          Navigator.of(context).pop(); // Cierra el loading
                          Navigator.of(context).pop(); // Cierra el modal
                          Navigator.of(context).pop(); // Cierra la pantalla de checklist

                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reporte guardado exitosamente en la base de datos!'), backgroundColor: Colors.green));
                        } catch (e) {
                          Navigator.of(context).pop(); // Cierra el loading
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar el reporte: $e'), backgroundColor: Colors.red));
                        }
                      },
                      child: const Text("FINALIZAR Y FIRMAR", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final macroAreas = _categoriasPorMacroArea.keys.toList()..sort();

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: macroAreas.isEmpty ? 1 : macroAreas.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: Text(widget.nombreViaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('LOGÍSTICA', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _mostrarLogistica,
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true, 
            labelColor: Colors.white, 
            unselectedLabelColor: Colors.white60,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            indicatorWeight: 4,
            tabs: macroAreas.isEmpty ? [const Tab(text: 'Vacío')] : macroAreas.map((m) => Tab(text: m)).toList()
          ),
        ),
        body: macroAreas.isEmpty
            ? const Center(child: Text('No hay categorías', style: TextStyle(color: Colors.grey)))
            : TabBarView(
                children: macroAreas.map((macro) {
                  final categorias = _categoriasPorMacroArea[macro]!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final cat = categorias[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5)
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          title: Text(cat['nombre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ItemsChecklistScreen(
                                      categoriaId: cat['id'].toString(),
                                      categoriaNombre: cat['nombre'],
                                      viajeId: widget.viajeId,
                                      tipoFase: widget.tipoFase))).then((_) => _cargarCategorias()), // <-- Recargamos al volver
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
        // BOTÓN SIEMPRE VISIBLE PARA EL CAPITÁN
        floatingActionButton: !widget.esCapitan 
            ? null 
            : FloatingActionButton.extended(
                onPressed: () {
                    // Quitamos la validación "todoListo" aquí para que SIEMPRE deje firmar
                    // Si quieres que avise si faltan cosas, podemos poner un if interno
                    _generarReporteMaestro();
                },
                backgroundColor: Theme.of(context).colorScheme.secondary,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('FIRMAR Y FINALIZAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter({required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null)
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}
