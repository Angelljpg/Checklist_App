import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReporteSemanalScreen extends StatefulWidget {
  const ReporteSemanalScreen({super.key});

  @override
  State<ReporteSemanalScreen> createState() => _ReporteSemanalScreenState();
}

class _ReporteSemanalScreenState extends State<ReporteSemanalScreen> {
  final supabase = Supabase.instance.client;
  bool _cargando = false;

  // Controladores Principales
  final _capitanController = TextEditingController();
  final _periodoController = TextEditingController();

  // Controladores Diamond
  final _diaEstadoCtrl = TextEditingController(text: 'Excelente');
  final _diaLimpiezaCtrl = TextEditingController(text: 'Limpio');
  final _diaSistemasCtrl = TextEditingController(text: 'Operativos');
  final _diaObsCtrl = TextEditingController();

  // Controladores Jr y Dingui
  final _jrEstadoCtrl = TextEditingController(text: 'Excelente');
  final _jrObsCtrl = TextEditingController();
  final _dinEstadoCtrl = TextEditingController(text: 'Excelente');
  final _dinObsCtrl = TextEditingController();

  // Inventarios (Selectores)
  String _invDespensa = 'Completo';
  String _invRefri = 'Completo';
  String _invConge = 'Completo';
  String _invBar = 'Completo';

  // Textos Libres
  final _comprasCtrl = TextEditingController();
  final _mantenimientoCtrl = TextEditingController();
  final _incidenciasCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _recomendacionesCtrl = TextEditingController();

  final Color _oceanBlue = const Color(0xFF0077B6);

  Future<void> _guardarReporte() async {
    if (_capitanController.text.isEmpty || _periodoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre y Periodo son obligatorios')));
      return;
    }

    setState(() => _cargando = true);

    try {
      await supabase.from('reportes_semanales').insert({
        'capitan_nombre': _capitanController.text.trim(),
        'periodo_texto': _periodoController.text.trim(),
        
        'diamond_estado': _diaEstadoCtrl.text,
        'diamond_limpieza': _diaLimpiezaCtrl.text,
        'diamond_sistemas': _diaSistemasCtrl.text,
        'diamond_observaciones': _diaObsCtrl.text,
        
        'jr_estado': _jrEstadoCtrl.text,
        'jr_observaciones': _jrObsCtrl.text,
        
        'dingui_estado': _dinEstadoCtrl.text,
        'dingui_observaciones': _dinObsCtrl.text,
        
        'inv_despensa': _invDespensa,
        'inv_refrigerador': _invRefri,
        'inv_congelador': _invConge,
        'inv_vinos_bar': _invBar,
        
        'compras_requeridas': _comprasCtrl.text,
        'mantenimientos_requeridos': _mantenimientoCtrl.text,
        'incidencias_danos': _incidenciasCtrl.text,
        'observaciones_generales': _observacionesCtrl.text,
        'recomendaciones_capitan': _recomendacionesCtrl.text,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Reporte guardado exitosamente!'), backgroundColor: Colors.green
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String valorActual, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: valorActual,
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: ['Completo', 'Requiere reposición'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCardSeccion(String titulo, IconData icono, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: _oceanBlue, size: 28),
                const SizedBox(width: 10),
                Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _oceanBlue)),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('REPORTE SEMANAL EJECUTIVO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.orange.shade800,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCardSeccion('Datos Generales', Icons.info_outline, [
                    _buildTextField('Nombre del Capitán', _capitanController),
                    _buildTextField('Periodo (Ej. Semana del 12 al 18 de Agosto)', _periodoController),
                  ]),

                  _buildCardSeccion('Estado del Yate Diamond', Icons.diamond, [
                    _buildTextField('Estado General', _diaEstadoCtrl),
                    _buildTextField('Sistemas Operativos', _diaSistemasCtrl),
                    _buildTextField('Observaciones', _diaObsCtrl, lines: 2),
                  ]),

                  _buildCardSeccion('Embarcaciones Auxiliares', Icons.directions_boat, [
                    const Text('Diamond Jr (Axopar)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTextField('Estado y Observaciones Jr', _jrObsCtrl, lines: 2),
                    const SizedBox(height: 15),
                    const Text('Dingui (Tender)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTextField('Estado y Observaciones Dingui', _dinObsCtrl, lines: 2),
                  ]),

                  _buildCardSeccion('Inventarios a Bordo', Icons.inventory, [
                    _buildDropdown('Despensa', _invDespensa, (v) => setState(() => _invDespensa = v!)),
                    _buildDropdown('Refrigerador', _invRefri, (v) => setState(() => _invRefri = v!)),
                    _buildDropdown('Congelador', _invConge, (v) => setState(() => _invConge = v!)),
                    _buildDropdown('Vinos y Bar', _invBar, (v) => setState(() => _invBar = v!)),
                  ]),

                  _buildCardSeccion('Resumen para Dueños', Icons.assignment_late, [
                    _buildTextField('Compras Requeridas', _comprasCtrl, lines: 3),
                    _buildTextField('Mantenimientos Requeridos', _mantenimientoCtrl, lines: 3),
                    _buildTextField('Incidencias o Daños', _incidenciasCtrl, lines: 3),
                    _buildTextField('Recomendaciones del Capitán', _recomendacionesCtrl, lines: 3),
                  ]),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      icon: const Icon(Icons.cloud_upload, color: Colors.white),
                      label: const Text('GUARDAR REPORTE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      onPressed: _guardarReporte,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}