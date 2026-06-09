import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'items_checklist_screen.dart';
import 'pdf_services.dart';

class SeleccionChecklistScreen extends StatefulWidget {
  final String viajeId;
  final String nombreViaje;
  final bool esZarpe;

  const SeleccionChecklistScreen({
    super.key,
    required this.viajeId,
    required this.nombreViaje,
    required this.esZarpe,
  });

  @override
  State<SeleccionChecklistScreen> createState() => _SeleccionChecklistScreenState();
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
      final data = await supabase
          .from('checklist_categorias')
          .select('*')
          .order('macro_area')
          .order('nombre');

      final Map<String, List<Map<String, dynamic>>> agrupado = {};
      for (var row in data) {
        final macro = row['macro_area'] ?? 'OTROS';

        if (widget.esZarpe && macro != 'ANTES DE PARTIR') continue;
        if (!widget.esZarpe && macro == 'ANTES DE PARTIR') continue;

        if (!agrupado.containsKey(macro)) agrupado[macro] = [];
        agrupado[macro]!.add(row);
      }

      if (mounted) {
        setState(() {
          _categoriasPorMacroArea = agrupado;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar categorías: $e')));
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _generarReporteMaestro() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2) Fase actual (se guarda por ItemsChecklistScreen al marcar)
      final String faseActual = widget.esZarpe ? 'ZARPE' : 'INVENTARIO';

      // 3) Traemos solo las respuestas de este viaje y de la fase actual
      final todasRespuestas = await supabase
          .from('checklist_respuestas')
          .select('item_id, completado')
          .eq('viaje_id', widget.viajeId)
          .eq('fase', faseActual);

      final mapRespuestas = { for (var r in todasRespuestas) r['item_id'].toString(): r['completado'] == true };

      List<String> listaFaltantesAutomaticos = [];
      int totalExistentes = 0;

      // 4) Iteramos solo por las categorías visibles y sus ítems
      for (var macro in _categoriasPorMacroArea.values) {
        for (var cat in macro) {
          final items = await supabase.from('checklist_items').select('*').eq('categoria_id', cat['id']);
          for (var item in items) {
            final itemId = item['id'].toString();
            if (mapRespuestas[itemId] == true) {
              totalExistentes++;
            } else {
              listaFaltantesAutomaticos.add('• [${cat['nombre']}] - ${item['nombre']}');
            }
          }
        }
      }

      Navigator.pop(context);
      _mostrarPanelFirmaMaestra(totalExistentes, listaFaltantesAutomaticos);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _mostrarPanelFirmaMaestra(int totalExistentes, List<String> listaFaltantesAutomaticos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 25,
                left: 30,
                right: 30,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.esZarpe ? 'AUTORIZACIÓN DE ZARPE' : 'REPORTE MAESTRO DE CIERRE',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0C2E6C)),
                                ),
                                Text('Viaje: ${widget.nombreViaje}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified, color: Colors.green, size: 28),
                                  const SizedBox(height: 6),
                                  Text('ITEMS OK: $totalExistentes', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.assignment_late, color: Colors.red, size: 28),
                                  const SizedBox(height: 6),
                                  Text('FALTAN: ${listaFaltantesAutomaticos.length}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      if (!widget.esZarpe) ...[
                        const Text('Lista de cosas que faltan (Abastecimiento):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE65100))),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cosasFaltantesController,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Anota aquí todo lo que haga falta comprar para el viaje...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.orange.shade50,
                            prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.shopping_cart, color: Color(0xFFE65100))),
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),
                      const Text('VALIDACIÓN DE FIRMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0C2E6C))),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _responsableController,
                        decoration: InputDecoration(
                          labelText: widget.esZarpe ? 'Nombre del Capitán (Autoriza Zarpe)' : 'Nombre de quien Entrega/Revisa',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.person_pin_rounded),
                        ),
                      ),

                      const SizedBox(height: 15),
                      const Text('Firma Digital Autógrafa:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Listener(
                            onPointerDown: (event) => setModalState(() => _puntosFirma.add(event.localPosition)),
                            onPointerMove: (event) => setModalState(() => _puntosFirma.add(event.localPosition)),
                            onPointerUp: (event) => setModalState(() => _puntosFirma.add(null)),
                            child: GestureDetector(
                              onVerticalDragUpdate: (_) {},
                              onHorizontalDragUpdate: (_) {},
                              behavior: HitTestBehavior.opaque,
                              child: CustomPaint(painter: SignaturePainter(points: _puntosFirma), size: Size.infinite),
                            ),
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => setModalState(() => _puntosFirma.clear()),
                            icon: const Icon(Icons.clear, color: Colors.red),
                            label: const Text('Limpiar Lienzo', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.esZarpe ? Colors.blue.shade900 : const Color(0xFF0C2E6C),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (_responsableController.text.trim().isEmpty || _puntosFirma.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre y la firma son obligatorios.')));
                              return;
                            }

                            try {
                              final puntosJson = jsonEncode(_puntosFirma.map((p) => p == null ? null : {'dx': p.dx, 'dy': p.dy}).toList());

                              String reporteTxt = "TOTAL ÍTEMS VERIFICADOS EN BUEN ESTADO: $totalExistentes\n\nFALTANTES DETECTADOS:\n";
                              reporteTxt += listaFaltantesAutomaticos.isNotEmpty ? listaFaltantesAutomaticos.join('\n') : '• Todo verificado correctamente.';

                              if (!widget.esZarpe && _cosasFaltantesController.text.trim().isNotEmpty) {
                                reporteTxt += "\n\n========================================\nCOSAS QUE FALTAN (Anotadas manualmente):\n========================================\n";
                                reporteTxt += _cosasFaltantesController.text.trim();
                              }

                              // 1. ACTUALIZA SUPABASE Y AVANZA EL PIPELINE
                              if (widget.esZarpe) {
                                await supabase.from('viajes').update({
                                  'estado': 'EN VIAJE', 
                                  'nombre_capitan_cierre': _responsableController.text.trim(),
                                }).eq('id', widget.viajeId);
                              } else {
                                await supabase.from('viajes').update({
                                  'estado': 'POR_ZARPAR', // <--- CAMBIA DE PESTAÑA AUTOMÁTICAMENTE
                                  'nombre_capitan_cierre': _responsableController.text.trim(),
                                  'firma_cierre_puntos': puntosJson,
                                  'reporte_entregable': reporteTxt,
                                  'fecha_cierre': DateTime.now().toIso8601String(),
                                }).eq('id', widget.viajeId);
                              }

                              // 2. GENERA EL PDF EN AMBOS CASOS (Se activa el Popup de Compartir nativo)
                              if (mounted) {
                                String sufijo = widget.esZarpe ? "ZARPE" : "INVENTARIO";
                                await generarReportePDF(
                                  context,
                                  "${widget.nombreViaje} - $sufijo",
                                  totalExistentes,
                                  listaFaltantesAutomaticos, // Ahora sí se envían bien al PDF
                                  puntosJson,
                                );
                              }

                              // 3. CIERRA PANTALLAS UNA SOLA VEZ
                              if (mounted) {
                                Navigator.pop(context); // Cierra el Modal
                                Navigator.pop(context); // Cierra la pantalla de la lista
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.esZarpe ? '¡ZARPE AUTORIZADO! Viaje en curso.' : '¡INVENTARIO CERRADO! Listo para Zarpar.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar: $e')));
                              }
                            }
                          },
                          child: Text(
                            widget.esZarpe ? 'FIRMAR Y AUTORIZAR ZARPE' : 'SELLAR YATE Y FINALIZAR REPORTE',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _puntosFirma.clear());
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final macroAreas = _categoriasPorMacroArea.keys.toList()..sort();

    return DefaultTabController(
      length: macroAreas.isEmpty ? 1 : macroAreas.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        appBar: AppBar(
          title: Text(widget.nombreViaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: widget.esZarpe ? Colors.blue.shade900 : const Color(0xFF0C2E6C),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.amber,
            indicatorWeight: 4,
            tabs: macroAreas.isEmpty ? [const Tab(text: 'Vacío')] : macroAreas.map((m) => Tab(text: m)).toList(),
          ),
        ),
        body: macroAreas.isEmpty
            ? const Center(child: Text('No hay categorías en esta sección', style: TextStyle(fontSize: 18, color: Colors.grey)))
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          title: Text(cat['nombre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.arrow_forward_ios, color: widget.esZarpe ? Colors.blue.shade900 : const Color(0xFF0C2E6C)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemsChecklistScreen(
                                  categoriaId: cat['id'].toString(),
                                  categoriaNombre: cat['nombre'],
                                  viajeId: widget.viajeId,
                                  esZarpe: widget.esZarpe,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: macroAreas.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: _generarReporteMaestro,
                backgroundColor: widget.esZarpe ? Colors.blue.shade900 : Colors.green.shade700,
                icon: Icon(widget.esZarpe ? Icons.sailing : Icons.verified_user, color: Colors.white),
                label: Text(
                  widget.esZarpe ? 'AUTORIZAR ZARPE' : 'CERRAR Y FIRMAR YATE',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}