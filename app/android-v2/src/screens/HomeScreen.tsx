import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import { useAuth } from '../context/AuthContext';

const HomeScreen: React.FC = () => {
  const { user, userData, signOut } = useAuth();

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
    }
  };

  const menuItems = [
    {
      id: 'chat',
      icon: '💬',
      title: 'Chat IA',
      description: 'Asistente inteligente',
      color: '#4CAF50',
    },
    {
      id: 'mensajeria',
      icon: '📨',
      title: 'Mensajería',
      description: 'Comunicación con colegas',
      color: '#2196F3',
    },
    {
      id: 'ubicacion',
      icon: '📍',
      title: 'Mi Ubicación',
      description: 'Ver mi ubicación actual',
      color: '#FF9800',
    },
    {
      id: 'reportes',
      icon: '📊',
      title: 'Reportes',
      description: 'Ver mis reportes',
      color: '#9C27B0',
    },
  ];

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <Text style={styles.greeting}>
            ¡Hola, {userData?.displayName?.split(' ')[0] || 'Inspector'}!
          </Text>
          <Text style={styles.subGreeting}>
            Bienvenido al sistema de inspectores
          </Text>
        </View>
        <TouchableOpacity style={styles.profileButton} onPress={handleSignOut}>
          <Text style={styles.profileButtonText}>🚪</Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.statusCard}>
          <View style={styles.statusDot} />
          <Text style={styles.statusText}>
            Estado: {userData?.estado === 'aprobado' ? 'Activo' : 'Pendiente'}
          </Text>
        </View>

        <Text style={styles.sectionTitle}>Menú Principal</Text>
        
        <View style={styles.menuGrid}>
          {menuItems.map((item) => (
            <TouchableOpacity
              key={item.id}
              style={[styles.menuCard, { borderLeftColor: item.color }]}
              activeOpacity={0.7}
              onPress={() => Alert.alert(item.title, `${item.description} - En desarrollo`)}
            >
              <Text style={styles.menuIcon}>{item.icon}</Text>
              <Text style={styles.menuTitle}>{item.title}</Text>
              <Text style={styles.menuDescription}>{item.description}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.quickActions}>
          <Text style={styles.sectionTitle}>Acciones Rápidas</Text>
          <TouchableOpacity style={styles.actionButton}>
            <Text style={styles.actionIcon}>📝</Text>
            <Text style={styles.actionText}>Nuevo Reporte</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton}>
            <Text style={styles.actionIcon}>📷</Text>
            <Text style={styles.actionText}>Reportar Infracción</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          App Inspectores Trelew v2 | {new Date().getFullYear()}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#1a73e8',
    padding: 20,
    paddingTop: 50,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerContent: {
    flex: 1,
  },
  greeting: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  subGreeting: {
    fontSize: 14,
    color: '#e3f2fd',
    marginTop: 4,
  },
  profileButton: {
    backgroundColor: 'rgba(255,255,255,0.2)',
    padding: 10,
    borderRadius: 20,
  },
  profileButtonText: {
    fontSize: 24,
  },
  content: {
    flex: 1,
    padding: 15,
  },
  statusCard: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 10,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 20,
    elevation: 2,
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#4CAF50',
    marginRight: 10,
  },
  statusText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 15,
  },
  menuGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  menuCard: {
    backgroundColor: '#fff',
    width: '48%',
    padding: 15,
    borderRadius: 10,
    marginBottom: 15,
    borderLeftWidth: 4,
    elevation: 2,
  },
  menuIcon: {
    fontSize: 30,
    marginBottom: 8,
  },
  menuTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  menuDescription: {
    fontSize: 12,
    color: '#666',
  },
  quickActions: {
    marginTop: 10,
    marginBottom: 20,
  },
  actionButton: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 10,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
    elevation: 2,
  },
  actionIcon: {
    fontSize: 24,
    marginRight: 15,
  },
  actionText: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  footer: {
    padding: 15,
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    backgroundColor: '#fff',
  },
  footerText: {
    fontSize: 12,
    color: '#666',
  },
});

export default HomeScreen;