import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View, StyleSheet, Text } from 'react-native';
import { AuthProvider, useAuth } from './src/context/AuthContext';
import LoginScreen from './src/screens/LoginScreen';
import PendingScreen from './src/screens/PendingScreen';
import HomeScreen from './src/screens/HomeScreen';

function AppContent() {
  const { user, userStatus, loading } = useAuth();

  // Mientras carga
  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#1a73e8" />
        <Text style={styles.loadingText}>Cargando...</Text>
      </View>
    );
  }

  // No hay usuario - mostrar login
  if (!user) {
    return <LoginScreen />;
  }

  // Usuario pendiente - mostrar pantalla de espera
  if (userStatus === 'pending') {
    return <PendingScreen />;
  }

  // Usuario aprobado - mostrar home
  if (userStatus === 'approved') {
    return <HomeScreen />;
  }

  // Usuario rechazado o no encontrado
  return (
    <View style={styles.errorContainer}>
      <Text style={styles.errorIcon}>⚠️</Text>
      <Text style={styles.errorTitle}>Acceso Denegado</Text>
      <Text style={styles.errorText}>
        Tu solicitud fue rechazada o no tienes permisos para acceder.
      </Text>
      <Text style={styles.errorContact}>
        Contacta a soporte@trelew.gob.ar
      </Text>
    </View>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <StatusBar style="auto" />
      <AppContent />
    </AuthProvider>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8f9fa',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666666',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#ffebee',
    paddingHorizontal: 32,
  },
  errorIcon: {
    fontSize: 60,
    marginBottom: 16,
  },
  errorTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#c62828',
    marginBottom: 12,
  },
  errorText: {
    fontSize: 16,
    color: '#666666',
    textAlign: 'center',
    marginBottom: 24,
  },
  errorContact: {
    fontSize: 14,
    color: '#999999',
  },
});
