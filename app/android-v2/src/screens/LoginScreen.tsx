import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';
import { auth } from '../services/firebase';

const LoginScreen: React.FC = () => {
  const [loading, setLoading] = useState(false);

  const handleGoogleSignIn = async () => {
    setLoading(true);
    try {
      await GoogleSignin.hasPlayServices();
      const googleUser = await GoogleSignin.signIn();
      
      if (googleUser.idToken) {
        const credential = GoogleAuthProvider.credential(googleUser.idToken);
        await signInWithCredential(auth, credential);
        // El AuthContext se encargará de redirigir según el estado del usuario
      }
    } catch (error: any) {
      if (error.code === statusCodes.SIGN_IN_CANCELLED) {
        Alert.alert('Cancelado', 'Inicio de sesión cancelado');
      } else if (error.code === statusCodes.IN_PROGRESS) {
        Alert.alert('En progreso', 'Inicio de sesión en progreso');
      } else if (error.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
        Alert.alert('Error', 'Servicios de Google Play no disponibles');
      } else {
        console.error('Error de autenticación:', error);
        Alert.alert('Error', 'No se pudo iniciar sesión. Intenta de nuevo.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <View style={styles.logoContainer}>
          <Text style={styles.logoText}>🚔</Text>
        </View>
        <Text style={styles.title}>App Inspectores</Text>
        <Text style={styles.subtitle}>Municipalidad de Trelew</Text>
        
        <TouchableOpacity
          style={styles.googleButton}
          onPress={handleGoogleSignIn}
          disabled={loading}
          activeOpacity={0.8}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <>
              <Text style={styles.googleButtonText}>Iniciar sesión con Google</Text>
            </>
          )}
        </TouchableOpacity>

        <Text style={styles.footerText}>
          Solo personal autorizado de la Municipalidad de Trelew
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a73e8',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  logoContainer: {
    marginBottom: 20,
  },
  logoText: {
    fontSize: 80,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 18,
    color: '#e3f2fd',
    marginBottom: 50,
    textAlign: 'center',
  },
  googleButton: {
    backgroundColor: '#fff',
    paddingHorizontal: 30,
    paddingVertical: 15,
    borderRadius: 30,
    flexDirection: 'row',
    alignItems: 'center',
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  googleButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  footerText: {
    position: 'absolute',
    bottom: 40,
    color: '#e3f2fd',
    fontSize: 12,
    textAlign: 'center',
    paddingHorizontal: 40,
  },
});

export default LoginScreen;