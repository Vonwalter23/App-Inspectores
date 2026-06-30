import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _saveTimer;
  Position? _lastPosition;
  bool _isTracking = false;

  Future<void> initialize() async {
    try {
      await _checkPermissions();
    } catch (e) {
      debugPrint('Error inicializando LocationService: $e');
    }
  }

  Future<bool> _checkPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) return false;
      return true;
    } catch (e) {
      debugPrint('Error permisos: $e');
      return false;
    }
  }

  Future<bool> startTracking() async {
    if (_isTracking) return true;
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return false;

    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _saveLocation(_lastPosition!);

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen(
        (Position position) => _lastPosition = position,
        onError: (error) => debugPrint('Error stream: $error'),
      );

      _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        if (_lastPosition != null) await _saveLocation(_lastPosition!);
      });

      _isTracking = true;
      return true;
    } catch (e) {
      debugPrint('Error startTracking: $e');
      return false;
    }
  }

  Future<void> stopTracking() async {
    _positionStreamSubscription?.cancel();
    _saveTimer?.cancel();
    if (_isTracking) await _setInactive();
    _isTracking = false;
    _lastPosition = null;
  }

  Future<void> _saveLocation(Position position) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      await firestore.collection('ubicaciones').doc(user.uid).set({
        'uid': user.uid,
        'nombre': userData?['nombre'] ?? '',
        'apellido': userData?['apellido'] ?? '',
        'latitud': position.latitude,
        'longitud': position.longitude,
        'precision': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'activo': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando ubicacion: $e');
    }
  }

  Future<void> _setInactive() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('ubicaciones').doc(user.uid).set({
        'activo': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error _setInactive: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return {
        'latitud': position.latitude,
        'longitud': position.longitude,
        'precision': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  bool get isTracking => _isTracking;
  void dispose() => stopTracking();
}
