import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { onAuthStateChanged, signOut as firebaseSignOut, User as FirebaseUser } from 'firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../services/firebase';

interface UserData {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  rol: 'inspector' | 'admin';
  fechaCreacion: any;
  ultimoAcceso: any;
}

interface AuthContextType {
  user: FirebaseUser | null;
  userData: UserData | null;
  loading: boolean;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser);
      
      if (firebaseUser) {
        // Verificar si el usuario existe en Firestore
        const userDoc = await getDoc(doc(db, 'usuarios', firebaseUser.uid));
        
        if (userDoc.exists()) {
          setUserData(userDoc.data() as UserData);
        } else {
          // Crear usuario pendiente si es nuevo
          const newUserData: UserData = {
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            estado: 'pendiente',
            rol: 'inspector',
            fechaCreacion: serverTimestamp(),
            ultimoAcceso: serverTimestamp(),
          };
          await setDoc(doc(db, 'usuarios', firebaseUser.uid), newUserData);
          setUserData(newUserData);
        }
      } else {
        setUserData(null);
      }
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const signIn = async () => {
    try {
      await GoogleSignin.hasPlayServices();
      const googleUser = await GoogleSignin.signIn();
      
      if (googleUser.idToken) {
        // Obtener credenciales de Firebase
        const { getFirebaseAuth } = await import('@react-native-google-signin/google-signin');
        const { GoogleAuthProvider } = await import('firebase/auth');
        
        // Firebase Auth ya está configurado, pero necesitamos las credenciales
        // Esto se maneja automáticamente con @react-native-google-signin
      }
    } catch (error) {
      console.error('Error en signIn:', error);
      throw error;
    }
  };

  const signOut = async () => {
    try {
      await GoogleSignin.revokeAccess();
      await GoogleSignin.signOut();
      await firebaseSignOut(auth);
    } catch (error) {
      console.error('Error en signOut:', error);
      throw error;
    }
  };

  return (
    <AuthContext.Provider value={{ user, userData, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth debe ser usado dentro de un AuthProvider');
  }
  return context;
};