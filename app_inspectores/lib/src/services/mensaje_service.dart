import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MensajeService {
  static final MensajeService instance = MensajeService._internal();
  factory MensajeService() => instance;
  MensajeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _currentRecordingPath;

  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );

        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        return path ?? _currentRecordingPath;
      }
      return null;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        
        // Eliminar archivo temporal
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      // Ignorar errores
    }
  }

  bool get isRecording => _isRecording;

  Future<String?> uploadAudio(String filePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('audio').child(user.uid).child('$timestamp.m4a');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'audio/mp4'),
      );

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      // Eliminar archivo local
      await file.delete();

      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendTextMessage(String contenido, {List<String>? mencionUsuarios}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Extraer menciones del texto
    final menciones = _extractMenciones(contenido);
    
    // Obtener datos del usuario
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    await _firestore.collection('mensajes').add({
      'remitenteId': user.uid,
      'remitenteNombre': '${userData?['nombre']} ${userData?['apellido']}',
      'remitenteCredencial': userData?['credencial'] ?? '',
      'contenido': contenido,
      'tipo': 'texto',
      'mencion': menciones,
      'mencionUsuarios': mencionUsuarios ?? [],
      'leidoPor': [user.uid],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendAudioMessage(String audioUrl, {List<String>? mencionUsuarios}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Obtener datos del usuario
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    await _firestore.collection('mensajes').add({
      'remitenteId': user.uid,
      'remitenteNombre': '${userData?['nombre']} ${userData?['apellido']}',
      'remitenteCredencial': userData?['credencial'] ?? '',
      'contenido': '📎 Mensaje de audio',
      'tipo': 'audio',
      'audioUrl': audioUrl,
      'mencion': [],
      'mencionUsuarios': mencionUsuarios ?? [],
      'leidoPor': [user.uid],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  List<String> _extractMenciones(String texto) {
    final regex = RegExp(r'@\S+');
    final matches = regex.allMatches(texto);
    return matches.map((m) => m.group(0)!).toList();
  }

  Stream<QuerySnapshot> getMensajesStream() {
    return _firestore
        .collection('mensajes')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> markAsRead(String mensajeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('mensajes').doc(mensajeId).update({
      'leidoPor': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<List<Map<String, dynamic>>> getInspectores() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('estado', equalTo: 'aprobado')
          .where('rol', equalTo: 'inspector')
          .get();

      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'uid': doc.id,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
