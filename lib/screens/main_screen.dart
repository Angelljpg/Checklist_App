import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nuevo_viaje_screen.dart';
import 'seleccion_checklist_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2440), Color(0xFF0D6480)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            _construirSidebarMenu(),
            Expanded(
              child: _construirListaViajes(esZarpe: _selectedIndex == 1),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NuevoViajeScreen()))
                    .then((_) => setState(() {}));
              },
              backgroundColor: const Color(0xFF0077B6), 
              elevation: 8,
              icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
              label: const Text('NUEVO VIAJE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            )
          : null,
    );
  }

  Widget _construirSidebarMenu() {
    return SizedBox(
      width: 260, 
      child: Column(
        children: [
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.4), 
                  blurRadius: 25, 
                  spreadRadius: 2
                )
              ],
            ),
            child: const Icon(Icons.diamond, size: 60, color: Color(0xFF00E5FF)), 
          ),
          const SizedBox(height: 15),
          const Text('DIAMOND', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 4)),
          const SizedBox(height: 5),
          
          const SizedBox(height: 40),
          Container(height: 1, width: 180, color: Colors.white24),
          const SizedBox(height: 30),

          _buildBotonMenu(
            icon: Icons.anchor,
            selectedIcon: Icons.anchor_outlined,
            label: 'Inventario',
            index: 0,
          ),
          const SizedBox(height: 15),
          _buildBotonMenu(
            icon: Icons.sailing_outlined,
            selectedIcon: Icons.sailing,
            label: 'Por Zarpar',
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonMenu({required IconData icon, required IconData selectedIcon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF00E5FF).withOpacity(0.3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                  ? Border.all(color: const Color(0xFF00E5FF).withOpacity(0.6), width: 1.5) 
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(isSelected ? selectedIcon : icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white60, size: 28),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 0.5
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirListaViajes({required bool esZarpe}) {
    final colorFondoCaja = esZarpe ? const Color(0xFFFFF6ED) : const Color(0xFFF0F8FF); 
    final colorBordeCaja = esZarpe ? const Color(0xFFFFDAB9) : const Color(0xFFBBE4FF);
    final colorIconoFondo = esZarpe ? const Color(0xFFFF8364) : const Color(0xFF0077B6); 
    final colorIcono = Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 24, 24, 24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: colorFondoCaja, shape: BoxShape.circle),
                child: Icon(esZarpe ? Icons.sailing : Icons.diamond, size: 36, color: colorIconoFondo),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esZarpe ? 'Viajes Por Zarpar' : 'Inventario del Diamond',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      esZarpe ? 'Revisión final: Juguetes acuáticos y hospitalidad' : 'Abastecimiento de despensa y revisión general',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          Expanded(
            child: FutureBuilder(
              // EL FILTRO MÁGICO: Separa los viajes según su estado actual
              future: supabase
                  .from('viajes')
                  .select()
                  .eq('estado', esZarpe ? 'POR_ZARPAR' : 'PLANEADO')
                  .order('fecha_inicio'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                final viajes = snapshot.data as List<dynamic>? ?? [];

                if (viajes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(esZarpe ? Icons.sailing_rounded : Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          esZarpe ? 'No hay viajes listos por zarpar.' : 'No hay inventarios pendientes.',
                          style: const TextStyle(fontSize: 18, color: Colors.grey)
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: viajes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final viaje = viajes[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeleccionChecklistScreen(
                              viajeId: viaje['id'].toString(),
                              nombreViaje: viaje['nombre_viaje'] ?? 'Detalles del Viaje',
                              esZarpe: esZarpe, 
                            ),
                          ),
                        ).then((_) => setState(() {})); // Se refresca la lista al volver
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorFondoCaja,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: colorBordeCaja, width: 2),
                          boxShadow: [BoxShadow(color: colorBordeCaja.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorIconoFondo,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: colorIconoFondo.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                              ),
                              child: Icon(esZarpe ? Icons.water : Icons.diamond, size: 36, color: colorIcono),
                            ),
                            const SizedBox(width: 25),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(viaje['nombre_viaje'] ?? 'Viaje', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 15,
                                    runSpacing: 5,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on, size: 18, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text('${viaje['destino']}', style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.groups, size: 18, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text('${viaje['cantidad_pasajeros']} personas', style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: colorIconoFondo),
                          ],
                        ),
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