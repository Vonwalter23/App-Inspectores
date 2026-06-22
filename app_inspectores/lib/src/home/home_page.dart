import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chat_page.dart';
import '../mensajeria/mensajes_page.dart';
import '../widgets/profile_drawer.dart';
import '../auth/login_page.dart';
import '../services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _locationEnabled = false;
  
  final List<Widget> _pages = [
    const DashboardView(),
    const ChatPage(),
    const MensajesPage(),
    const PerfilView(),
  ];

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    final enabled = await LocationService.instance.startTracking();
    if (mounted) {
      setState(() {
        _locationEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Inspectores Trelew'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Indicador de ubicación
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _locationEnabled ? Icons.location_on : Icons.location_off,
                color: _locationEnabled ? Colors.green : Colors.red,
              ),
              tooltip: _locationEnabled 
                  ? 'Ubicación activa' 
                  : 'Ubicación desactivada',
              onPressed: () => _showLocationDialog(),
            ),
          ),
          // Notificaciones
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotifications(),
          ),
        ],
      ),
      drawer: const ProfileDrawer(),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Asistente IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_locationEnabled ? 'Ubicación Activa' : 'Ubicación Inactiva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _locationEnabled ? Icons.location_on : Icons.location_off,
              size: 48,
              color: _locationEnabled ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _locationEnabled
                  ? 'Tu ubicación está siendo compartida con el centro de control.'
                  : 'Tu ubicación no está siendo compartida. Actívala para que el centro de control pueda verte.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_locationEnabled) {
                await LocationService.instance.stopTracking();
              } else {
                await LocationService.instance.startTracking();
              }
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _locationEnabled = !_locationEnabled;
                });
              }
            },
            child: Text(_locationEnabled ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay notificaciones nuevas'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'I',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Buenos días!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          user?.displayName ?? 'Inspector',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'En línea',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Accesos rápidos
          const Text(
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildQuickAction(
                context,
                icon: Icons.support_agent,
                title: 'Asistente Legal',
                subtitle: 'Consulta normas',
                color: Colors.blue,
                onTap: () {},
              ),
              _buildQuickAction(
                context,
                icon: Icons.message,
                title: 'Mensajes',
                subtitle: 'Canal interno',
                color: Colors.green,
                onTap: () {},
              ),
              _buildQuickAction(
                context,
                icon: Icons.location_on,
                title: 'Mi Ubicación',
                subtitle: 'Ver en mapa',
                color: Colors.orange,
                onTap: () => _showMyLocation(context),
              ),
              _buildQuickAction(
                context,
                icon: Icons.help,
                title: 'Ayuda',
                subtitle: 'Soporte técnico',
                color: Colors.purple,
                onTap: () => _showHelp(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Estado de conexión
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Estado de Conexión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusItem(
                        'Firebase',
                        true,
                        Icons.cloud_done,
                      ),
                      const SizedBox(width: 24),
                      _buildStatusItem(
                        'Ubicación',
                        true,
                        Icons.location_on,
                      ),
                      const SizedBox(width: 24),
                      _buildStatusItem(
                        'Drive',
                        true,
                        Icons.folder,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: status ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: status ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  void _showMyLocation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Ubicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Coordenadas actuales:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<dynamic>(
              future: LocationService.instance.getCurrentPosition(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final loc = snapshot.data as Map<String, dynamic>;
                return Text(
                  '${loc['latitud']}, ${loc['longitud']}',
                  style: const TextStyle(fontFamily: 'monospace'),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda y Soporte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para soporte técnico, contacta a:'),
            SizedBox(height: 12),
            Text('📧 soporte@trelew.gob.ar'),
            Text('📞 0800-XXX-XXXX'),
            SizedBox(height: 16),
            Text(
              'Horario de atención:\nLunes a Viernes 8:00 - 14:00',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              user?.displayName?.substring(0, 1).toUpperCase() ?? 'I',
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Inspector',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Credencial'),
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data!['credencial'] ?? 'No asignada',
                        );
                      }
                      return const Text('Cargando...');
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Fecha de Registro'),
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final timestamp = snapshot.data!['fechaRegistro'];
                        if (timestamp != null) {
                          return Text(
                            (timestamp as Timestamp)
                                .toDate()
                                .toString()
                                .split(' ')[0],
                          );
                        }
                      }
                      return const Text('-');
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _handleSignOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      await LocationService.instance.stopTracking();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
