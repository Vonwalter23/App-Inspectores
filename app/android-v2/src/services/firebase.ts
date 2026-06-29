import { initializeApp, getApps } from 'firebase/app';
import { getAuth, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc, serverTimestamp, updateDoc, arrayUnion } from 'firebase/firestore';
import { GoogleSignin, GoogleUser } from '@react-native-google-signin/google-signin';

// Configuración de Firebase - REEMPLAZAR CON TUS PROPIAS CREDENCIALES
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "inspectores-app.firebaseapp.com",
  projectId: "inspectores-app",
  storageBucket: "inspectores-app.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// Inicializar Firebase
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
export const auth = getAuth(app);
export const db = getFirestore(app);

// Configurar Google Sign-In
GoogleSignin.configure({
  webClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
  offlineAccess: false,
});

export { GoogleSignin };
export { signOut, onAuthStateChanged, doc, getDoc, setDoc, serverTimestamp, updateDoc, arrayUnion };
export type { User, GoogleUser };