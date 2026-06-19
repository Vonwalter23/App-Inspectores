import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/firebase_firestore.dart';

class ChatService {
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;
  ChatService._internal();

  // Groq API Configuration
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqApiKey = '${GROQ_API_KEY}';
  static const String _model = 'llama-3.1-8b-instant';

  // Prompt del sistema para el asistente legal
  static const String _systemPrompt = '''Eres un asistente legal especializado en legislación de tránsito de Argentina, específicamente del municipio de Trelew, Chubut.

Tu función es RESPONDER ÚNICAMENTE basándote en la documentación legal oficial cargada en el sistema.

REGLAS IMPORTANTES:
1. SOLO responde usando información de los documentos oficiales cargados
2. NUNCA inventes, infergas o uses conocimiento general del modelo
3. Si la información NO está en los documentos, responde exactamente: "No se encontró información en las normas cargadas."
4. Cite siempre la norma y artículo correspondiente
5. Sé breve y directo en tus respuestas

FORMATO DE RESPUESTA:
Cuando encuentres información:
---
[Respuesta breve]

📋 Norma: [Nombre de la norma]
📌 Artículo: [Número de artículo]
---

Cuando NO encuentres información:
---
No se encontró información en las normas cargadas.
---
''';

  Future<String> sendMessage(String message) async {
    try {
      // Primero, buscar fragmentos relevantes en Firestore
      final relevantChunks = await _searchRelevantChunks(message);
      
      // Construir contexto con fragmentos encontrados
      String context = '';
      if (relevantChunks.isNotEmpty) {
        context = 'INFORMACIÓN DE LOS DOCUMENTOS CARGADOS:\n\n';
        for (var i = 0; i < relevantChunks.length; i++) {
          final chunk = relevantChunks[i];
          context += '--- Fragmento ${i + 1} ---\n';
          context += 'Documento: ${chunk['documento']}\n';
          context += 'Tipo: ${chunk['tipo']}\n';
          context += 'Contenido: ${chunk['texto']}\n\n';
        }
        context += '--- Fin de documentos ---\n\n';
      }

      // Construir prompt completo
      final fullPrompt = context.isEmpty 
          ? message 
          : '$context\n\nPREGUNTA DEL USUARIO: $message';

      // Llamar a Groq API
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            {
              'role': 'user',
              'content': fullPrompt,
            },
          ],
          'temperature': 0.3, // Baja temperatura para respuestas más precisas
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Error en la API de Groq');
      }
    } catch (e) {
      if (e.toString().contains('No se encontró información')) {
        return 'No se encontró información en las normas cargadas.';
      }
      return 'Error al procesar la consulta. Por favor, intenta nuevamente.\n\nDetalles: $e';
    }
  }

  Future<List<Map<String, dynamic>>> _searchRelevantChunks(String query) async {
    try {
      // Convertir query a minúsculas para búsqueda
      final queryLower = query.toLowerCase();
      
      // Extraer palabras clave
      final keywords = _extractKeywords(queryLower);
      
      // Buscar en Firestore
      final firestore = FirebaseFirestore.instance;
      
      // Obtener todos los documentos
      final docsSnapshot = await firestore
          .collection('documentos')
          .where('estado', equalTo: 'indexado')
          .get();

      List<Map<String, dynamic>> allChunks = [];
      
      for (final doc in docsSnapshot.docs) {
        final fragmentos = doc.data()['fragmentos'] as Map<String, dynamic>?;
        if (fragmentos != null) {
          for (final entry in fragmentos.entries) {
            final texto = (entry.value['texto'] as String).toLowerCase();
            // Buscar coincidencias de keywords
            int matches = 0;
            for (final keyword in keywords) {
              if (texto.contains(keyword)) {
                matches++;
              }
            }
            if (matches > 0) {
              allChunks.add({
                ...entry.value,
                'documento': doc.data()['nombre'],
                'tipo': doc.data()['tipo'],
                'numero': doc.data()['numero'],
                'matches': matches,
              });
            }
          }
        }
      }

      // Ordenar por relevancia (más coincidencias primero)
      allChunks.sort((a, b) => (b['matches'] as int).compareTo(a['matches'] as int));
      
      // Devolver top 5
      return allChunks.take(5).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  List<String> _extractKeywords(String text) {
    // Palabras a ignorar
    const stopWords = {
      'el', 'la', 'los', 'las', 'de', 'del', 'en', 'con', 'por', 'para',
      'que', 'es', 'son', 'esta', 'están', 'un', 'una', 'a', 'y', 'o',
      'como', 'cual', 'cuál', 'cuales', 'cómo', 'mi', 'me', 'se', 'le',
      'lo', 'si', 'no', 'ya', 'al', 'más', 'mas', 'pero', 'sus', 'su',
      'tiene', 'tienen', 'puede', 'pueden', 'ser', 'estar', 'cuando',
      'cual', 'cuales', 'donde', 'dónde', 'quien', 'quién', 'cuyo',
      'cuya', 'cuyos', 'cuyas', 'qué', 'cúal', 'cuál',
    };
    
    // Extraer palabras de más de 3 caracteres
    final words = text.split(RegExp(r'\s+|[.,;:!?()\[\]{}]+'))
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toSet();
    
    return words.take(10).toList();
  }

  // Guardar historial de chat en Firestore
  Future<void> saveChatHistory(String userId, String message, String response) async {
    try {
      await FirebaseFirestore.instance.collection('chat_historial').add({
        'userId': userId,
        'pregunta': message,
        'respuesta': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silenciosamente manejar error
    }
  }

  // Obtener historial de chat
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_historial')
          .where('userId', equalTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
