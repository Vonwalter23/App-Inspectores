import { initializeApp, getApps } from 'firebase/app';
import { getAuth, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { GoogleSignin } from '@react-native-google-signin/google-signin';

// Configuración de Firebase para App Inspectores Trelew
const firebaseConfig = {
  apiKey: "AIzaSyDib4_Bn8k9UpXIyo8XAzb74yLt8sgZS2Y",
  authDomain: "app-inspectores-trelew-499913.firebaseapp.com",
  projectId: "app-inspectores-trelew-499913",
  storageBucket: "app-inspectores-trelew-499913.appspot.com",
  messagingSenderId: "468318865609",
  appId: "1:468318865609:android:86e66bd3eac14fa5cda518"
};

// Inicializar Firebase solo si no está ya inicializado
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

// Inicializar servicios
export const auth = getAuth(app);
export const db = getFirestore(app);

// Configurar Google Sign-In con el Web Client ID de OAuth 2.0
GoogleSignin.configure({
  webClientId: '468318865609-2nq5s9fju53tsvu5v8s8gsuvadout2f2.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
  offlineAccess: false,
});

// Exportar GoogleSignin para uso en AuthContext
export { GoogleSignin };

export { signOut, onAuthStateChanged, doc, getDoc, setDoc, serverTimestamp };
export type { User };
