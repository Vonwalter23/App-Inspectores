# App Inspectores Trelew v2

Aplicación Android para inspectores de tránsito de la Municipalidad de Trelew, Chubut, Argentina.

## 📋 Descripción

App móvil para inspectores de tránsito que incluye:
- Login con Google
- Flujo de aprobación de usuarios
- Panel principal con acceso a funciones del inspector

## 🛠 Tecnologías

- **Framework:** Expo + React Native
- **Lenguaje:** TypeScript
- **Autenticación:** Firebase Auth + Google Sign-In
- **Base de datos:** Cloud Firestore
- **Package Name:** `com.municipalidad.trelew.inspectores.v2`

## 📁 Estructura del Proyecto

```
app/android-v2/
├── src/
│   ├── context/
│   │   └── AuthContext.tsx      # Context de autenticación
│   ├── screens/
│   │   ├── LoginScreen.tsx      # Pantalla de login
│   │   ├── PendingScreen.tsx    # Pantalla de espera aprobación
│   │   └── HomeScreen.tsx       # Dashboard principal
│   └── services/
│       └── firebase.ts          # Configuración Firebase
├── android/                     # Proyecto nativo Android
├── releases/                    # APKs compiladas
├── App.tsx                      # Punto de entrada
├── app.json                     # Configuración Expo
└── package.json                # Dependencias
```

## 🚀 Configuración

### 1. Variables de Entorno

Crear archivo `.env` con las credenciales de Firebase:

```env
FIREBASE_API_KEY=tu_api_key
FIREBASE_AUTH_DOMAIN=tu_proyecto.firebaseapp.com
FIREBASE_PROJECT_ID=tu_proyecto
FIREBASE_STORAGE_BUCKET=tu_proyecto.appspot.com
FIREBASE_MESSAGING_SENDER_ID=tu_sender_id
FIREBASE_APP_ID=tu_app_id
```

### 2. Configuración Firebase

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar app Android con package `com.municipalidad.trelew.inspectores.v2`
3. Agregar SHA-1 del keystore (ver sección de Keystore)
4. Descargar `google-services.json` y copiar a `android/app/`
5. Habilitar Authentication → Google Sign-In
6. Crear colección `usuarios` en Firestore

### 3. Keystore

El keystore está en `releases/inspectores.jks`:

```
Alias: inspectores
Contraseña: inspectores123
SHA-1: 32:9E:08:A3:5D:52:9B:42:5C:55:56:BA:B7:20:09:D1:F2:A0:D8:8A
```

⚠️ **IMPORTANTE:** Guardar este keystore en lugar seguro. Es necesario para actualizar la app en Play Store.

## 🔧 Compilación

### Requisitos
- Java JDK 17
- Android SDK

### Compilar Debug APK
```bash
cd app/android-v2
export JAVA_HOME=/ruta/a/jdk-17
export ANDROID_HOME=/ruta/a/android-sdk
npx expo prebuild --platform android
cd android
./gradlew assembleDebug
```

### Compilar Release APK
```bash
cd app/android-v2
export JAVA_HOME=/ruta/a/jdk-17
export ANDROID_HOME=/ruta/a/android-sdk
npx expo prebuild --platform android
cd android
./gradlew assembleRelease
```

La APK se genera en: `android/app/build/outputs/apk/release/app-release.apk`

## 📱 Flujo de Usuario

1. **Login:** Usuario inicia sesión con Google
2. **Registro:** Se crea documento en Firestore con estado `pendiente`
3. **Espera:** El usuario ve pantalla de espera
4. **Aprobación:** Admin cambia estado a `aprobado` en Firestore
5. **Home:** Usuario accede al dashboard principal

## 🔐 Estructura de Datos (Firestore)

### Colección: `usuarios`
```typescript
{
  uid: string;           // UID de Firebase Auth
  email: string;          // Email del usuario
  displayName: string;   // Nombre completo
  photoURL: string;      // Foto de perfil
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  rol: 'inspector' | 'admin';
  fechaCreacion: Timestamp;
  ultimoAcceso: Timestamp;
}
```

## 📦 Dependencias

```json
{
  "firebase": "^12.15.0",
  "@react-native-google-signin/google-signin": "^16.1.2",
  "@react-navigation/native": "^7.3.4",
  "@react-navigation/stack": "^7.10.6",
  "react-native-screens": "^4.25.2",
  "react-native-safe-area-context": "^5.8.0",
  "react-native-gesture-handler": "^3.0.2"
}
```

## 📝 Notas Importantes

1. **No subir google-services.json a GitHub** - Contiene credenciales
2. **Guardar keystore** - Necesario para actualizaciones de la app
3. **SHA-1 debe coincidir** - Entre keystore y Firebase Console
4. **OAuth Production** - Para evitar restricciones de Testing en Google Sign-In

## 🔗 Enlaces Útiles

- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Expo Documentation](https://docs.expo.dev/)
- [React Native Google Sign-In](https://github.com/react-native-google-signin/google-signin)

---

**Municipalidad de Trelew, Chubut, Argentina**
