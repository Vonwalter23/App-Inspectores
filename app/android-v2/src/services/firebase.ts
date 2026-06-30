import { initializeApp, getApps } from 'firebase/app';
import { getAuth, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc, serverTimestamp, updateDoc, arrayUnion } from 'firebase/firestore';
import { GoogleSignin, GoogleUser } from '@react-native-google-signin/google-signin';

// Configuración de Firebase
const firebaseConfig = {
  apiKey: "AIzaSyCHdsxtVQ3MuayxdfXJxN_LsLaIKdHKkFs",
  authDomain: "inspectores-app.firebaseapp.com",
  projectId: "inspectores-app",
  storageBucket: "inspectores-app.firebasestorage.app",
  messagingSenderId: "166006434703",
  appId: "1:166006434703:android:fce70be5cbe31a365139fa"
};

// Inicializar Firebase
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
export const auth = getAuth(app);
export const db = getFirestore(app);

// Configurar Google Sign-In
GoogleSignin.configure({
  webClientId: '166006434703-9hbsjuklvgabevf3cvb2jbd2tgcicsb8.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
  offlineAccess: false,
});

export { GoogleSignin };
export { signOut, onAuthStateChanged, doc, getDoc, setDoc, serverTimestamp, updateDoc, arrayUnion };
export type { User, GoogleUser };