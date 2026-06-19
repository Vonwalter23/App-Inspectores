import 'dart:async';
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Verificar permisos al iniciar
    await _checkPermissions();
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<bool> startTracking() async {
    if (_isTracking) return true;

    final hasPermission = await _checkPermissions();
    if (!hasPermission) return false;

    try {
      // Obtener posición inicial
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Guardar posición inicial
      await _saveLocation(_lastPosition!);

      // Iniciar stream de posiciones
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metros
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastPosition = position;
        },
        onError: (error) {
          // Manejar error silenciosamente
        },
      );

      // Timer para guardar cada 30 segundos
      _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        if (_lastPosition != null) {
          await _saveLocation(_lastPosition!);
        }
      });

      _isTracking = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopTracking() async {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    _saveTimer?.cancel();
    _saveTimer = null;

    if (_isTracking) {
      // Marcar como inactivo en Firestore
      await _setInactive();
    }

    _isTracking = false;
    _lastPosition = null;
  }

  Future<void> _saveLocation(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Obtener datos del usuario
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      await _firestore.collection('ubicaciones').doc(user.uid).set({
        'uid': user.uid,
        'nombre': userData?['nombre'] ?? '',
        'apellido': userData?['apellido'] ?? '',
        'credencial': userData?['credencial'] ?? '',
        'latitud': position.latitude,
        'longitud': position.longitude,
        'precision': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'activo': true,
      }, SetOptions(merge: true));
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  Future<void> _setInactive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('ubicaciones').doc(user.uid).set({
        'activo': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

  void dispose() {
    stopTracking();
  }
}
