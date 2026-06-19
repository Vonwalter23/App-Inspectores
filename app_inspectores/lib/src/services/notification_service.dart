import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamController<String>? _notificationController;
  Stream<String> get onNotification => _notificationController?.stream ?? const Stream.empty();

  Future<void> initialize() async {
    // Solicitar permisos
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Obtener token FCM
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Escuchar cambios de token
      _firebaseMessaging.onTokenRefresh.listen(_saveToken);

      // Configurar handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Suscribirse al topic de inspectores
      await _firebaseMessaging.subscribeToTopic('inspectores');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Mensaje en foreground: ${message.messageId}');
    
    _notificationController?.add(message.notification?.body ?? '');
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('App abierta desde notificación: ${message.messageId}');
    
    // Navegar según el tipo de mensaje
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'mensaje':
        // Navegar a mensajes
        break;
      case 'mencion':
        // Navegar a mensaje específico
        break;
      case 'sistema':
        // Mostrar detalles
        break;
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  void dispose() {
    _notificationController?.close();
    _notificationController = null;
  }
}

// Background message handler (debe ser top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}
