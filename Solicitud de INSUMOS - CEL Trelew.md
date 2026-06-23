# SOLICITUD DE INSUMOS - CEL TRELEW
## Sistema Integral para Inspectores de Tránsito de Trelew

---

## 📋 INFORMACIÓN GENERAL

| Campo | Valor |
|-------|-------|
| **Proyecto** | Sistema Integral para Inspectores de Tránsito de Trelew |
| **Repositorio** | Vonwalter23/App-Inspectores |
| **Fecha de Creación** | 2024 |
| **Última Actualización** | 2024-06-22 |
| **Estado** | EN DESARROLLO - PROBLEMAS CRÍTICOS |
| **Plataforma Principal** | Flutter (Android) + Web Admin |

---

## 🎯 OBJETIVO DEL PROYECTO

Desarrollar una plataforma completa para los Inspectores de Tránsito de la Municipalidad de Trelew:

### Componentes:
1. **Aplicación Android (APK)** - Para inspectores
2. **Plataforma Web Administrativa** - Para administradores

### Funcionalidades Principales:
- Login con Google Sign In
- Asistente Legal IA con RAG (Groq API)
- Mensajería interna (texto/audio)
- Geolocalización en tiempo real
- Notificaciones Push (Firebase Cloud Messaging)
- Gestión documental (Google Drive)

---

## 🏗️ ARQUITECTURA DEL SISTEMA

### Stack Tecnológico

#### Aplicación Móvil (Android)
```
- Flutter 3.x
- Android 10+ (minSdk 23)
- Material Design 3
- Dart 3.x
```

#### Backend
```
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Hosting
- Firebase Functions (futuro)
```

#### Servicios Externos
```
- Google Sign In
- Google Drive API
- Google Maps API
- Groq API (IA - modelos gratuitos)
```

### Modelo de Datos (Firestore)

```
/users/{uid}
  - nombre: string
  - apellido: string
  - email: string
  - estado: "pendiente" | "aprobado" | "rechazado"
  - fechaRegistro: timestamp
  - rol: "inspector" | "admin"
  - ubicacion: { lat, lng, timestamp }

/mensajes/{id}
  - texto: string
  - remitenteId: string
  - remitenteNombre: string
  - timestamp: timestamp
  - tipo: "texto" | "audio"

/normas/{id}
  - titulo: string
  - tipo: "ley" | "ordenanza" | "resolucion"
  - texto: string
  - embedding: vector (para RAG)
  - fechaCarga: timestamp
  - driveFileId: string
```

### Roles del Sistema

#### Inspector
- Login con Google ✅
- Consultar asistente legal IA ✅
- Ver/enviar mensajes ✅
- Enviar mensajes de audio (pendiente)
- Compartir ubicación (pendiente)
- Recibir notificaciones ✅

#### Administrador
- Aprobar/rechazar usuarios ✅
- Visualizar inspectores conectados (pendiente)
- Ver ubicación en tiempo real (pendiente)
- Gestionar documentación legal (pendiente)
- Consultar logs (pendiente)

---

## 📁 ESTRUCTURA DEL PROYECTO

```
sistema-inspectores-trelew/
├── app_inspectores/           # Flutter Android App
│   ├── lib/
│   │   ├── main.dart          # Entry point
│   │   └── src/
│   │       ├── auth/
│   │       │   ├── login_page.dart
│   │       │   └── pending_page.dart
│   │       ├── home/
│   │       │   └── home_page.dart
│   │       ├── chat/
│   │       │   └── chat_page.dart
│   │       ├── mensajeria/
│   │       │   └── mensajes_page.dart
│   │       └── services/
│   │           ├── auth_service.dart
│   │           └── notification_service.dart
│   ├── android/
│   │   └── app/
│   │       ├── build.gradle
│   │       └── google-services.json
│   └── pubspec.yaml
│
├── web_admin/                 # Panel Web Admin (React/Next.js)
│   └── (código existente en GitHub)
│
└── firebase/                  # Config Firebase
    └── (rules, functions)
```

---

## ❌ ERRORES IDENTIFICADOS

### Error 1: App queda en Logo Inicial (CRÍTICO)

**Síntoma:** 
- La APK se instala correctamente
- Al abrirla muestra el logo y queda congelada
- No avanza a la pantalla de login

**Causa Raíz (investigación):**
1. Firebase Authentication no puede inicializar correctamente
2. El `google-services.json` puede no estar configurado correctamente
3. Las reglas de Firestore pueden estar bloqueando el acceso
4. Posible incompatibilidad con el dispositivo Samsung A21 (Android 12)

**Archivo Afectado:** `app_inspectores/lib/main.dart`

**Código Problemático Original:**
```dart
// El authStateChanges().listen() causa bloqueo si Firebase no responde
FirebaseAuth.instance.authStateChanges.listen((User? user) {
  _checkAuthState(user);
});
```

### Error 2: Firebase Connection Timeout

**Síntoma:**
- Error visible: "Error: 403 Forbidden" o timeouts
- La app no puede leer/escribir en Firestore

**Causa:**
- Falta configurar SHA-1 del certificado de firma
- El google-services.json no tiene los SHA correctos

**Solución Requerida:**
```bash
# Generar SHA-1 del certificado de depuración
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Error 3: Versiones de Dependencias

**Síntoma:**
- Errores de compilación en Gradle
- Incompatibilidad con Kotlin

**Archivo:** `android/settings.gradle`

**Valores Actuales (pueden necesitar actualización):**
```gradle
id "com.android.application" version "8.1.0" apply false
id "org.jetbrains.kotlin.android" version "1.9.22" apply false
```

---

## 🔧 PASOS PARA REPRODUCCIÓN DEL ERROR

1. Instalar APK en Samsung A21 (Android 12)
2. Abrir la aplicación
3. Verificar que muestra logo pero no avanza
4. Si hay error previo: podría mostrar "403 Forbidden" o similar

---

## ✅ SOLUCIONES PROPUESTAS

### Solución 1: Simplificar el AuthWrapper

Reemplazar el código de autenticación con timeouts apropiados:

```dart
// En main.dart - AuthWrapper
Future<void> _checkInitialState() async {
  try {
    final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    await _navigateBasedOnUser(user);
  } catch (e) {
    // Ir directo a login si falla
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }
}
```

### Solución 2: Configurar SHA-1 en Firebase Console

Pasos:
1. Ir a Firebase Console → Configuración del proyecto
2. Agregar huella digital SHA-1
3. Descargar nuevo google-services.json
4. Reemplazar en el proyecto

```bash
# Comando para obtener SHA-1
cd ~/Android/Sdk/build-tools/30.0.3/
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -d "CN=Android Debug,O=Android,C=US"
```

### Solución 3: Verificar google-services.json

El archivo debe contener:
```json
{
  "project_info": {
    "project_number": "...",
    "project_id": "app-inspectores-trelew-499913",
    "storage_bucket": "app-inspectores-trelew-499913.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:...:android:...",
        "android_client_info": {
          "package_name": "com.municipalidad.trelew.app_inspectores"
        }
      },
      "oauth_client": [...],
      "api_key": [...],
      "services": {
        "appinvite_service": {...}
      }
    }
  ],
  "configuration_version": "1"
}
```

---

## 📊 FLUJO DE AUTENTICACIÓN

```
┌─────────────────┐
│   App Inicia    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Firebase Init  │──Error──▶ Mostrar Error + Retry
└────────┬────────┘
         │ OK
         ▼
┌─────────────────┐
│ Check Auth State│──Timeout──▶ Ir a Login
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐  ┌──────────┐
│ User  │  │ No User  │
│  OK   │  │    →     │
└───┬───┘  └────┬─────┘
    │            │
    ▼            ▼
┌─────────┐  ┌─────────┐
│Check    │  │  Login  │
│Firestore│  │  Page   │
└────┬────┘  └─────────┘
     │
┌────┴────┐
│         │
▼         ▼
┌─────┐  ┌─────────┐
│Status│  │Pending  │
│=OK   │  │ Page    │
└───┬─┘  └─────────┘
    │
    ▼
┌─────────┐
│ Home    │
│ Page    │
└─────────┘
```

---

## 🔑 API KEYS Y CONFIGURACIÓN

### Firebase
- **Project ID:** app-inspectores-trelew-499913
- **Package:** com.municipalidad.trelew.app_inspectores

### Google Drive
- **Folder ID:** 11U5_4AceI_l7cEEkEjaEk_WLUsXSi1Jz

### Groq API
- **Key:** (Pendiente de configurar en producción)
- **Modelos recomendados:**
  - llama-3.1-8b-instant (gratuito)
  - gemma-7b-it (gratuito)

---

## 📱 ESPECIFICACIONES APK

| Propiedad | Valor |
|-----------|-------|
| **Package Name** | com.municipalidad.trelew.app_inspectores |
| **minSdkVersion** | 23 (Android 10) |
| **targetSdkVersion** | 34 (Android 14) |
| **compileSdkVersion** | 34 |
| **Kotlin Version** | 1.9.22 |
| **Gradle Version** | 8.1.0 |
| **AGP Version** | 8.1.0 |

---

## 🚀 COMANDOS DE BUILD

```bash
# Compilar APK Debug
cd app_inspectores
flutter build apk --debug

# Compilar APK Release
flutter build apk --release

# Limpiar y recompilar
flutter clean
flutter pub get
flutter build apk --debug

# Verificar instalación de dependencias
flutter pub deps
```

---

## 📦 DEPENDENCIAS ACTUALES (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.10
  
  # Google Sign In
  google_sign_in: ^6.2.1

  # Utils
  intl: ^0.18.1
  shared_preferences: ^2.2.2
  http: ^1.2.0
```

---

## 🔐 REGLAS DE FIRESTORE (rules.security)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'admin';
    }
    
    // Mensajes collection
    match /mensajes/{mensajeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if false; // Solo admins pueden modificar
    }
    
    // Solo usuarios aprobados pueden acceder
    match /users/{userId}/ubicacion {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

### Fase 1: Autenticación ✅
- [x] Login con Google Sign In
- [x] Registro automático en Firestore
- [x] Pantalla de aprobación pendiente
- [ ] Verificación de estado en Firestore

### Fase 2: Core App ⏳
- [x] Pantalla principal (Dashboard)
- [x] Navegación inferior
- [x] Perfil de usuario
- [ ] Cerrar sesión

### Fase 3: Mensajería ⏳
- [x] Lista de mensajes
- [x] Enviar mensaje de texto
- [ ] Enviar mensaje de audio
- [ ] Soporte para @usuario
- [ ] Notificaciones

### Fase 4: Chat IA ⏳
- [x] Interfaz de chat
- [ ] Integración con RAG
- [ ] Búsqueda en normas
- [ ] Formato de respuesta con referencia legal

### Fase 5: Geolocalización ⏳
- [ ] Servicio de ubicación en segundo plano
- [ ] Actualización cada 30 segundos
- [ ] Guardar en Firestore
- [ ] Panel de mapa en admin

### Fase 6: Admin Web ⏳
- [x] Dashboard
- [ ] Gestión de usuarios
- [ ] Gestión documental
- [ ] Mapa en tiempo real
- [ ] Logs

---

## 🎯 PRIORIDADES PARA RESOLVER

### CRÍTICO (Bloquea uso)
1. **Arreglar inicialización de Firebase** - App queda en logo
2. **Configurar SHA-1** en Firebase Console
3. **Verificar google-services.json**

### ALTO (Funcionalidad básica)
4. Implementar verificación de estado de usuario
5. Agregar mensajes de error claros
6. Implementar logout funcional

### MEDIO (Mejora UX)
7. Agregar geolocalización
8. Implementar mensajes de audio
9. Configurar notificaciones push

### BAJO (Features completos)
10. Chat IA con RAG
11. Panel Admin completo
12. Documentación legal

---

## 📝 NOTAS PARA DESARROLLADOR

### Para continuar desde otra conversación:

1. **Clonar repositorio:**
   ```bash
   git clone https://github.com/Vonwalter23/App-Inspectores.git
   ```

2. **Revisar google-services.json:**
   - Verificar que el package_name coincida
   - Agregar SHA-1 si no está

3. **Compilar APK:**
   ```bash
   cd app_inspectores
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

4. **Instalar en dispositivo:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

5. **Ver logs de error:**
   ```bash
   adb logcat | grep -i flutter
   ```

### Causa más probable del error:
El dispositivo no puede conectar con Firebase. Posibles razones:
- Bloqueo de red
- SHA-1 no configurado
- google-services.json incorrecto

### Recomendación:
Probar en un emulador primero para descartar problemas del dispositivo físico.

---

## 🔗 ENLACES IMPORTANTES

- **Firebase Console:** https://console.firebase.google.com/project/app-inspectores-trelew-499913
- **Google Drive (APKs):** https://drive.google.com/drive/folders/11U5_4AceI_l7cEEkEjaEk_WLUsXSi1Jz
- **GitHub Repo:** https://github.com/Vonwalter23/App-Inspectores

---

## 📞 INFORMACIÓN DE CONTACTO

- **Desarrollador:** CEL Trelew
- **Proyecto:** Inspectores de Tránsito Municipal
- **Ciudad:** Trelew, Chubut, Argentina

---

*Documento generado automáticamente para transferencia de conocimiento entre sesiones de desarrollo.*
*Fecha: 2024-06-22*
