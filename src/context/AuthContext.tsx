import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db, signOut, GoogleSignin } from '../services/firebase';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';

export type UserStatus = 'loading' | 'pending' | 'approved' | 'rejected' | 'not_found' | null;

interface AuthUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

interface AuthContextType {
  user: AuthUser | null;
  userStatus: UserStatus;
  loading: boolean;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [userStatus, setUserStatus] = useState<UserStatus>('loading');
  const [loading, setLoading] = useState(true);

  // Escuchar cambios en el estado de autenticación
  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged(async (firebaseUser) => {
      if (firebaseUser) {
        setUser({
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
        });
        
        // Verificar estado del usuario en Firestore
        await checkUserStatus(firebaseUser.uid);
      } else {
        setUser(null);
        setUserStatus(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Verificar estado del usuario en Firestore
  const checkUserStatus = async (uid: string) => {
    try {
      const userDoc = await getDoc(doc(db, 'users', uid));
      
      if (userDoc.exists()) {
        const estado = userDoc.data().estado;
        setUserStatus(estado as UserStatus);
      } else {
        // Usuario no existe, crear solicitud pendiente
        setUserStatus('pending');
      }
    } catch (error) {
      console.error('Error al verificar estado:', error);
      setUserStatus('not_found');
    }
  };

  // Crear solicitud de registro pendiente
  const createUserRequest = async (uid: string, email: string, displayName: string | null, photoURL: string | null) => {
    try {
      const nameParts = displayName?.split(' ') || ['', ''];
      const userData = {
        uid: uid,
        email: email,
        nombre: nameParts[0] || '',
        apellido: nameParts.slice(1).join(' ') || '',
        credencial: '',
        estado: 'pendiente',
        rol: 'inspector',
        fechaRegistro: serverTimestamp(),
        fotoUrl: photoURL || null,
      };

      // Crear en colección users
      await setDoc(doc(db, 'users', uid), userData);
      
      setUserStatus('pending');
    } catch (error) {
      console.error('Error al crear solicitud:', error);
    }
  };

  // Iniciar sesión con Google (Android native)
  const handleSignIn = async () => {
    try {
      // Obtener tokens de Google
      await GoogleSignin.hasPlayServices();
      const googleUser = await GoogleSignin.signIn();
      
      // Crear credencial de Firebase con el idToken
      const idToken = (googleUser as any).idToken;
      const serverAuthCode = (googleUser as any).serverAuthCode;
      
      const credential = GoogleAuthProvider.credential(idToken, serverAuthCode || undefined);
      
      // Iniciar sesión en Firebase con la credencial
      await signInWithCredential(auth, credential);
      
      // Verificar si es nuevo usuario
      const currentUser = auth.currentUser;
      if (currentUser) {
        const userDoc = await getDoc(doc(db, 'users', currentUser.uid));
        if (!userDoc.exists()) {
          await createUserRequest(
            currentUser.uid,
            currentUser.email || '',
            currentUser.displayName,
            currentUser.photoURL
          );
        }
      }
      
      console.log('Login exitoso:', currentUser?.email);
    } catch (error: any) {
      console.error('Error en login:', error);
      throw error;
    }
  };

  // Cerrar sesión
  const handleSignOut = async () => {
    try {
      await GoogleSignin.revokeAccess();
      await GoogleSignin.signOut();
      await signOut(auth);
      setUser(null);
      setUserStatus(null);
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        userStatus,
        loading,
        signIn: handleSignIn,
        signOut: handleSignOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
