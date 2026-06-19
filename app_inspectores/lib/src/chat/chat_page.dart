import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final history = await _chatService.getChatHistory(user.uid);
    if (mounted) {
      setState(() {
        _messages = history.reversed.toList();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Legal IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consultá las normas vigentes usando lenguaje natural',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mensajes
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == 0) {
                        return _buildTypingIndicator();
                      }
                      final msgIndex = _isTyping ? index - 1 : index;
                      final message = _messages[msgIndex];
                      final isUser = message['isUser'] == true;
                      return _buildMessageBubble(message, isUser);
                    },
                  ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Escribí tu consulta legal...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.balance,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Asistente Legal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realizá consultas sobre normas de tránsito\nde Trelew y Chubut',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          // Ejemplos
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildExampleChip('¿Cuál es la velocidad máxima?'),
              _buildExampleChip('¿Dónde puedo estacionar?'),
              _buildExampleChip('Multas por alcoholemia'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Consultando... ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.balance, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message['pregunta'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    )
                  else
                    _buildAIResponse(message['respuesta'] ?? ''),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIResponse(String response) {
    // Parsear el formato de respuesta
    final lines = response.split('\n');
    List<Widget> widgets = [];

    for (final line in lines) {
      if (line.startsWith('📋')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            line,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ));
      } else if (line.startsWith('📌')) {
        widgets.add(Text(
          line,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[700],
          ),
        ));
      } else if (line.contains('No se encontró información')) {
        widgets.add(Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_off, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se encontró información en las normas cargadas.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Text(
          line,
          style: const TextStyle(color: Colors.black87),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _isTyping = true;
      _messages.insert(0, {'pregunta': text, 'respuesta': '', 'isUser': true});
    });

    _messageController.clear();

    try {
      final response = await _chatService.sendMessage(text);
      
      // Guardar en historial
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _chatService.saveChatHistory(user.uid, text, response);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTyping = false;
          if (_messages.isNotEmpty && _messages[0]['isUser'] == true) {
            _messages[0]['respuesta'] = response;
            _messages[0]['isUser'] = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTyping = false;
          if (_messages.isNotEmpty) {
            _messages[0]['respuesta'] = 'Error al procesar la consulta.';
          }
        });
      }
    }
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo usar el Asistente?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Puedes preguntar sobre:'),
            SizedBox(height: 8),
            Text('• Velocidad máxima en diferentes vías'),
            Text('• Zonas de estacionamiento'),
            Text('• Multas y sanciones'),
            Text('• Señales de tránsito'),
            Text('• Ordenanzas vigentes'),
            SizedBox(height: 16),
            Text('❌ No puedes preguntar sobre:'),
            SizedBox(height: 8),
            Text('• Información fuera de las normas cargadas'),
            Text('• Asesoramiento legal personal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
