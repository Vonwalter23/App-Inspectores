import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  StreamSubscription<QuerySnapshot>? _mensajesSubscription;
  List<QueryDocumentSnapshot> _mensajes = [];
  List<Map<String, dynamic>> _inspectores = [];
  List<String> _selectedMenciones = [];

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _cargarInspectores();
  }

  void _cargarMensajes() {
    _mensajesSubscription = _mensajeService.escucharMensajes().listen((snapshot) {
      setState(() {
        _mensajes = snapshot.docs;
      });
    });
  }

  Future<void> _cargarInspectores() async {
    final inspectores = await _mensajeService.obtenerInspectores();
    setState(() {
      _inspectores = inspectores;
    });
  }

  Future<void> _enviarMensaje() async {
    final contenido = _messageController.text.trim();
    if (contenido.isEmpty) return;

    await _mensajeService.enviarMensaje(
      contenido: contenido,
      menciones: _selectedMenciones,
    );

    _messageController.clear();
    setState(() {
      _selectedMenciones = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajería'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _mostrarSelectorMenciones,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedMenciones.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  const Text('Menciones: '),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: _selectedMenciones.map((id) {
                        final insp = _inspectores.firstWhere(
                          (i) => i['uid'] == id,
                          orElse: () => {'nombre': id},
                        );
                        return Chip(
                          label: Text('@${insp['nombre'] ?? id}'),
                          onDeleted: () {
                            setState(() {
                              _selectedMenciones.remove(id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = _mensajes[index];
                final data = mensaje.data() as Map<String, dynamic>;
                final esMio = data['remitenteId'] == FirebaseAuth.instance.currentUser?.uid;
                
                return _buildMensajeCard(data, esMio);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMensajeCard(Map<String, dynamic> data, bool esMio) {
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final fecha = ts?.toDate();

    return Card(
      margin: EdgeInsets.only(
        left: esMio ? 48 : 8,
        right: esMio ? 8 : 48,
        top: 4,
        bottom: 4,
      ),
      color: esMio 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['remitenteEmail'] ?? 'Desconocido',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (fecha != null)
                  Text(
                    _formatDate(fecha),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(data['contenido'] ?? ''),
            if (data['menciones'] != null && (data['menciones'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: (data['menciones'] as List).map<Widget>((m) {
                    return Chip(
                      label: Text('@$m', style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                  hintText: 'Escribe un mensaje...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _enviarMensaje(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _enviarMensaje,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorMenciones() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mencionar usuarios',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('@todos'),
                    trailing: _selectedMenciones.contains('todos')
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setModalState(() {
                        if (_selectedMenciones.contains('todos')) {
                          _selectedMenciones.remove('todos');
                        } else {
                          _selectedMenciones.add('todos');
                        }
                      });
                      setState(() {});
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _inspectores.length,
                      itemBuilder: (context, index) {
                        final insp = _inspectores[index];
                        final uid = insp['uid'] as String;
                        final nombre = insp['nombre'] ?? insp['email'] ?? uid;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(nombre[0].toUpperCase()),
                          ),
                          title: Text(nombre),
                          trailing: _selectedMenciones.contains(uid)
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setModalState(() {
                              if (_selectedMenciones.contains(uid)) {
                                _selectedMenciones.remove(uid);
                              } else {
                                _selectedMenciones.add(uid);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _mensajesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
