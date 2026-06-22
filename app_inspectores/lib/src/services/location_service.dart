import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Position {
  final double latitude;
  final double longitude;
  
  Position({required this.latitude, required this.longitude});
}

class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  bool _isTracking = false;
  Timer? _uploadTimer;
  Position? _lastPosition;

  Future<void> initialize() async {}

  Future<Position?> getCurrentPosition() async {
    return _lastPosition;
  }

  void setPosition(double lat, double lng) {
    _lastPosition = Position(latitude: lat, longitude: lng);
    if (_isTracking) {
      _uploadPosition();
    }
  }

  Future<void> startTracking() async {
    _isTracking = true;
    _uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _uploadPosition();
    });
  }

  Future<void> _uploadPosition() async {
    if (_lastPosition == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('ubicaciones')
          .doc(user.uid)
          .set({
        'latitud': _lastPosition!.latitude,
        'longitud': _lastPosition!.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'email': user.email,
      });
    } catch (e) {
      // Silenciar
    }
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    _uploadTimer?.cancel();
    _uploadTimer = null;
  }

  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;
}
