import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemsChecklistScreen extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;
  final String viajeId;
  final bool esZarpe;

  const ItemsChecklistScreen({
    super.key,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.viajeId,
    required this.esZarpe,
  });

  @override
  State<ItemsChecklistScreen> createState() => _ItemsChecklistScreenState();
}

class _ItemsChecklistScreenState extends State<ItemsChecklistScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> _items = [];
  bool _cargando = true;
  String? _errorMensaje;

  // Colores Playeros y Premium
  final Color _oceanBlue = const Color(0xFF0077B6);
  final Color _sandWhite = const Color(0xFFF8FAFC);
  final Color _emeraldGreen = const Color(0xFF10B981); // Un verde más lujoso

  @override
  void initState() {
    super.initState();
    _cargarDatos(); 
  }

  Future<void> _cargarDatos() async {
    try {
      final itemsData = await supabase.from('checklist_items')
          .select('*')
          .eq('categoria_id', widget.categoriaId)
          .order('orden');

      final respuestasData = await supabase.from('checklist_respuestas')
          .select('item_id, completado, foto_url')
          .eq('viaje_id', widget.viajeId);

      final mapRespuestas = {
        for (var r in respuestasData) r['item_id'].toString(): r
      };

      final itemsConRespuestas = itemsData.map((item) {
        final itemModificable = Map<String, dynamic>.from(item);
        final String idString = item['id'].toString();
        final respuesta = mapRespuestas[idString];
        
        itemModificable['checklist_respuestas'] = respuesta != null ? [respuesta] : [];
        return itemModificable;
      }).toList();

      if (mounted) {
        setState(() {
          _items = itemsConRespuestas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMensaje = e.toString();
          _cargando = false;
        });
      }
    }
  }

  bool _verificarTodoCompletado() {
    if (_items.isEmpty || _cargando) return false;
    
    for (var item in _items) {
      final respuestas = item['checklist_respuestas'];
      bool estaCompletado = false;
      
      if (respuestas != null && respuestas is List && respuestas.isNotEmpty) {
        estaCompletado = respuestas.first['completado'] == true;
      } else if (respuestas != null && respuestas is Map) {
        estaCompletado = respuestas['completado'] == true;
      }
      
      if (!estaCompletado) return false;
    }
    return true;
  }

  List<dynamic> _obtenerItemsFaltantes() {
    return _items.where((item) {
      final respuestas = item['checklist_respuestas'];
      bool estaCompletado = false;
      
      if (respuestas != null && respuestas is List && respuestas.isNotEmpty) {
        estaCompletado = respuestas.first['completado'] == true;
      } else if (respuestas != null && respuestas is Map) {
        estaCompletado = respuestas['completado'] == true;
      }
      return !estaCompletado;
    }).toList();
  }

  void _mostrarPanelFaltantes() {
    final faltantes = _obtenerItemsFaltantes();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Faltantes de ${widget.categoriaNombre}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50, 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade100)
                    ),
                    child: Text(
                      '${faltantes.length} pendientes',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const Divider(height: 30, color: Colors.black12),
              if (faltantes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text('¡Excelente! Todo está completo a bordo. 🎉', style: TextStyle(fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: faltantes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                              child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                faltantes[index]['nombre'] ?? '',
                                style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _oceanBlue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleCheck(int index, String itemId, bool completadoActual) async {
    setState(() {
      if (_items[index]['checklist_respuestas'] == null || (_items[index]['checklist_respuestas'] as List).isEmpty) {
        _items[index]['checklist_respuestas'] = [{'completado': !completadoActual}];
      } else {
        _items[index]['checklist_respuestas'][0]['completado'] = !completadoActual;
      }
    });

    try {
      await supabase.from('checklist_respuestas').upsert({
        'viaje_id': widget.viajeId,
        'item_id': itemId,
        'completado': !completadoActual,
        'fase': widget.esZarpe ? 'ZARPE' : 'INVENTARIO',
      }, onConflict: 'viaje_id,item_id'); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        setState(() {
           _items[index]['checklist_respuestas'][0]['completado'] = completadoActual;
        });
      }
    }
  }

  Future<void> _tomarYSubirEvidencia(int index, String itemId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (foto == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo evidencia, por favor espera...')),
        );
      }

      final bytes = await foto.readAsBytes();
      final extension = foto.path.split('.').last;
      final nombreArchivo = '${widget.viajeId}_${itemId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await supabase.storage.from('evidencias').uploadBinary(
        nombreArchivo,
        bytes,
      );

      final String fotoUrl = supabase.storage.from('evidencias').getPublicUrl(nombreArchivo);

      await supabase.from('checklist_respuestas').upsert({
        'viaje_id': widget.viajeId,
        'item_id': itemId,
        'completado': true,
        'foto_url': fotoUrl,
        'fase': widget.esZarpe ? 'ZARPE' : 'INVENTARIO',
      }, onConflict: 'viaje_id,item_id');

      setState(() {
        if (_items[index]['checklist_respuestas'] == null || (_items[index]['checklist_respuestas'] as List).isEmpty) {
          _items[index]['checklist_respuestas'] = [{'completado': true, 'foto_url': fotoUrl}];
        } else {
          _items[index]['checklist_respuestas'][0]['completado'] = true;
          _items[index]['checklist_respuestas'][0]['foto_url'] = fotoUrl;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Evidencia guardada con éxito!', style: TextStyle(color: Colors.green))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool todoListo = _verificarTodoCompletado();

    return Scaffold(
      backgroundColor: _sandWhite,
      appBar: AppBar(
        title: Text(widget.categoriaNombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1)),
        backgroundColor: _oceanBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_cargando && _errorMensaje == null)
            IconButton(
              icon: const Icon(Icons.assignment_late_outlined, size: 28),
              tooltip: 'Ver faltantes',
              onPressed: _mostrarPanelFaltantes,
            ),
          const SizedBox(width: 15),
        ],
      ),
      body: _construirCuerpo(),
      
      bottomNavigationBar: todoListo 
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 30.0, top: 10.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); 
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                  label: const Text(
                    'ÁREA COMPLETADA',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _oceanBlue,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: _oceanBlue.withOpacity(0.4),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) {
      return Center(child: CircularProgressIndicator(color: _oceanBlue));
    }

    if (_errorMensaje != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Error de Supabase:\n$_errorMensaje', 
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No hay ítems en esta categoría.', style: TextStyle(fontSize: 18, color: Colors.blueGrey))
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(40),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _items[index];
        final String itemId = item['id'].toString();
        
        final respuestas = item['checklist_respuestas'];
        bool estaCompletado = false;
        
        if (respuestas != null && respuestas is List && respuestas.isNotEmpty) {
          estaCompletado = respuestas.first['completado'] == true;
        } else if (respuestas != null && respuestas is Map) {
          estaCompletado = respuestas['completado'] == true;
        }

        return InkWell(
          onTap: () => _toggleCheck(index, itemId, estaCompletado),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: estaCompletado ? _emeraldGreen : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: estaCompletado ? _emeraldGreen : Colors.blue.shade50, 
                width: 2
              ),
              boxShadow: [
                if (!estaCompletado) 
                  BoxShadow(color: Colors.blue.shade50, blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Row(
              children: [
                Icon(
                  estaCompletado ? Icons.check_circle : Icons.circle_outlined,
                  size: 32,
                  color: estaCompletado ? Colors.white : Colors.blueGrey.shade300,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    item['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: estaCompletado ? FontWeight.bold : FontWeight.w600,
                      color: estaCompletado ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),

                if (respuestas != null && respuestas is List && respuestas.isNotEmpty && respuestas.first['foto_url'] != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 15.0),
                    child: Icon(Icons.image_outlined, color: Colors.white, size: 28),
                  ),

                if (item['requiere_evidencia'] == true)
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, size: 30),
                    color: estaCompletado ? Colors.white : _oceanBlue,
                    onPressed: () {
                      _tomarYSubirEvidencia(index, itemId);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}