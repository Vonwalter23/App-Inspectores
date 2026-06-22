import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MensajeService {
  static final MensajeService instance = MensajeService._internal();
  factory MensajeService() => instance;
  MensajeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> enviarMensaje({
    required String contenido,
    String? tipo,
    List<String>? menciones,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mensaje = {
      'contenido': contenido,
      'tipo': tipo ?? 'texto',
      'remitenteId': user.uid,
      'remitenteEmail': user.email,
      'menciones': menciones ?? [],
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('mensajes').add(mensaje);
  }

  Stream<QuerySnapshot> escucharMensajes() {
    return _firestore
        .collection('mensajes')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> obtenerInspectores() async {
    final snapshot = await _firestore
        .collection('usuarios')
        .where('estado', isEqualTo: 'aprobado')
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return data;
    }).toList();
  }
}
