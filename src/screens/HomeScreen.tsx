import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Image } from 'react-native';
import { useAuth } from '../context/AuthContext';

export default function HomeScreen() {
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
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <View style={styles.userInfo}>
            {user?.photoURL ? (
              <Image source={{ uri: user.photoURL }} style={styles.avatar} />
            ) : (
              <View style={styles.avatarPlaceholder}>
                <Text style={styles.avatarText}>
                  {user?.displayName?.charAt(0).toUpperCase() || 'U'}
                </Text>
              </View>
            )}
            <View style={styles.userText}>
              <Text style={styles.greeting}>Bienvenido</Text>
              <Text style={styles.userName}>{user?.displayName || 'Inspector'}</Text>
            </View>
          </View>
          <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout}>
            <Text style={styles.logoutBtnText}>Salir</Text>
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Estado */}
        <View style={styles.statusCard}>
          <View style={styles.statusDot} />
          <Text style={styles.statusText}>✅ Acceso Aprobado</Text>
        </View>

        {/* Bienvenida */}
        <View style={styles.welcomeCard}>
          <Text style={styles.welcomeTitle}>App Inspectores Trelew</Text>
          <Text style={styles.welcomeSubtitle}>
            Sistema integral para inspectores de tránsito
          </Text>
        </View>

        {/* Funcionalidades - Etapa 1 */}
        <Text style={styles.sectionTitle}>Funcionalidades</Text>
        
        <View style={styles.featuresGrid}>
          {/* Mensajería */}
          <TouchableOpacity style={styles.featureCard}>
            <View style={[styles.featureIcon, { backgroundColor: '#e3f2fd' }]}>
              <Text style={styles.featureIconText}>💬</Text>
            </View>
            <Text style={styles.featureTitle}>Mensajería</Text>
            <Text style={styles.featureDesc}>Comunicación interna</Text>
            <View style={styles.comingSoon}>
              <Text style={styles.comingSoonText}>Próximamente</Text>
            </View>
          </TouchableOpacity>

          {/* Chat IA */}
          <TouchableOpacity style={styles.featureCard}>
            <View style={[styles.featureIcon, { backgroundColor: '#f3e5f5' }]}>
              <Text style={styles.featureIconText}>🤖</Text>
            </View>
            <Text style={styles.featureTitle}>Asistente IA</Text>
            <Text style={styles.featureDesc}>Consulta legal con IA</Text>
            <View style={styles.comingSoon}>
              <Text style={styles.comingSoonText}>Próximamente</Text>
            </View>
          </TouchableOpacity>

          {/* Geolocalización */}
          <TouchableOpacity style={styles.featureCard}>
            <View style={[styles.featureIcon, { backgroundColor: '#e8f5e9' }]}>
              <Text style={styles.featureIconText}>📍</Text>
            </View>
            <Text style={styles.featureTitle}>Ubicación</Text>
            <Text style={styles.featureDesc}>Geolocalización en tiempo real</Text>
            <View style={styles.comingSoon}>
              <Text style={styles.comingSoonText}>Próximamente</Text>
            </View>
          </TouchableOpacity>

          {/* Documentos */}
          <TouchableOpacity style={styles.featureCard}>
            <View style={[styles.featureIcon, { backgroundColor: '#fff3e0' }]}>
              <Text style={styles.featureIconText}>📄</Text>
            </View>
            <Text style={styles.featureTitle}>Documentos</Text>
            <Text style={styles.featureDesc}>Leyes y ordenanzas</Text>
            <View style={styles.comingSoon}>
              <Text style={styles.comingSoonText}>Próximamente</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* Info */}
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>ℹ️ Nota</Text>
          <Text style={styles.infoText}>
            Esta es la versión inicial de la app. Las funcionalidades adicionales se irán habilitando progresivamente.
          </Text>
        </View>

        {/* Versión */}
        <Text style={styles.version}>Versión 1.0.0</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#1a73e8',
    paddingTop: 50,
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 50,
    height: 50,
    borderRadius: 25,
    borderWidth: 2,
    borderColor: '#ffffff',
  },
  avatarPlaceholder: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#ffffff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1a73e8',
  },
  userText: {
    marginLeft: 12,
  },
  greeting: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.8)',
  },
  userName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#ffffff',
  },
  logoutBtn: {
    backgroundColor: 'rgba(255,255,255,0.2)',
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 20,
  },
  logoutBtnText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '500',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#ffffff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#4caf50',
    marginRight: 10,
  },
  statusText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#4caf50',
  },
  welcomeCard: {
    backgroundColor: '#1a73e8',
    padding: 24,
    borderRadius: 16,
    marginBottom: 24,
  },
  welcomeTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 4,
  },
  welcomeSubtitle: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1a1a1a',
    marginBottom: 16,
  },
  featuresGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  featureCard: {
    width: '48%',
    backgroundColor: '#ffffff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  featureIcon: {
    width: 50,
    height: 50,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  featureIconText: {
    fontSize: 24,
  },
  featureTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1a1a1a',
    marginBottom: 4,
  },
  featureDesc: {
    fontSize: 12,
    color: '#666666',
    marginBottom: 8,
  },
  comingSoon: {
    backgroundColor: '#e0e0e0',
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  comingSoonText: {
    fontSize: 10,
    color: '#666666',
    fontWeight: '500',
  },
  infoCard: {
    backgroundColor: '#e3f2fd',
    padding: 16,
    borderRadius: 12,
    marginBottom: 24,
  },
  infoTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1565c0',
    marginBottom: 8,
  },
  infoText: {
    fontSize: 13,
    color: '#1976d2',
    lineHeight: 20,
  },
  version: {
    textAlign: 'center',
    color: '#999999',
    fontSize: 12,
    marginBottom: 20,
  },
});
