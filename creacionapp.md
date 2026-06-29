# Guía para Crear App Android Inspectores Trelew v2

## 📋 INFORMACIÓN DEL PROYECTO

### Datos del nuevo proyecto
- **Package Name:** `com.municipalidad.trelew.inspectores.v2`
- **Nombre App:** `App Inspectores Trelew v2`
- **Proyecto Firebase:** `inspectores-app`

### Repositorio
- **URL:** https://github.com/Vonwalter23/App-Inspectores
- **Rama para app:** `app-android-v2`

---

## 🔧 INSTALACIÓN DE JAVA Y ANDROID SDK EN SERVIDOR

### 1. Descargar e instalar Java JDK 17

```bash
# Crear directorio
mkdir -p /workspace/java

# Descargar JDK 17
cd /workspace/java
curl -fsSL "https://download.oracle.com/java/17/archive/jdk-17.0.5_linux-x64_bin.tar.gz" -o jdk17.tar.gz

# Extraer
tar -xzf jdk17.tar.gz

# Configurar variables
export JAVA_HOME=/workspace/java/jdk-17.0.5
export PATH=$JAVA_HOME/bin:$PATH

# Verificar
java -version
```

### 2. Descargar e instalar Android SDK

```bash
# Crear directorio SDK
mkdir -p /workspace/android-sdk/cmdline-tools
cd /workspace/android-sdk/cmdline-tools

# Descargar command line tools
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o cmdline-tools.zip

# Extraer (usar Python si unzip no disponible)
python3 -c "import zipfile; zipfile.ZipFile('cmdline-tools.zip', 'r').extractall('.')"
mv cmdline-tools latest

# Dar permisos
chmod +x /workspace/android-sdk/cmdline-tools/latest/bin/*

# Configurar PATH
export ANDROID_HOME=/workspace/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Aceptar licencias
yes | sdkmanager --licenses

# Instalar componentes necesarios
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

---

## 🚀 PASOS PARA CREAR LA APP

### Paso 1: Crear proyecto Expo

```bash
cd /workspace
npx create-expo-app@latest AppInspectoresV2 --template blank-typescript
cd AppInspectoresV2
```

### Paso 2: Instalar dependencias

```bash
# Firebase
npm install firebase@12.15.0

# Google Sign-In
npm install @react-native-google-signin/google-signin

# Navegación (si se necesita)
npm install @react-navigation/native @react-navigation/stack
npm install react-native-screens react-native-safe-area-context
```

### Paso 3: Configurar Google Sign-In

Crear archivo `src/services/firebase.ts`:

```typescript
import { initializeApp, getApps } from 'firebase/app';
import { getAuth, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { GoogleSignin } from '@react-native-google-signin/google-signin';

const firebaseConfig = {
  apiKey: "API_KEY_DEL_NUEVO_PROYECTO",
  authDomain: "NOMBRE_PROYECTO.firebaseapp.com",
  projectId: "NOMBRE_PROYECTO",
  storageBucket: "NOMBRE_PROYECTO.appspot.com",
  messagingSenderId: "SENDER_ID",
  appId: "APP_ID"
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
export const auth = getAuth(app);
export const db = getFirestore(app);

GoogleSignin.configure({
  webClientId: 'WEB_CLIENT_ID.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
  offlineAccess: false,
});

export { GoogleSignin };
export { signOut, onAuthStateChanged, doc, getDoc, setDoc, serverTimestamp };
export type { User };
```

### Paso 4: Generar Keystore

```bash
cd android/app

# Generar keystore
keytool -genkeypair -v -storetype PKCS12 \
  -keystore inspectores.jks \
  -alias inspectores \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -storepass inspectores123 \
  -keypass inspectores123 \
  -dname "CN=App Inspectores Trelew, OU=Municipalidad, O=Municipalidad de Trelew, L=Trelew, ST=Chubut, C=AR"

# Obtener SHA-1
keytool -list -v -keystore inspectores.jks -storepass inspectores123 -alias inspectores | grep SHA1
```

### Paso 5: Actualizar app.json

```json
{
  "expo": {
    "name": "App Inspectores Trelew",
    "slug": "AppInspectoresV2",
    "version": "1.0.0",
    "android": {
      "package": "com.municipalidad.trelew.inspectores.v2",
      "adaptiveIcon": {
        "backgroundColor": "#1a73e8",
        "foregroundImage": "./assets/android-icon-foreground.png"
      }
    }
  }
}
```

### Paso 6: Configurar build.gradle

Modificar `android/app/build.gradle`:

```gradle
android {
    // ... configuración existente ...
    
    signingConfigs {
        release {
            storeFile file('inspectores.jks')
            storePassword 'inspectores123'
            keyAlias 'inspectores'
            keyPassword 'inspectores123'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Paso 7: Prebuild y compilar

```bash
# Configurar variables
export JAVA_HOME=/workspace/java/jdk-17.0.5
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_HOME=/workspace/android-sdk

# Crear local.properties
echo "sdk.dir=/workspace/android-sdk" > android/local.properties

# Prebuild
npx expo prebuild --platform android --clean

# Copiar google-services.json a android/app/

# Compilar release
cd android
chmod +x gradlew
./gradlew assembleRelease --no-daemon
```

### Paso 8: Generar APK final

```bash
# La APK estará en:
android/app/build/outputs/apk/release/app-release.apk

# Copiar a releases
mkdir -p releases
cp android/app/build/outputs/apk/release/app-release.apk releases/
cp android/app/inspectores.jks releases/
```

---

## ⚠️ ERRORES COMUNES Y SOLUCIONES

### Error: auth/argument-error
**Causa:** Pasar serverAuthCode a GoogleAuthProvider.credential

**Solución:**
```typescript
// INCORRECTO
const credential = GoogleAuthProvider.credential(idToken, serverAuthCode);

// CORRECTO
const credential = GoogleAuthProvider.credential(idToken);
```

### Error: DEVELOPER_ERROR
**Causa:** SHA-1 no coincide entre keystore y Firebase

**Solución:**
1. Verificar SHA-1 del keystore
2. Agregar SHA-1 exacto en Firebase Console → Project Settings → App Android

### Error: signInWithPopup not defined
**Causa:** Usar API web en app nativa

**Solución:** Usar @react-native-google-signin/google-signin
```typescript
import { GoogleSignin } from '@react-native-google-signin/google-signin';
const googleUser = await GoogleSignin.signIn();
```

### Error: Module not found
**Causa:** Dependencias no instaladas

**Solución:**
```bash
npm install
npx expo install --check
```

---

## 🔑 CONFIGURACIÓN FIREBASE REQUERIDA

### 1. Crear nuevo proyecto en Firebase Console
- Ir a: https://console.firebase.google.com/
- Crear proyecto: `inspectores-app`

### 2. Agregar App Android
- Package name: `com.municipalidad.trelew.inspectores.v2`
- SHA-1: (agregar el del keystore generado)

### 3. Descargar google-services.json
- Descargar desde Firebase Console
- Copiar a `android/app/google-services.json`

### 4. Habilitar Authentication
- Firebase Console → Authentication → Enable Google

### 5. Configurar OAuth Consent
- Google Cloud Console → APIs & Services → OAuth consent
- Cambiar a **Production** (NO Testing)
- Esto permite login sin agregar test users

### 6. APIs necesarias
- Google Identity Toolkit API
- Firebase Auth API
- Cloud Firestore API

---

## 📁 ESTRUCTURA DEL PROYECTO

```
AppInspectoresV2/
├── src/
│   ├── context/
│   │   └── AuthContext.tsx      # Autenticación
│   ├── screens/
│   │   ├── LoginScreen.tsx      # Login Google
│   │   ├── PendingScreen.tsx    # Espera aprobación
│   │   └── HomeScreen.tsx       # Dashboard
│   ├── services/
│   │   └── firebase.ts          # Config Firebase
│   └── App.tsx                  # Entry point
├── android/
│   └── app/
│       ├── build.gradle         # Config build
│       ├── google-services.json # Firebase config
│       └── inspectores.jks      # Keystore
├── releases/                    # APK compiladas
├── app.json
└── package.json
```

---

## 🔐 CREDENCIALES IMPORTANTES

### Keystore
| Campo | Valor |
|-------|-------|
| Alias | `inspectores` |
| Contraseña | `inspectores123` |
| Validez | 10000 días |

### Archivos importantes
- `inspectores.jks` → Guardar en lugar seguro
- `google-services.json` → No subir a GitHub (agregar a .gitignore)

---

## 📝 COMANDOS ÚTILES

```bash
# Limpiar build
./gradlew clean

# Compilar debug
./gradlew assembleDebug

# Compilar release
./gradlew assembleRelease

# Ver APK
ls -la android/app/build/outputs/apk/release/
```

---

## 📌 NOTAS IMPORTANTES

1. **Siempre usar Java 17** para compilar
2. **No usar signInWithPopup** en Android (es para web)
3. **SHA-1 debe coincidir** exactamente entre keystore y Firebase
4. **OAuth en Production** para evitar restricciones de Testing
5. **Guardar keystore** en lugar seguro (necesario para actualizaciones)

---

## 🔗 ENLACES ÚTILES

- Firebase Console: https://console.firebase.google.com/
- Google Cloud Console: https://console.cloud.google.com/
- Expo Docs: https://docs.expo.dev/
- React Native Google Sign-In: https://github.com/react-native-google-signin/google-signin
