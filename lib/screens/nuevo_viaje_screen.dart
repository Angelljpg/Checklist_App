import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NuevoViajeScreen extends StatefulWidget {
  const NuevoViajeScreen({super.key});

  @override
  State<NuevoViajeScreen> createState() => _NuevoViajeScreenState();
}

class _NuevoViajeScreenState extends State<NuevoViajeScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  int _pasoActual = 0; 
  bool _cargando = false;

  // SECCIÓN 1: DATOS GENERALES
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final _destinoController = TextEditingController();
  final _propietarioController = TextEditingController();
  final _pasajerosController = TextEditingController();
  final _tripulantesController = TextEditingController();
  
  TimeOfDay? _horaZarpe;
  TimeOfDay? _horaArribo;

  // SECCIÓN 2: CUADRO MAESTRO PARA MENÚS Y COMPRAS
  final _logisticaMasterController = TextEditingController();

  // =========================================================================
  // ¡NUEVO!: LISTAS DE SELECCIÓN EXCLUSIVA PARA EL YATE (BEBIDAS Y MÚSICA)
  // =========================================================================
  final List<String> _opcionesBebidas = [
    'Don Julio 70 / Maestro Dobel',
    'Mezcal Premium',
    'Whisky (Black Label / Macallan)',
    'Gin Tonic / Aperol Spritz',
    'Carajillo',
    'Champagne / Vino Blanco Frío',
    'Vino Tinto Fino',
    'Cerveza Ultra / Corona',
    'Refrescos Variados / Agua Mineral',
    'Jugos Naturales / Sueros'
  ];
  final List<String> _bebidasSeleccionadas = [];

  final List<String> _opcionesMusica = [
    'Chillout / Lounge (Yacht Club)',
    'Deep House / Electrónica Sutil',
    'Pop Hits (Actuales)',
    'Reggaetón / Urbano',
    'Rock Clásico (80s / 90s)',
    'Jazz / Bossa Nova Romántica',
    'Salsa / Cumbia Tropical',
    'Mariachi / Música Mexicana'
  ];
  final List<String> _musicaSeleccionada = [];

  Future<void> _seleccionarFechas(BuildContext context) async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context, firstDate: DateTime.now(), lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary, onPrimary: Colors.white, onSurface: Colors.black87)), child: child!),
    );
    if (rango != null) setState(() { _fechaInicio = rango.start; _fechaFin = rango.end; });
  }

  Future<void> _seleccionarHoraZarpe(BuildContext context) async {
    final TimeOfDay? hora = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (hora != null) setState(() => _horaZarpe = hora);
  }

  Future<void> _seleccionarHoraArribo(BuildContext context) async {
    final TimeOfDay? hora = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (hora != null) setState(() => _horaArribo = hora);
  }

  // REPRODUCTOR INTELIGENTE DE WHATSAPP (Para separar el resto de la comida)
  String _extraerPorPalabraClave(String textoCompleto, List<String> palabrasClaveBuscadas) {
    if (textoCompleto.trim().isEmpty) return "No especificado.";
    String textoLimpio = textoCompleto.toLowerCase();
    int indiceInicio = -1;
    String palabraEncontrada = "";

    for (String palabra in palabrasClaveBuscadas) {
      int idx = textoLimpio.indexOf(palabra);
      if (idx != -1) { indiceInicio = idx; palabraEncontrada = palabra; break; }
    }

    if (indiceInicio == -1) return "Revisar bloque general.";

    int inicioCorte = indiceInicio + palabraEncontrada.length;
    String textoRestante = textoCompleto.substring(inicioCorte);
    String textoRestanteLimpio = textoRestante.toLowerCase();

    List<String> limitesDeCorte = ['alergia', 'desayuno', 'comida', 'cena', 'snack', 'playa'];
    int indiceFin = textoRestante.length;

    for (String limite in limitesDeCorte) {
      int idx = textoRestanteLimpio.indexOf(limite);
      if (idx != -1 && idx < indiceFin) { indiceFin = idx; }
    }

    String resultadoFinal = textoRestante.substring(0, indiceFin).trim();
    return resultadoFinal.replaceAll(RegExp(r'^[:\-\s]+'), '').trim();
  }

  Future<void> _guardarViaje() async {
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta seleccionar las fechas')));
      return;
    }

    setState(() => _cargando = true);
    String bloqueLogistica = _logisticaMasterController.text;

    try {
      await supabase.from('viajes').insert({
        'nombre_viaje': 'Viaje a ${_destinoController.text.isEmpty ? "Destino" : _destinoController.text}',
        'estado': 'PLANEADO',
        'fecha_inicio': _fechaInicio!.toIso8601String(),
        'fecha_fin': _fechaFin!.toIso8601String(),
        'destino': _destinoController.text,
        'propietario_responsable': _propietarioController.text, 
        'cantidad_pasajeros': int.tryParse(_pasajerosController.text) ?? 0,
        'tripulantes': int.tryParse(_tripulantesController.text) ?? 0,
        'horario_zarpe': _horaZarpe?.format(context) ?? '',
        'horario_arribo': _horaArribo?.format(context) ?? '',
        
        // Se guardan los Chips seleccionados como listas ordenadas
        'preferencias_bebidas': _bebidasSeleccionadas.isEmpty ? 'Ninguna selección premium.' : _bebidasSeleccionadas.join(', '),
        'preferencias_especiales': _musicaSeleccionada.isEmpty ? 'Uso de sistema general.' : _musicaSeleccionada.join(', '),
        
        // Se extraen los alimentos del cuadro maestro
        'alergias': _extraerPorPalabraClave(bloqueLogistica, ['alergia', 'restriccion', 'intolerante']),
        'menu_desayunos': _extraerPorPalabraClave(bloqueLogistica, ['desayuno', 'mañana']),
        'menu_comidas': _extraerPorPalabraClave(bloqueLogistica, ['comida', 'almuerzo']),
        'menu_cenas': _extraerPorPalabraClave(bloqueLogistica, ['cena', 'noche']),
        'comidas_playa': _extraerPorPalabraClave(bloqueLogistica, ['playa', 'snack', 'botana']),
        
        'menu_especiales': bloqueLogistica, // Respaldo íntegro
        'lista_invitados': 'Registrado globalmente en sistema.',
        'edades_invitados': '', 
        'restricciones_alimenticias': 'Integrado en el bloque maestro.',
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _cargando = false);
      }
    }
  }

  Widget _crearSelectorChips(String titulo, List<String> opciones, List<String> seleccionadas, Color colorActivo) {
    return Card(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: opciones.map((opcion) {
                final bool estaSeleccionado = seleccionadas.contains(opcion);
                return FilterChip(
                  label: Text(opcion, style: TextStyle(color: estaSeleccionado ? Colors.white : Colors.black87, fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal)),
                  selected: estaSeleccionado,
                  selectedColor: colorActivo,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (bool valor) {
                    setState(() {
                      if (valor) { seleccionadas.add(opcion); } 
                      else { seleccionadas.remove(opcion); }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearInputLargo(String label, TextEditingController controller, {String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, maxLines: null, minLines: 6, keyboardType: TextInputType.multiline,
        decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: true, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(18), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.blue.shade50, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2))),
      ),
    );
  }

  Widget _crearInputCorto(String label, TextEditingController controller, {TextInputType tipo = TextInputType.text}) {
    final bool esNumero = tipo == TextInputType.number;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, keyboardType: esNumero ? TextInputType.number : TextInputType.text, inputFormatters: esNumero ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.blue.shade50, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('ALTA Y LOGÍSTICA DE VIAJE', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.horizontal, currentStep: _pasoActual,
              onStepContinue: () { if (_pasoActual < 1) setState(() => _pasoActual += 1); else _guardarViaje(); },
              onStepCancel: () { if (_pasoActual > 0) setState(() => _pasoActual -= 1); },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: _cargando ? null : details.onStepContinue, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _cargando ? const CircularProgressIndicator(color: Colors.white) : Text(_pasoActual == 1 ? 'GUARDAR Y PROGRAMAR VIAJE' : 'CONTINUAR A MENÚS', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                      if (_pasoActual > 0) ...[const SizedBox(width: 16), TextButton(onPressed: details.onStepCancel, child: Text('REGRESAR', style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold)))]
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('1. Destino y Capacidad'), isActive: _pasoActual >= 0, state: _pasoActual > 0 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      InkWell(
                        onTap: () => _seleccionarFechas(context), borderRadius: BorderRadius.circular(15),
                        child: Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100, width: 2)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_fechaInicio == null ? 'Seleccionar fechas de viaje' : 'Del ${_fechaInicio!.day}/${_fechaInicio!.month} al ${_fechaFin!.day}/${_fechaFin!.month}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _fechaInicio == null ? Colors.blueGrey : Theme.of(context).colorScheme.primary)), Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary)])),
                      ),
                      _crearInputCorto('Destino de Navegación', _destinoController), 
                      _crearInputCorto('Capitan en Navegación', _propietarioController),
                      Row(children: [
                        // ¡EL CAMBIO! Quitamos la palabra invitados
                        Expanded(child: _crearInputCorto('Tripulacion', _pasajerosController, tipo: TextInputType.number)), 
                        const SizedBox(width: 15), 
                        Expanded(child: _crearInputCorto('Personas a Bordo', _tripulantesController, tipo: TextInputType.number))
                      ]),
                      Row(children: [Expanded(child: InkWell(onTap: () => _seleccionarHoraZarpe(context), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade50, width: 2)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_horaZarpe == null ? 'Hora Zarpe' : _horaZarpe!.format(context), style: const TextStyle(fontWeight: FontWeight.w600)), Icon(Icons.wb_sunny, color: Theme.of(context).colorScheme.primary)])))), const SizedBox(width: 15), Expanded(child: InkWell(onTap: () => _seleccionarHoraArribo(context), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade50, width: 2)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_horaArribo == null ? 'Hora Arribo' : _horaArribo!.format(context), style: const TextStyle(fontWeight: FontWeight.w600)), Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary)]))))]),
                    ],
                  ),
                ),
                Step(
                  title: const Text('2. Logística y Preferencias'), isActive: _pasoActual >= 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SELECTORES AUTOMÁTICOS DE LUJO
                      _crearSelectorChips('🍸 Preferencias de Bar y Bebidas (Selecciona las requeridas)', _opcionesBebidas, _bebidasSeleccionadas, Theme.of(context).colorScheme.primary),
                      _crearSelectorChips('🎵 Ambiente Musical Deseado', _opcionesMusica, _musicaSeleccionada, Theme.of(context).colorScheme.secondary),
                      
                      const Divider(height: 30),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12), 
                        child: Text('Pega aquí el resto de la información (Alergias, Desayuno, Comida, Cena, etc.) recibida por WhatsApp:', style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontStyle: FontStyle.italic))
                      ),
                      _crearInputLargo('Copia y pega la bitácora de alimentos aquí...', _logisticaMasterController, hint: 'Ejemplo:\nAlergias: Sofia intolerante al gluten.\nDesayuno: Fruta y chilaquiles con pollo.\nComida: Tacos de camarón en la playa.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}