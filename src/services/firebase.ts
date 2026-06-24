import { initializeApp, getApps } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';

// Configuración de Firebase para App Inspectores Trelew
// Esta configuración se obtiene de Firebase Console → Project Settings → Your apps
const firebaseConfig = {
  apiKey: "AIzaSyD3xXXXXXXXXXXXXXXXXXXXXXXXXX", // Reemplazar con tu API key real
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

// Provider de Google
const googleProvider = new GoogleAuthProvider();
googleProvider.addScope('email');
googleProvider.addScope('profile');

// WebClientId para Google Sign-In (obtenido de Firebase Console)
export const WEB_CLIENT_ID = '468318865609-2nq5s9fju53tsvu5v8s8gsuvadout2f2.apps.googleusercontent.com';

export { signInWithPopup, signOut, onAuthStateChanged, doc, getDoc, setDoc, serverTimestamp };
export type { User };
