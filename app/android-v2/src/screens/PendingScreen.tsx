import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { useAuth } from '../context/AuthContext';

const PendingScreen: React.FC = () => {
  const { user, userData, signOut } = useAuth();

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <View style={styles.iconContainer}>
          <Text style={styles.icon}>⏳</Text>
        </View>
        
        <Text style={styles.title}>Cuenta Pendiente de Aprobación</Text>
        
        <View style={styles.infoCard}>
          <Text style={styles.infoLabel}>Usuario</Text>
          <Text style={styles.infoValue}>
            {userData?.displayName || 'No disponible'}
          </Text>
        </View>

        <View style={styles.infoCard}>
          <Text style={styles.infoLabel}>Email</Text>
          <Text style={styles.infoValue}>
            {userData?.email || 'No disponible'}
          </Text>
        </View>

        <View style={styles.messageBox}>
          <Text style={styles.messageTitle}>📋 Estado de la Solicitud</Text>
          <Text style={styles.messageText}>
            Tu cuenta está pendiente de aprobación por un administrador.
            {'\n\n'}
            Recibirás acceso una vez que tu cuenta sea verificada.
            {'\n\n'}
            Por favor, espera o contacta a soporte si tienes alguna consulta.
          </Text>
        </View>

        <TouchableOpacity
          style={styles.logoutButton}
          onPress={handleSignOut}
          activeOpacity={0.8}
        >
          <Text style={styles.logoutButtonText}>Cerrar Sesión</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
    padding: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconContainer: {
    marginBottom: 20,
  },
  icon: {
    fontSize: 80,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 30,
    textAlign: 'center',
  },
  infoCard: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 10,
    width: '100%',
    marginBottom: 15,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 2,
  },
  infoLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  infoValue: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  messageBox: {
    backgroundColor: '#fff3e0',
    padding: 20,
    borderRadius: 10,
    width: '100%',
    marginTop: 10,
    marginBottom: 30,
    borderLeftWidth: 4,
    borderLeftColor: '#ff9800',
  },
  messageTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#e65100',
    marginBottom: 10,
  },
  messageText: {
    fontSize: 14,
    color: '#555',
    lineHeight: 22,
  },
  logoutButton: {
    backgroundColor: '#f44336',
    paddingHorizontal: 40,
    paddingVertical: 15,
    borderRadius: 25,
  },
  logoutButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
  },
});

export default PendingScreen;