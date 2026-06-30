import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'src/auth/login_page.dart';
import 'src/home/home_page.dart';
import 'src/auth/pending_page.dart';
import 'src/services/notification_service.dart';
import 'src/services/location_service.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Inicializar servicios
  await NotificationService.instance.initialize();
  await LocationService.instance.initialize();
  
  runApp(const AppInspectores());
}

class AppInspectores extends StatelessWidget {
  const AppInspectores({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Inspectores Trelew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen(_checkAuthState);
  }

  Future<void> _checkAuthState(User? user) async {
    if (user != null) {
      // Verificar estado del usuario en Firestore
      await _navigateBasedOnStatus();
    }
  }

  Future<void> _navigateBasedOnStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Importar dinámicamente para evitar ciclos
    final authService = AuthService();
    final status = await authService.getUserStatus(user.uid);

    if (!mounted) return;

    if (status == 'aprobado') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (status == 'pendiente') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PendingPage()),
      );
    } else {
      // Rechazado o no existe - volver al login
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_police, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'App Inspectores Trelew',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Servicio de autenticación
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['estado'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> createUserRequest({
    required String uid,
    required String email,
    required String nombre,
    required String apellido,
    String? fotoUrl,
  }) async {
    final batch = _firestore.batch();
    
    // Crear request
    final requestRef = _firestore.collection('requests').doc(uid);
    batch.set(requestRef, {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'credencial': '',
      'estado': 'pendiente',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Crear usuario pendiente
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'credencial': '',
      'estado': 'pendiente',
      'rol': 'inspector',
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fotoUrl': fotoUrl,
    });

    await batch.commit();
  }

  Future<void> signOut() async {
    // Detener geolocalización
    await LocationService.instance.stopTracking();
    
    // Desuscribirse de FCM
    await FirebaseMessaging.instance.deleteToken();
    
    await _auth.signOut();
  }
}
