import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator, Image } from 'react-native';
import { useAuth } from '../context/AuthContext';

export default function LoginScreen() {
  const { signIn, loading } = useAuth();

  const handleGoogleSignIn = async () => {
    try {
      await signIn();
    } catch (error) {
      console.error('Error al iniciar sesión:', error);
      alert('Error al iniciar sesión. Intenta nuevamente.');
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        {/* Logo */}
        <View style={styles.logoContainer}>
          <View style={styles.logoCircle}>
            <Text style={styles.logoIcon}>🛡️</Text>
          </View>
        </View>

        {/* Título */}
        <Text style={styles.title}>App Inspectores</Text>
        <Text style={styles.subtitle}>Municipalidad de Trelew</Text>

        {/* Descripción */}
        <Text style={styles.description}>
          Sistema integral para inspectores{'\n'}de tránsito
        </Text>

        {/* Botón de Google */}
        <TouchableOpacity
          style={styles.googleButton}
          onPress={handleGoogleSignIn}
          disabled={loading}
          activeOpacity={0.8}
        >
          {loading ? (
            <ActivityIndicator color="#4285F4" />
          ) : (
            <View style={styles.googleButtonContent}>
              <Image
                source={{ uri: 'https://developers.google.com/identity/images/g-logo.png' }}
                style={styles.googleIcon}
              />
              <Text style={styles.googleButtonText}>Iniciar sesión con Google</Text>
            </View>
          )}
        </TouchableOpacity>

        {/* Footer */}
        <Text style={styles.footer}>
          Solo personal autorizado puede acceder
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  logoContainer: {
    marginBottom: 24,
  },
  logoCircle: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: '#1a73e8',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 8,
  },
  logoIcon: {
    fontSize: 60,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1a1a1a',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666666',
    marginBottom: 32,
    textAlign: 'center',
  },
  description: {
    fontSize: 14,
    color: '#888888',
    textAlign: 'center',
    marginBottom: 48,
    lineHeight: 22,
  },
  googleButton: {
    width: '100%',
    maxWidth: 320,
    backgroundColor: '#ffffff',
    borderRadius: 8,
    paddingVertical: 14,
    paddingHorizontal: 24,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#dadce0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  googleButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  googleIcon: {
    width: 24,
    height: 24,
    marginRight: 12,
  },
  googleButtonText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#3c4043',
  },
  footer: {
    position: 'absolute',
    bottom: 40,
    fontSize: 12,
    color: '#999999',
    textAlign: 'center',
  },
});
