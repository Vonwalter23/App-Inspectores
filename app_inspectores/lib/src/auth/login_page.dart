import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'pending_page.dart';
import '../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '468318865609-36tsjdakr3ocmhq1s0kup1sgm9pjd97k.apps.googleusercontent.com',
  );
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo institucional
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
                      Icons.local_police,
                      size: 70,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Título
                  const Text(
                    'App Inspectores',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Municipalidad de Trelew',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // Card de login
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Usa tu cuenta de Google para acceder',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Mensaje de error
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Botón de Google
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Image.network(
                                    'https://www.gstatic.com/firebasejs/staging/cdnfirebasejs.com/0.9.22/images/google-icon.png',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.login, size: 24);
                                    },
                                  ),
                            label: Text(
                              _isLoading ? 'Iniciando sesión...' : 'Continuar con Google',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Información
                  const Text(
                    'Solo inspectores autorizados pueden acceder',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Usuario canceló
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtener credenciales
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Error al iniciar sesión');
      }

      // Verificar o crear usuario
      await _processUser(user);

    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processUser(User user) async {
    final firestore = FirebaseFirestore.instance;
    
    // Verificar si el usuario ya existe
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      // Nuevo usuario - crear solicitud
      await _createUserRequest(user);
    }
    
    // Obtener estado actual
    final status = await _getUserStatus(user.uid);
    
    if (!mounted) return;

    // Navegar según estado
    if (status == 'aprobado') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (status == 'pendiente') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PendingPage()),
      );
    } else {
      // Rechazado o sin credencial
      setState(() {
        _errorMessage = 'Tu cuenta ha sido rechazada. Contacta al administrador.';
      });
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _createUserRequest(User user) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    // Extraer nombre del email o usar el display name
    final nombre = user.displayName?.split(' ').first ?? 
                   user.email?.split('@').first ?? 'usuario';
    final apellido = user.displayName?.split(' ').skip(1).join(' ') ?? '';
    
    // Crear request
    final requestRef = firestore.collection('requests').doc(user.uid);
    batch.set(requestRef, {
      'uid': user.uid,
      'email': user.email,
      'nombre': nombre,
      'apellido': apellido,
      'credencial': '',
      'estado': 'pendiente',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Crear usuario
    final userRef = firestore.collection('users').doc(user.uid);
    batch.set(userRef, {
      'email': user.email,
      'nombre': nombre,
      'apellido': apellido,
      'credencial': '',
      'estado': 'pendiente',
      'rol': 'inspector',
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fotoUrl': user.photoURL,
    });

    await batch.commit();
  }

  Future<String?> _getUserStatus(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return doc.data()?['estado'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
