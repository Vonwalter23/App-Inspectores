import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription? _foregroundSubscription;
  StreamSubscription? _backgroundSubscription;

  Function(Map<String, dynamic>)? onMessageReceived;

  Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notificaciones autorizadas');
      }

      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      await _guardarToken(token);

      _messaging.onTokenRefresh.listen(_guardarToken);
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _guardarToken(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('fcm_tokens').doc(user.uid).set({
        'token': token,
        'userId': user.uid,
        'email': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Mensaje en foreground: ${message.notification?.title}');
    if (onMessageReceived != null) {
      onMessageReceived!(message.data);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Mensaje en background: ${message.notification?.title}');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _backgroundSubscription?.cancel();
  }
}
