import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;
  ChatService._internal();

  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static String _groqApiKey = '';
  static const String _model = 'llama-3.1-8b-instant';

  static const String _systemPrompt = '''Eres un asistente legal especializado en legislación de tránsito de Argentina.

Responde ÚNICAMENTE usando la documentación oficial cargada.
Si no hay información en los documentos, responde exactamente: "No se encontró información en las normas cargadas."
Cite siempre la norma y artículo.''';

  Future<String> enviarPregunta(String pregunta, {String? contexto}) async {
    if (_groqApiKey.isEmpty) {
      return 'Error: API Key de Groq no configurada';
    }

    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
        if (contexto != null && contexto.isNotEmpty)
          {'role': 'user', 'content': 'Información de referencia:\n$contexto\n\nPregunta: $pregunta'},
        if (contexto == null || contexto.isEmpty)
          {'role': 'user', 'content': pregunta},
      ];

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Sin respuesta';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<List<Map<String, dynamic>>> buscarDocumentos(String query) async {
    try {
      final db = FirebaseFirestore.instance;
      final palabras = _extraerPalabrasClave(query);
      
      if (palabras.isEmpty) return [];

      final snapshot = await db.collection('documentos_fragmentos')
          .where('palabrasClave', arrayContainsAny: palabras.take(5).toList())
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<String> _extraerPalabrasClave(String texto) {
    final stopWords = {
      'el', 'la', 'los', 'las', 'de', 'del', 'en', 'con', 'por', 'para',
      'que', 'es', 'son', 'esta', 'un', 'una', 'a', 'y', 'o', 'como',
      'mi', 'me', 'se', 'le', 'lo', 'si', 'no', 'ya', 'al', 'mas',
      'tiene', 'puede', 'pueden', 'ser', 'estar', 'cuando', 'cual', 'donde'
    };
    
    return texto.toLowerCase().split(' ')
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toSet()
        .take(10)
        .toList();
  }

  Future<void> guardarHistorial(String pregunta, String respuesta) async {
    try {
      await FirebaseFirestore.instance.collection('chat_historial').add({
        'pregunta': pregunta,
        'respuesta': respuesta,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silenciar error
    }
  }

  void setApiKey(String key) {
    _groqApiKey = key;
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_historial')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChatHistory(String userId, String pregunta, String respuesta) async {
    try {
      await FirebaseFirestore.instance.collection('chat_historial').add({
        'userId': userId,
        'pregunta': pregunta,
        'respuesta': respuesta,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silenciar
    }
  }

  Future<String> sendMessage(String pregunta) async {
    // Primero buscar documentos relacionados
    final docs = await buscarDocumentos(pregunta);
    
    String contexto = '';
    if (docs.isNotEmpty) {
      contexto = docs.map((d) => d['contenido'] ?? '').join('\n\n');
    }
    
    final respuesta = await enviarPregunta(pregunta, contexto: contexto);
    await guardarHistorial(pregunta, respuesta);
    
    return respuesta;
  }
}
