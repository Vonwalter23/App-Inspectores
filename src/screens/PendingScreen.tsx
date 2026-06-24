import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native';
import { useAuth } from '../context/AuthContext';

export default function PendingScreen() {
  const { user, signOut } = useAuth();

  const handleLogout = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        {/* Icono de reloj */}
        <View style={styles.iconContainer}>
          <ActivityIndicator size="large" color="#f59e0b" />
        </View>

        {/* Título */}
        <Text style={styles.title}>Solicitud Pendiente</Text>
        
        {/* Mensaje */}
        <Text style={styles.message}>
          Tu solicitud de acceso está siendo revisada por un administrador.
        </Text>

        {/* Info del usuario */}
        {user && (
          <View style={styles.userInfo}>
            <Text style={styles.userEmail}>{user.email}</Text>
            <Text style={styles.userName}>{user.displayName}</Text>
          </View>
        )}

        {/* Estado */}
        <View style={styles.statusBadge}>
          <Text style={styles.statusText}>⏳ Esperando aprobación</Text>
        </View>

        {/* Instrucciones */}
        <View style={styles.instructions}>
          <Text style={styles.instructionsTitle}>¿Qué sigue?</Text>
          <Text style={styles.instructionsText}>
            1. Un administrador revisará tu solicitud{'\n'}
            2. Recibirás acceso una vez aprobado{'\n'}
            3. Podrás iniciar sesión cuando esté listo
          </Text>
        </View>

        {/* Contacto */}
        <Text style={styles.contact}>
          ¿Necesitas ayuda?{'\n'}
          Contacta a soporte@trelew.gob.ar
        </Text>

        {/* Botón de cerrar sesión */}
        <TouchableOpacity
          style={styles.logoutButton}
          onPress={handleLogout}
          activeOpacity={0.8}
        >
          <Text style={styles.logoutButtonText}>Cerrar Sesión</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8e1',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  iconContainer: {
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1a1a1a',
    marginBottom: 16,
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: '#666666',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 24,
  },
  userInfo: {
    backgroundColor: '#ffffff',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    marginBottom: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  userEmail: {
    fontSize: 14,
    color: '#666666',
    marginBottom: 4,
  },
  userName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1a1a1a',
  },
  statusBadge: {
    backgroundColor: '#fff3cd',
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 20,
    marginBottom: 32,
    borderWidth: 1,
    borderColor: '#ffc107',
  },
  statusText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#856404',
  },
  instructions: {
    backgroundColor: '#ffffff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 24,
    width: '100%',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  instructionsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1a1a1a',
    marginBottom: 12,
  },
  instructionsText: {
    fontSize: 14,
    color: '#666666',
    lineHeight: 24,
  },
  contact: {
    fontSize: 12,
    color: '#999999',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 20,
  },
  logoutButton: {
    backgroundColor: '#dc3545',
    paddingVertical: 14,
    paddingHorizontal: 40,
    borderRadius: 8,
  },
  logoutButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
  },
});
