import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  StreamController<String>? _notificationController;
  Stream<String> get onNotification => _notificationController?.stream ?? const Stream.empty();

  Future<void> initialize() async {
    try {
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
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null) {
            await _saveToken(token);
          }
        } catch (e) {
          debugPrint('Error obteniendo token FCM: $e');
        }

        // Escuchar cambios de token
        _firebaseMessaging.onTokenRefresh.listen((token) async {
          try {
            await _saveToken(token);
          } catch (_) {}
        });

        // Configurar handlers
        FirebaseMessaging.onMessage.listen((message) async {
          _notificationController?.add(message.notification?.body ?? '');
        });
        
        FirebaseMessaging.onMessageOpenedApp.listen((message) async {
          // Handle message opened
        });
      }
    } catch (e) {
      debugPrint('Error inicializando NotificationService: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribe: $e');
    }
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
