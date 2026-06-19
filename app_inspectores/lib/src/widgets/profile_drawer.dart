import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Drawer(
      child: Column(
        children: [
          // Header con foto y nombre
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              children: [
                // Foto de perfil
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? 'I',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Nombre
                Text(
                  user?.displayName ?? 'Inspector',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                // Email
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Info del usuario
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.badge,
                      'Credencial',
                      data['credencial']?.isNotEmpty == true
                          ? '#${data['credencial']}'
                          : 'No asignada',
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      Icons.verified,
                      'Estado',
                      _getStatusText(data['estado']),
                      color: _getStatusColor(data['estado']),
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Registro',
                      _formatDate(data['fechaRegistro']),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // Opciones del drawer
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ayuda'),
            onTap: () {
              Navigator.pop(context);
              _showHelp(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              _showAbout(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleSignOut(context);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Versión
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobado';
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    
    final DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '-';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Soporte técnico:'),
            Text('• Email: soporte@trelew.gob.ar'),
            Text('• Teléfono: 0800-XXX-XXXX'),
            SizedBox(height: 16),
            Text('🕐 Horario de atención:'),
            Text('Lunes a Viernes 8:00 - 14:00'),
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

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'App Inspectores Trelew',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.local_police,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Sistema Integral para Inspectores de Tránsito de la '
          'Municipalidad de Trelew, Chubut.',
        ),
      ],
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
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}
