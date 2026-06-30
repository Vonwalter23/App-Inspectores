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
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }
  
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
  bool _initialized = false;
  String _statusMessage = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() => _statusMessage = 'Inicializando servicios...');
      
      // Inicializar servicios (no критично si fallan)
      try {
        await NotificationService.instance.initialize();
      } catch (e) {
        debugPrint('Error NotificationService: $e');
      }
      
      try {
        await LocationService.instance.initialize();
      } catch (e) {
        debugPrint('Error LocationService: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _initialized = true);
        _checkUserAndNavigate();
      }
    }
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      setState(() => _statusMessage = 'Verificando usuario...');
      
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        _goToLogin();
        return;
      }

      setState(() => _statusMessage = 'Verificando estado...');
      
      // Usuario existe, verificar estado en Firestore
      final authService = AuthService();
      final status = await authService.getUserStatus(user.uid);

      if (status == 'aprobado') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else if (status == 'pendiente') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PendingPage()),
        );
      } else {
        // Usuario no existe en Firestore o fue rechazado
        _goToLogin();
      }
    } catch (e) {
      debugPrint('Error verificando usuario: $e');
      // En caso de error de red o cualquier problema, ir al login
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            SizedBox(height: 10),
            Text(
              _statusMessage,
              style: TextStyle(color: Colors.grey),
            ),
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
      debugPrint('Error getUserStatus: $e');
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
    try {
      await LocationService.instance.stopTracking();
    } catch (_) {}
    
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    
    await _auth.signOut();
  }
}
