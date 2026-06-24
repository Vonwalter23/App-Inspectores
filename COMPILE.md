# 📱 Guía de Compilación - App Inspectores Trelew

## Prerequisites (Requisitos Previos)

### 1. Node.js
```bash
# Verificar versión
node --version  # Debe ser >= 18

# Instalar si no tienes: https://nodejs.org/
```

### 2. Java JDK 17+
```bash
# Verificar
java -version

# En Windows: https://adoptium.net/
# En Mac: brew install openjdk@17
# En Linux: sudo apt install openjdk-17-jdk
```

### 3. Android SDK
```bash
# Verificar
echo $ANDROID_HOME  # Debe apuntar al SDK

# Instalar Android Studio: https://developer.android.com/studio
# O standalone: https://developer.android.com/tools/releases/SDK-Tools
```

---

## Pasos de Instalación

### 1. Clonar el proyecto
```bash
git clone https://github.com/Vonwalter23/App-Inspectores.git
cd App-Inspectores
git checkout expo-dev
```

### 2. Instalar dependencias
```bash
npm install
```

### 3. Asegurarse que google-services.json está en su lugar
```bash
# Debe existir en:
# - android/app/google-services.json
# - google-services.json (raíz)

# Si no existe, descárgalo de Firebase Console
```

### 4. Generar proyecto Android
```bash
npx expo prebuild --platform android
```

### 5. Crear keystore (primera vez)
```bash
cd android/app

keytool -genkeypair -v -storetype PKCS12 \
  -keystore inspectores.jks \
  -alias inspectores \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -storepass inspectores123 \
  -keypass inspectores123 \
  -dname "CN=App Inspectores Trelew, OU=Municipalidad, O=Municipalidad de Trelew, L=Trelew, ST=Chubut, C=AR"

cd ../..
```

### 6. Configurar firma en build.gradle
Edita `android/app/build.gradle` y agrega:

```gradle
android {
    ...
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
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
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 7. Compilar APK Debug
```bash
cd android
./gradlew assembleDebug
```

### 8. Compilar APK Release
```bash
./gradlew assembleRelease
```

### 9. Encontrar el APK
```bash
# Debug
android/app/build/outputs/apk/debug/app-debug.apk

# Release
android/app/build/outputs/apk/release/app-release.apk
```

---

## 🔑 Credenciales del Keystore

| Campo | Valor |
|-------|-------|
| Keystore | `inspectores.jks` |
| Alias | `inspectores` |
| Contraseña keystore | `inspectores123` |
| Contraseña clave | `inspectores123` |

**⚠️ IMPORTANTE**: Haz backup del keystore en un lugar seguro. Sin él, NO podrás actualizar la app en Google Play.

---

## 📋 Checklist Pre-Compilación

- [ ] Node.js >= 18 instalado
- [ ] Java JDK 17+ instalado
- [ ] Android SDK instalado y ANDROID_HOME configurado
- [ ] Dependencias instaladas (`npm install`)
- [ ] google-services.json en su lugar
- [ ] Keystore creado y backup realizado
- [ ] build.gradle configurado con signing

---

## 🐛 Solución de Problemas

### Error: "JAVA_HOME is not set"
```bash
# Agregar a ~/.bashrc o ~/.zshrc
export JAVA_HOME=/path/to/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

# Recargar
source ~/.bashrc
```

### Error: "ANDROID_HOME is not set"
```bash
# Agregar a ~/.bashrc
export ANDROID_HOME=/path/to/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH

# Recargar
source ~/.bashrc
```

### Error: "google-services.json not found"
```bash
# Descargar de Firebase Console
# https://console.firebase.google.com/ → Project Settings → Your apps → Download google-services.json

# Copiar a:
cp ~/Downloads/google-services.json android/app/
cp ~/Downloads/google-services.json ./
```

### Error: "Gradle build failed"
```bash
# Limpiar y recompilar
cd android
./gradlew clean
./gradlew assembleDebug
```

---

## 📁 Estructura del Proyecto

```
AppInspectores/
├── App.tsx                    # Componente principal
├── app.json                   # Configuración Expo
├── google-services.json       # Firebase config (copiar a android/app/)
├── src/
│   ├── context/
│   │   └── AuthContext.tsx    # Autenticación y estado
│   ├── screens/
│   │   ├── LoginScreen.tsx    # Pantalla de login
│   │   ├── PendingScreen.tsx  # Pantalla de espera
│   │   └── HomeScreen.tsx     # Pantalla principal
│   └── services/
│       └── firebase.ts        # Configuración Firebase
├── android/                   # Proyecto Android generado
│   └── app/
│       ├── build.gradle       # Configuración de compilación
│       └── google-services.json  # Firebase config
└── package.json
```

---

## 🔗 Links Útiles

- [Documentación Expo](https://docs.expo.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Android Studio](https://developer.android.com/studio)
- [Node.js](https://nodejs.org/)
