import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemsChecklistScreen extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;
  final String viajeId;
  final String tipoFase;

  const ItemsChecklistScreen({
    super.key,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.viajeId,
    required this.tipoFase,
  });

  @override
  State<ItemsChecklistScreen> createState() => _ItemsChecklistScreenState();
}

class _ItemsChecklistScreenState extends State<ItemsChecklistScreen> {
  final supabase = Supabase.instance.client;

  Map<String, List<Map<String, dynamic>>> itemsAgrupados = {};
  bool isLoading = true;
  String? _errorMensaje;
  
  // ¡NUEVO!: Guarda localmente lo que revisas hoy para no borrar tu historial real
  Set<String> itemsRevisadosHoy = {}; 

  final Color _emeraldGreen = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    cargarItemsDeSupabase();
  }

  Future<void> cargarItemsDeSupabase() async {
    setState(() => isLoading = true);

    try {
      final itemsData = await supabase.from('checklist_items')
          .select('*, checklist_categorias(*)')
          .eq('categoria_id', widget.categoriaId)
          .order('orden');

      final respuestasData = await supabase.from('checklist_respuestas')
          .select('item_id, completado, foto_url')
          .eq('viaje_id', widget.viajeId);

      final mapRespuestas = { for (var r in respuestasData) r['item_id'].toString(): r };
      Map<String, List<Map<String, dynamic>>> mapaTemporal = {};

      for (var item in itemsData) {
        String categoriaNombre = 'Sin Categoría';
        if (item['checklist_categorias'] != null && item['checklist_categorias'] is Map) {
          categoriaNombre = item['checklist_categorias']['nombre'] ?? 'Sin Categoría';
        }

        if (!mapaTemporal.containsKey(categoriaNombre)) mapaTemporal[categoriaNombre] = [];

        final itemModificable = Map<String, dynamic>.from(item);
        final String idString = item['id'].toString();
        final respuesta = mapRespuestas[idString];
        itemModificable['checklist_respuestas'] = respuesta != null ? [respuesta] : [];

        mapaTemporal[categoriaNombre]!.add(itemModificable);
      }

      if (mounted) {
        setState(() {
          itemsAgrupados = mapaTemporal;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMensaje = e.toString(); isLoading = false; });
    }
  }

  bool _verificarTodoCompletado() {
    if (itemsAgrupados.isEmpty || isLoading) return false;
    for (var categoria in itemsAgrupados.values) {
      for (var item in categoria) {
        final String itemId = item['id'].toString();
        
        // Si estamos navegando, revisamos nuestra memoria temporal
        if (widget.tipoFase == 'DURANTE') {
          if (!itemsRevisadosHoy.contains(itemId)) return false;
        } else {
          // Si es zarpe o inventario, revisamos la base de datos oficial
          final respuestas = item['checklist_respuestas'];
          bool estaCompletado = false;
          if (respuestas != null && respuestas is List && respuestas.isNotEmpty) {
            estaCompletado = respuestas.first['completado'] == true;
          } else if (respuestas != null && respuestas is Map) {
            estaCompletado = respuestas['completado'] == true;
          }
          if (!estaCompletado) return false;
        }
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _obtenerItemsFaltantes() {
    List<Map<String, dynamic>> faltantes = [];
    for (var categoria in itemsAgrupados.values) {
      for (var item in categoria) {
        final String itemId = item['id'].toString();
        bool estaCompletado = false;

        if (widget.tipoFase == 'DURANTE') {
          estaCompletado = itemsRevisadosHoy.contains(itemId);
        } else {
          final respuestas = item['checklist_respuestas'];
          if (respuestas != null && respuestas is List && respuestas.isNotEmpty) {
            estaCompletado = respuestas.first['completado'] == true;
          } else if (respuestas != null && respuestas is Map) {
            estaCompletado = respuestas['completado'] == true;
          }
        }
        if (!estaCompletado) faltantes.add(item);
      }
    }
    return faltantes;
  }

  void _mostrarPanelFaltantes() {
    final faltantes = _obtenerItemsFaltantes();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: Text('Pendientes de Revisión', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)),
                    child: Text('${faltantes.length} pendientes', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Divider(height: 30, color: Colors.black12),
              if (faltantes.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Text('¡Excelente! Todo revisado. 🎉', style: TextStyle(fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.bold))))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true, itemCount: faltantes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle), child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 24)),
                            const SizedBox(width: 15),
                            Expanded(child: Text(faltantes[index]['nombre'] ?? '', style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // LÓGICA TRADICIONAL (Zarpe e Inventario)
  // =========================================================================
  Future<void> _toggleCheck(String categoriaNombre, int itemIndex, String itemId, bool completadoActual) async {
    setState(() {
      final item = itemsAgrupados[categoriaNombre]![itemIndex];
      if (item['checklist_respuestas'] == null || (item['checklist_respuestas'] as List).isEmpty) {
        item['checklist_respuestas'] = [{'completado': !completadoActual}];
      } else {
        item['checklist_respuestas'][0]['completado'] = !completadoActual;
      }
    });

    try {
      await supabase.from('checklist_respuestas').upsert({
        'viaje_id': widget.viajeId, 'item_id': itemId, 'completado': !completadoActual, 'fase': widget.tipoFase,
      }, onConflict: 'viaje_id,item_id');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  // =========================================================================
  // NUEVA LÓGICA "OPCIÓN C" (Bitácora Durante Navegación)
  // =========================================================================
  Future<void> _mostrarDialogoBitacora(String nombreItem, String itemId) async {
    final TextEditingController notaController = TextEditingController();
    bool esIncidencia = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Registro: $nombreItem', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: notaController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Añade una observación (opcional si todo está bien)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(color: esIncidencia ? Colors.red.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: esIncidencia ? Colors.red.shade200 : Colors.grey.shade300)),
                    child: SwitchListTile(
                      title: Text('Es Incidencia', style: TextStyle(fontWeight: FontWeight.bold, color: esIncidencia ? Colors.red : Colors.black87)),
                      value: esIncidencia, activeColor: Colors.red,
                      onChanged: (val) => setStateDialog(() => esIncidencia = val),
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: esIncidencia ? Colors.red : _emeraldGreen),
                  onPressed: () async {
                    if (notaController.text.trim().isEmpty && esIncidencia) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe la incidencia.')));
                      return;
                    }
                    String notaTexto = notaController.text.trim().isEmpty ? "Revisado y en orden." : notaController.text.trim();
                    String prefix = esIncidencia ? "🚨 INCIDENCIA:" : "✅ OK:";
                    String notaFinal = "$prefix [$nombreItem] $notaTexto";

                    Navigator.pop(context); // Cierra el diálogo
                    await _guardarEnBitacora(notaFinal, itemId);
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _guardarEnBitacora(String notaFinal, String itemId) async {
    try {
      await supabase.from('bitacora_diaria').insert({
        'viaje_id': widget.viajeId,
        'nota_operativa': notaFinal,
      });
      setState(() => itemsRevisadosHoy.add(itemId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en bitácora', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // =========================================================================

  Future<void> _tomarYSubirEvidencia(String categoriaNombre, int itemIndex, String itemId, String nombreItem) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // 1. AQUÍ ESTÁ LA MAGIA DE LA COMPRESIÓN
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 40,       // Reducimos la calidad al 40% (imperceptible en la tablet)
        maxWidth: 1080,         // Limitamos el ancho máximo a HD
        maxHeight: 1080,        // Limitamos el alto máximo
      );
      
      if (foto == null) return;

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo evidencia optimizada...')));

      final bytes = await foto.readAsBytes();
      final extension = foto.path.split('.').last;
      final nombreArchivo = '${widget.viajeId}_${itemId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // 2. SUBE LA VERSIÓN SÚPER LIGERA A SUPABASE
      await supabase.storage.from('evidencias').uploadBinary(nombreArchivo, bytes);
      final String fotoUrl = supabase.storage.from('evidencias').getPublicUrl(nombreArchivo);

      if (widget.tipoFase == 'DURANTE') {
        // Guardamos en bitácora
        await supabase.from('bitacora_diaria').insert({'viaje_id': widget.viajeId, 'nota_operativa': '[📸 FOTO] $nombreItem', 'foto_url': fotoUrl});
        setState(() => itemsRevisadosHoy.add(itemId));
      } else {
        // Guardamos tradicional
        await supabase.from('checklist_respuestas').upsert({'viaje_id': widget.viajeId, 'item_id': itemId, 'completado': true, 'foto_url': fotoUrl, 'fase': widget.tipoFase}, onConflict: 'viaje_id,item_id');
        setState(() {
          final item = itemsAgrupados[categoriaNombre]![itemIndex];
          if (item['checklist_respuestas'] == null || (item['checklist_respuestas'] as List).isEmpty) {
            item['checklist_respuestas'] = [{'completado': true, 'foto_url': fotoUrl}];
          } else {
            item['checklist_respuestas'][0]['completado'] = true;
            item['checklist_respuestas'][0]['foto_url'] = fotoUrl;
          }
        });
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Evidencia guardada!', style: TextStyle(color: Colors.green))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool todoListo = _verificarTodoCompletado();
    final bool esDurante = widget.tipoFase == 'DURANTE';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF), // Usa este mismo color en todas tus pantallas
      appBar: AppBar(
        title: Text(widget.categoriaNombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary, // <-- Esto garantiza el Azul Marino
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, 
        centerTitle: true,
        actions: [
          if (!isLoading && _errorMensaje == null)
            IconButton(icon: const Icon(Icons.assignment_late_outlined, size: 28), tooltip: 'Ver faltantes', onPressed: _mostrarPanelFaltantes),
          const SizedBox(width: 15),
        ],
      ),
      body: _construirCuerpo(esDurante),
    );
  }

  Widget _construirCuerpo(bool esDurante) {
    if (isLoading) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    if (_errorMensaje != null) return Center(child: Text('Error:\n$_errorMensaje', style: const TextStyle(color: Colors.red, fontSize: 18), textAlign: TextAlign.center));
    if (itemsAgrupados.isEmpty) return const Center(child: Text('No hay ítems.', style: TextStyle(fontSize: 18, color: Colors.blueGrey)));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: itemsAgrupados.keys.map((String categoriaNombre) {
        final List<Map<String, dynamic>> itemsDeEstaCategoria = itemsAgrupados[categoriaNombre]!;

        return Card(
          elevation: 2, margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(categoriaNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                ...itemsDeEstaCategoria.asMap().entries.map((entry) {
                  int itemIndex = entry.key;
                  Map<String, dynamic> item = entry.value;
                  final String itemId = item['id'].toString();
                  final String nombreItem = item['nombre'] ?? 'Sin nombre';

                  bool estaCompletado = false;
                  if (esDurante) {
                    estaCompletado = itemsRevisadosHoy.contains(itemId);
                  } else {
                    final respuestas = item['checklist_respuestas'];
                    if (respuestas != null && respuestas is List && respuestas.isNotEmpty) estaCompletado = respuestas.first['completado'] == true;
                    else if (respuestas != null && respuestas is Map) estaCompletado = respuestas['completado'] == true;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () {
                        if (esDurante) {
                          _mostrarDialogoBitacora(nombreItem, itemId);
                        } else {
                          _toggleCheck(categoriaNombre, itemIndex, itemId, estaCompletado);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: estaCompletado ? _emeraldGreen.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(
                              esDurante 
                                ? (estaCompletado ? Icons.check_circle : Icons.add_comment_outlined) 
                                : (estaCompletado ? Icons.check_circle : Icons.circle_outlined),
                              size: 28,
                              color: estaCompletado ? _emeraldGreen : (esDurante ? Theme.of(context).colorScheme.primary : Colors.blueGrey.shade300),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(nombreItem, style: TextStyle(fontSize: 16, fontWeight: estaCompletado ? FontWeight.bold : FontWeight.w500, color: estaCompletado ? _emeraldGreen : const Color(0xFF1E293B), decoration: (!esDurante && estaCompletado) ? TextDecoration.lineThrough : TextDecoration.none)),
                            ),
                            if (item['requiere_evidencia'] == true || esDurante)
                              IconButton(
                                icon: const Icon(Icons.camera_alt_outlined, size: 24),
                                color: estaCompletado ? _emeraldGreen : Theme.of(context).colorScheme.primary,
                                onPressed: () => _tomarYSubirEvidencia(categoriaNombre, itemIndex, itemId, nombreItem),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
