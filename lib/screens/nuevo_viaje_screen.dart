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

  // 1.1 Controladores - Datos Generales
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final _destinoController = TextEditingController();
  final _propietarioController = TextEditingController();
  final _pasajerosController = TextEditingController();
  final _tripulantesController = TextEditingController();
  
  TimeOfDay? _horaZarpe;
  TimeOfDay? _horaArribo;

  // 1.2 Controladores - Invitados (Se eliminó _edadesController)
  final _listaInvitadosController = TextEditingController();
  final _restriccionesController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _prefBebidasController = TextEditingController();
  final _prefEspecialesController = TextEditingController();

  // 1.3 Controladores - Menús
  final _desayunosController = TextEditingController();
  final _comidasController = TextEditingController();
  final _cenasController = TextEditingController();
  final _menusEspecialesController = TextEditingController();
  final _comidasPlayaController = TextEditingController();

  // Colores Playeros
  final Color _oceanBlue = const Color(0xFF0077B6);
  final Color _sandWhite = const Color(0xFFF8FAFC);

  Future<void> _seleccionarFechas(BuildContext context) async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _oceanBlue, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
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

  Future<void> _guardarViaje() async {
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta seleccionar las fechas')));
      return;
    }

    setState(() => _cargando = true);

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
        
        // Invitados
        'lista_invitados': _listaInvitadosController.text,
        'edades_invitados': '', // Lo mandamos vacío para no romper la BD
        'restricciones_alimenticias': _restriccionesController.text,
        'alergias': _alergiasController.text,
        'preferencias_bebidas': _prefBebidasController.text,
        'preferencias_especiales': _prefEspecialesController.text,
        
        // Menús
        'menu_desayunos': _desayunosController.text,
        'menu_comidas': _comidasController.text,
        'menu_cenas': _cenasController.text,
        'menu_especiales': _menusEspecialesController.text,
        'comidas_playa': _comidasPlayaController.text,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _cargando = false);
      }
    }
  }

  Widget _crearInput(String label, TextEditingController controller, {int lineas = 1, TextInputType tipo = TextInputType.text}) {
    final bool esNumero = tipo == TextInputType.number;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: esNumero ? 1 : (lineas > 1 ? null : 1),
        minLines: esNumero ? 1 : lineas,
        keyboardType: esNumero ? TextInputType.number : TextInputType.multiline,
        textInputAction: esNumero ? TextInputAction.next : TextInputAction.newline,
        inputFormatters: esNumero ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey.shade400),
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade50, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: _oceanBlue.withOpacity(0.5), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sandWhite,
      appBar: AppBar(
        title: const Text('PLANEACIÓN DEL VIAJE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: _oceanBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Theme(
          // Ajustamos los colores del Stepper
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _oceanBlue),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _pasoActual,
                elevation: 0,
                onStepContinue: () {
                  if (_pasoActual < 2) setState(() => _pasoActual += 1);
                  else _guardarViaje();
                },
                onStepCancel: () {
                  if (_pasoActual > 0) setState(() => _pasoActual -= 1);
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 35),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cargando ? null : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _oceanBlue,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 4,
                              shadowColor: _oceanBlue.withOpacity(0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _cargando 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _pasoActual == 2 ? 'GUARDAR PLAN DE VIAJE' : 'SIGUIENTE SECCIÓN', 
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                                ),
                          ),
                        ),
                        if (_pasoActual > 0) ...[
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: Text('REGRESAR', style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                  );
                },
                steps: [
                  // PASO 1: DATOS GENERALES
                  Step(
                    title: const Text('General'),
                    isActive: _pasoActual >= 0,
                    state: _pasoActual > 0 ? StepState.complete : StepState.indexed,
                    content: Column(
                      children: [
                        InkWell(
                          onTap: () => _seleccionarFechas(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade100, width: 2),
                              boxShadow: [BoxShadow(color: Colors.blue.shade50, blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fechaInicio == null ? 'Seleccionar fechas de viaje' 
                                    : 'Del ${_fechaInicio!.day}/${_fechaInicio!.month} al ${_fechaFin!.day}/${_fechaFin!.month}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _fechaInicio == null ? Colors.blueGrey : _oceanBlue),
                                ),
                                Icon(Icons.calendar_month_outlined, color: _oceanBlue, size: 28),
                              ],
                            ),
                          ),
                        ),
                        _crearInput('Destino(s)', _destinoController),
                        _crearInput('Propietario Responsable', _propietarioController),
                        Row(
                          children: [
                            Expanded(child: _crearInput('N° Invitados', _pasajerosController, tipo: TextInputType.number)),
                            const SizedBox(width: 15),
                            Expanded(child: _crearInput('N° Tripulantes', _tripulantesController, tipo: TextInputType.number)),
                          ],
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarHoraZarpe(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue.shade50, width: 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _horaZarpe == null ? 'Hora Zarpe' : _horaZarpe!.format(context),
                                          style: TextStyle(fontSize: 16, color: _horaZarpe == null ? Colors.blueGrey.shade400 : Colors.black87, fontWeight: FontWeight.w600),
                                        ),
                                        Icon(Icons.wb_sunny_outlined, color: _oceanBlue),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarHoraArribo(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue.shade50, width: 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _horaArribo == null ? 'Hora Arribo' : _horaArribo!.format(context),
                                          style: TextStyle(fontSize: 16, color: _horaArribo == null ? Colors.blueGrey.shade400 : Colors.black87, fontWeight: FontWeight.w600),
                                        ),
                                        Icon(Icons.nights_stay_outlined, color: _oceanBlue),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PASO 2: INVITADOS (Diseño limpio, preferencias más pequeñas)
                  Step(
                    title: const Text('Invitados'),
                    isActive: _pasoActual >= 1,
                    state: _pasoActual > 1 ? StepState.complete : StepState.indexed,
                    content: Column(
                      children: [
                        _crearInput('Nombres de los invitados', _listaInvitadosController, lineas: 2),
                        // Removidas las edades de la vista
                        _crearInput('Restricciones alimenticias', _restriccionesController, lineas: 1),
                        _crearInput('Alergias', _alergiasController, lineas: 1),
                        _crearInput('Preferencias de bebidas', _prefBebidasController, lineas: 1),
                        _crearInput('Otras preferencias (música, etc.)', _prefEspecialesController, lineas: 1),
                      ],
                    ),
                  ),

                  // PASO 3: MENÚS
                  Step(
                    title: const Text('Menús'),
                    isActive: _pasoActual >= 2,
                    content: Column(
                      children: [
                        _crearInput('Desayunos propuestos', _desayunosController, lineas: 2),
                        _crearInput('Comidas propuestas', _comidasController, lineas: 2),
                        _crearInput('Cenas propuestas', _cenasController, lineas: 2),
                        _crearInput('Menús infantiles o especiales', _menusEspecialesController, lineas: 1),
                        _crearInput('Comidas en playa / Snacks', _comidasPlayaController, lineas: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),                                                                                                                                                                                                                  
      ),
    );
  }
}