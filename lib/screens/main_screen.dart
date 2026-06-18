import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'nuevo_viaje_screen.dart';
import 'seleccion_checklist_screen.dart';
import 'reporte_semanal_screen.dart';
import 'resumen_viaje_finalizado_screen.dart';
import 'login_selector_screen.dart';
import 'ver_reporte_screen.dart'; // <-- IMPORTAMOS LA NUEVA PANTALLA

class MainScreen extends StatefulWidget {
  final bool esCapitan;
  const MainScreen({super.key, required this.esCapitan});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;
  RealtimeChannel? _viajesSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.esCapitan ? 0 : 2; 
    _configurarNotificacionesReales();
  }

  void _configurarNotificacionesReales() {
    _viajesSubscription = supabase.channel('public:viajes').onPostgresChanges(
          event: PostgresChangeEvent.insert, schema: 'public', table: 'viajes',
          callback: (payload) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Nuevo viaje programado en el sistema!'), 
                  backgroundColor: Colors.orange, 
                  duration: Duration(seconds: 5)
                )
              );
              setState(() {});
            }
          },
        ).subscribe();
  }

  @override
  void dispose() {
    if (_viajesSubscription != null) supabase.removeChannel(_viajesSubscription!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A2440), Color(0xFF0D6480)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Row(
          children: [
            _construirSidebarMenu(),
            Expanded(child: _construirListaViajes(
              tipoFase: _selectedIndex == 0 ? 'INVENTARIO' : _selectedIndex == 1 ? 'ZARPE' : _selectedIndex == 2 ? 'DURANTE' : _selectedIndex == 3 ? 'CIERRE' : _selectedIndex == 4 ? 'HISTORIAL' : 'DOCUMENTOS'
            )),
          ],
        ),
      ),
      floatingActionButton: ((widget.esCapitan && _selectedIndex == 0) || (!widget.esCapitan && _selectedIndex == 2)) 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NuevoViajeScreen())).then((_) => setState(() {}));
              },
              backgroundColor: Theme.of(context).colorScheme.primary, elevation: 8,
              icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
              label: const Text('REGISTRAR VIAJE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            )
          : null,
    );
  }

  Widget _construirSidebarMenu() {
    return SizedBox(
      width: 270,
      height: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 20, spreadRadius: 1)]),
            child: const Icon(Icons.diamond, size: 45, color: Color(0xFF00E5FF)),
          ),
          const SizedBox(height: 8),
          const Text('DIAMOND', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4)),
          const SizedBox(height: 15),
          Container(height: 1, width: 180, color: Colors.white24),
          const SizedBox(height: 15),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.esCapitan ? Icons.gavel : Icons.engineering, color: widget.esCapitan ? const Color(0xFF00E5FF) : Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(widget.esCapitan ? 'CAPITÁN' : 'PROPIETARIO', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (widget.esCapitan) ...[
                  _buildBotonMenu(icon: Icons.anchor, selectedIcon: Icons.anchor_outlined, label: 'Inventario / Alta', index: 0),
                  const SizedBox(height: 8),
                  _buildBotonMenu(icon: Icons.sailing_outlined, selectedIcon: Icons.sailing, label: 'Por Zarpar', index: 1),
                  const SizedBox(height: 8),
                ],
                _buildBotonMenu(icon: Icons.directions_boat_outlined, selectedIcon: Icons.directions_boat, label: 'Revisión en Viaje', index: 2),
                const SizedBox(height: 8),
                _buildBotonMenu(icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, label: 'Reportes Firmados', index: 5),
                const SizedBox(height: 8),
                if (widget.esCapitan) ...[
                  _buildBotonMenu(icon: Icons.task_alt, selectedIcon: Icons.done_all, label: 'Cierre de Viaje', index: 3),
                  const SizedBox(height: 8),
                  _buildBotonMenu(icon: Icons.history, selectedIcon: Icons.history_toggle_off, label: 'Historial', index: 4),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReporteSemanalScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.6), width: 1.5)), child: Row(children: const [Icon(Icons.assignment_turned_in, color: Colors.orange, size: 24), SizedBox(width: 15), Expanded(child: Text('Reporte Semanal', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)))])),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginSelectorScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.5))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('SALIR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonMenu({required IconData icon, required IconData selectedIcon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Material(color: Colors.transparent, child: InkWell(onTap: () => setState(() => _selectedIndex = index), borderRadius: BorderRadius.circular(16), child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), decoration: BoxDecoration(color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.6) : Colors.transparent, width: 1.5)), child: Row(children: [Icon(isSelected ? selectedIcon : icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white60, size: 24), const SizedBox(width: 15), Expanded(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)))])))));
  }

  Widget _construirListaViajes({required String tipoFase}) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    
    return Container(
      margin: const EdgeInsets.all(20), 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18), 
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle), 
                child: Icon(tipoFase == 'DOCUMENTOS' ? Icons.assignment_turned_in : Icons.directions_boat, size: 32, color: Colors.white)
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(
                      tipoFase == 'DOCUMENTOS' ? 'Reportes Firmados' : 'Viajes: ${tipoFase.toUpperCase()}', 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primary, letterSpacing: 1)
                    ), 
                    const SizedBox(height: 4), 
                    Text('Gestión operativa de la flota Diamond', style: TextStyle(fontSize: 14, color: Colors.grey.shade600))
                  ]
                )
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: FutureBuilder(
              future: tipoFase == 'DOCUMENTOS' 
                  ? supabase.from('viajes').select().order('fecha_inicio', ascending: false)
                  : supabase.from('viajes').select().eq('estado', tipoFase == 'ZARPE' ? 'POR_ZARPAR' : tipoFase == 'DURANTE' ? 'EN_NAVEGACION' : tipoFase == 'CIERRE' ? 'POR_CERRAR' : tipoFase == 'HISTORIAL' ? 'FINALIZADO' : 'PLANEADO').order('fecha_inicio'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primary));
                }
                
                final viajesBrutos = snapshot.data as List<dynamic>? ?? [];
                final viajes = tipoFase == 'DOCUMENTOS'
                    ? viajesBrutos.where((v) => 
                        v['estado'] == 'POR_ZARPAR' || 
                        v['estado'] == 'EN_NAVEGACION' || 
                        v['estado'] == 'POR_CERRAR' || 
                        v['estado'] == 'FINALIZADO'
                      ).toList()
                    : viajesBrutos;

                if (viajes.isEmpty) {
                  return Center(child: Text('Sin registros activos', style: TextStyle(color: Colors.grey.shade400)));
                }

                return ListView.separated(
                  itemCount: viajes.length, 
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final viaje = viajes[index];
                    return InkWell(
                      onTap: () {
                        if (tipoFase == 'DOCUMENTOS') {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VerReporteScreen(viajeId: viaje['id'].toString())));
                        } else if (tipoFase == 'HISTORIAL') {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ResumenViajeFinalizadoScreen(viajeId: viaje['id'].toString(), nombreViaje: viaje['nombre_viaje'] ?? 'Viaje Concluido')));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SeleccionChecklistScreen(viajeId: viaje['id'].toString(), nombreViaje: viaje['nombre_viaje'] ?? 'Viaje', tipoFase: tipoFase, esCapitan: widget.esCapitan))).then((_) => setState(() {}));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: primary.withOpacity(0.3), width: 1.5)
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12), 
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1), 
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primary.withOpacity(0.3))
                              ), 
                              child: Icon(Icons.sailing, color: primary)
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  Text(viaje['nombre_viaje'] ?? 'Viaje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
                                  Text('Destino: ${viaje['destino']}', style: TextStyle(color: Colors.grey.shade600))
                                ]
                              )
                            ),
                            Icon(Icons.chevron_right, color: secondary, size: 30)
                          ]
                        )
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}