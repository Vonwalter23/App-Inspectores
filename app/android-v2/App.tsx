import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View, StyleSheet } from 'react-native';
import { AuthProvider, useAuth } from './src/context/AuthContext';
import LoginScreen from './src/screens/LoginScreen';
import PendingScreen from './src/screens/PendingScreen';
import HomeScreen from './src/screens/HomeScreen';

const AppNavigator: React.FC = () => {
  const { user, userData, loading } = useAuth();

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#1a73e8" />
      </View>
    );
  }

  if (!user) {
    return <LoginScreen />;
  }

  // Verificar estado del usuario
  if (userData?.estado === 'pendiente') {
    return <PendingScreen />;
  }

  // Usuario aprobado
  if (userData?.estado === 'aprobado') {
    return <HomeScreen />;
  }

  // Por defecto, mostrar pantalla de login
  return <LoginScreen />;
};

export default function App() {
  return (
    <AuthProvider>
      <StatusBar style="light" />
      <AppNavigator />
    </AuthProvider>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#1a73e8',
  },
});
