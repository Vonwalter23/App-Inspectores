import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de reloj
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hourglass_empty,
                      size: 70,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Título
                  const Text(
                    'Solicitud Pendiente',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mensaje
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tu solicitud de acceso está siendo revisada por un administrador.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Información del usuario
                        FutureBuilder<DocumentSnapshot>(
                          future: _getUserData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == 
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const Text('No se encontró información');
                            }
                            
                            final data = snapshot.data!.data() 
                                as Map<String, dynamic>;
                            
                            return Column(
                              children: [
                                _buildInfoRow(
                                  Icons.person,
                                  'Nombre',
                                  '${data['nombre']} ${data['apellido']}',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.email,
                                  'Email',
                                  data['email'] ?? '',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.badge,
                                  'Credencial',
                                  data['credencial']?.isNotEmpty == true
                                      ? data['credencial']
                                      : 'Pendiente de asignación',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.info,
                                  'Estado',
                                  _getStatusText(data['estado']),
                                  color: _getStatusColor(data['estado']),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recordatorio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Recibirás una notificación cuando\ntu solicitud sea aprobada.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de cerrar sesión
                  TextButton.icon(
                    onPressed: _isLoading ? null : _handleSignOut,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<DocumentSnapshot> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario');
    
    return await _firestore.collection('users').doc(user.uid).get();
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente de aprobación';
      case 'aprobado':
        return 'Aprobado ✓';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cerrar sesión')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
