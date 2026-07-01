import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import '../services/mensaje_service.dart';

class MensajesPage extends StatefulWidget {
  const MensajesPage({super.key});

  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MensajeService _mensajeService = MensajeService.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  StreamSubscription<QuerySnapshot>? _mensajesSubscription;
  List<QueryDocumentSnapshot> _mensajes = [];
  bool _isRecording = false;
  String? _playingAudioId;
  List<Map<String, dynamic>> _inspectores = [];
  List<String> _selectedMenciones = [];

  @override
  void initState() {
    super.initState();
    _loadInspectores();
    _subscribeToMensajes();
  }

  void _subscribeToMensajes() {
    _mensajesSubscription = _mensajeService.getMensajesStream().listen((snapshot) {
      if (mounted) {
        setState(() {
          _mensajes = snapshot.docs;
        });
      }
    });
  }

  Future<void> _loadInspectores() async {
    final inspectores = await _mensajeService.getInspectores();
    if (mounted) {
      setState(() {
        _inspectores = inspectores;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _mensajesSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canal de Inspectores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => _showInspectores(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _mensajes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = _mensajes[index];
                      final isOwn = mensaje['remitenteId'] == 
                          FirebaseAuth.instance.currentUser?.uid;
                      return _buildMensajeCard(mensaje, isOwn);
                    },
                  ),
          ),
          
          // Indicador de grabación
          if (_isRecording) _buildRecordingIndicator(),
          
          // Input de mensaje
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menciones seleccionadas
                  if (_selectedMenciones.isNotEmpty)
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _selectedMenciones.map((mencion) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Chip(
                              label: Text(mencion, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedMenciones.remove(mencion);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Row(
                    children: [
                      // Botón de audio
                      GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        child: IconButton(
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: _isRecording ? Colors.red : Colors.grey,
                          ),
                          onPressed: _isRecording ? null : _showAudioOptions,
                        ),
                      ),
                      
                      // Campo de texto
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Escribí un mensaje... (usa @ para mencionar)',
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
                          onSubmitted: (_) => _sendTextMessage(),
                          onChanged: _onTextChanged,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Botón de enviar
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendTextMessage,
                        ),
                      ),
                    ],
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
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay mensajes aún',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Sé el primero en enviar un mensaje',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red[50],
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Grabando audio... Suelta para enviar',
            style: TextStyle(color: Colors.red),
          ),
          const Spacer(),
          TextButton(
            onPressed: _cancelRecording,
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeCard(QueryDocumentSnapshot mensaje, bool isOwn) {
    final tipo = mensaje['tipo'] as String? ?? 'texto';
    final menciones = (mensaje['mencion'] as List?)?.cast<String>() ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwn)
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[400],
              child: Text(
                (mensaje['remitenteNombre'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          if (!isOwn) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOwn 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwn ? 16 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y credencial
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mensaje['remitenteNombre'] ?? 'Desconocido',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOwn ? Colors.white70 : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                          if (mensaje['remitenteCredencial']?.isNotEmpty == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isOwn 
                                    ? Colors.white24 
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${mensaje['remitenteCredencial']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOwn ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  // Contenido
                  if (tipo == 'texto') ...[
                    Text(
                      mensaje['contenido'] ?? '',
                      style: TextStyle(
                        color: isOwn ? Colors.white : Colors.black87,
                      ),
                    ),
                  ] else if (tipo == 'audio') ...[
                    _buildAudioPlayer(mensaje),
                  ],
                  
                  // Menciones
                  if (menciones.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: menciones.map<Widget>((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOwn 
                                  ? Colors.white24 
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 10,
                                color: isOwn ? Colors.white : Colors.blue[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTimestamp(mensaje['timestamp']),
                      style: TextStyle(
                        fontSize: 10,
                        color: isOwn ? Colors.white54 : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isOwn) const SizedBox(width: 8),
          if (isOwn)
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
              child: Text(
                (FirebaseAuth.instance.currentUser?.displayName ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(QueryDocumentSnapshot mensaje) {
    final audioUrl = mensaje['audioUrl'] as String?;
    final isPlaying = _playingAudioId == mensaje.id;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: isOwnMessage(mensaje) ? Colors.white : Theme.of(context).primaryColor,
          ),
          onPressed: () => _toggleAudio(mensaje.id, audioUrl),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: isOwnMessage(mensaje) 
                  ? Colors.white38 
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Icon(
          Icons.audiotrack,
          size: 16,
          color: isOwnMessage(mensaje) ? Colors.white54 : Colors.grey[500],
        ),
      ],
    );
  }

  bool isOwnMessage(QueryDocumentSnapshot mensaje) {
    return mensaje['remitenteId'] == FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _toggleAudio(String mensajeId, String? url) async {
    if (url == null) return;

    if (_playingAudioId == mensajeId) {
      await _audioPlayer.pause();
      setState(() {
        _playingAudioId = null;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      setState(() {
        _playingAudioId = mensajeId;
      });
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _playingAudioId = null;
            });
          }
        }
      });
    }
  }

  void _onTextChanged(String text) {
    if (text.contains('@')) {
      _showMentionSuggestions(text);
    }
  }

  void _showMentionSuggestions(String text) {
    final query = text.split('@').last.toLowerCase();
    
    if (query.isEmpty) return;
    
    final filtered = _inspectores.where((i) {
      final nombre = '${i['nombre']} ${i['apellido']}'.toLowerCase();
      return nombre.contains(query);
    }).toList();
    
    if (filtered.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final inspector = filtered[index];
          final nombre = '${inspector['nombre']} ${inspector['apellido']}';
          return ListTile(
            leading: CircleAvatar(
              child: Text(nombre[0].toUpperCase()),
            ),
            title: Text(nombre),
            subtitle: Text('Credencial: ${inspector['credencial']}'),
            onTap: () {
              Navigator.pop(context);
              // Insertar mención en el texto
              final cursorPos = _messageController.selection.baseOffset;
              final text = _messageController.text;
              final mentionText = '@$nombre ';
              _messageController.text = text.substring(0, cursorPos - query.length) + 
                  mentionText;
              _messageController.selection = TextSelection.collapsed(
                offset: cursorPos - query.length + mentionText.length,
              );
              
              setState(() {
                if (!_selectedMenciones.contains('@$nombre')) {
                  _selectedMenciones.add('@$nombre');
                }
              });
            },
          );
        },
      ),
    );
  }

  void _showAudioOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enviar mensaje de audio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mantén presionado el botón del micrófono\npara grabar (máx. 30 segundos)',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRecordingInstructions();
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text('Grabar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordingInstructions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mantén presionado el botón de micrófono para grabar'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _mensajeService.startRecording();
    if (hasPermission) {
      setState(() {
        _isRecording = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder al micrófono')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    final path = await _mensajeService.stopRecording();
    setState(() {
      _isRecording = false;
    });
    
    if (path != null) {
      // Subir audio
      final audioUrl = await _mensajeService.uploadAudio(path);
      if (audioUrl != null) {
        await _mensajeService.sendAudioMessage(
          audioUrl,
          mencionUsuarios: _selectedMenciones,
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _mensajeService.cancelRecording();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _mensajeService.sendTextMessage(
      text,
      mencionUsuarios: _selectedMenciones,
    );
    
    _messageController.clear();
    setState(() {
      _selectedMenciones.clear();
    });
  }

  void _showInspectores(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inspectores en línea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _inspectores.length,
                itemBuilder: (context, index) {
                  final inspector = _inspectores[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${inspector['nombre']}'.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text('${inspector['nombre']} ${inspector['apellido']}'),
                    subtitle: Text('Credencial: ${inspector['credencial']}'),
                    trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
