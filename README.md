# Sistema Integral para Inspectores de Tránsito de Trelew

## 🚀 Estado del Proyecto

| Componente | Estado | URL |
|------------|--------|-----|
| Panel Admin Web | ✅ Funcional | https://vonwalter23.github.io/App-Inspectores/ |
| App Android | 🔄 En desarrollo | `app_inspectores/` |
| Backend Firebase | ✅ Configurado | `app-inspectores-trelew-499913` |
| Firestore | ✅ Activo | Colecciones: users, ubicaciones, mensajes |
| GitHub Pages | ✅ Activo | Rama `gh-pages` |

---

## 📋 Descripción

Plataforma completa para inspectores de tránsito de la Municipalidad de Trelew, Chaco, Argentina.

### Características Principales

- **Autenticación**: Google Sign In
- **App Móvil**: Flutter (Android 10+)
- **Panel Web**: Progressive Web App (PWA)
- **Backend**: Firebase (Firestore, FCM, Auth)
- **IA Legal**: Groq API con sistema RAG
- **Mapas**: Google Maps API
- **Documentación**: Google Drive integration

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA DEL SISTEMA                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐         ┌──────────────────────────┐    │
│   │  App Android  │         │     Panel Admin Web      │    │
│   │   (Flutter)   │         │   (GitHub Pages)         │    │
│   └───────┬──────┘         └───────────┬──────────────┘    │
│           │                             │                   │
│           └──────────┬──────────────────┘                   │
│                      │                                      │
│                      ▼                                      │
│           ┌─────────────────────┐                          │
│           │   Firebase Auth     │                          │
│           │   (Authentication)   │                          │
│           └──────────┬──────────┘                          │
│                      │                                      │
│           ┌──────────┴──────────┐                           │
│           │                     │                           │
│           ▼                     ▼                           │
│   ┌───────────────┐   ┌───────────────┐                   │
│   │   Firestore    │   │     FCM       │                   │
│   │  (Database)    │   │ (Notifications)                   │
│   └───────────────┘   └───────────────┘                   │
│                                                             │
│   ┌─────────────────────────────────────────┐               │
│   │           Groq API (IA)                │               │
│   │      RAG - Asistente Legal             │               │
│   └─────────────────────────────────────────┘               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 👥 Roles del Sistema

### Inspector
- Login con Google
- Consultar asistente legal IA
- Mensajería interna (texto y audio)
- Geolocalización en tiempo real
- Recibir notificaciones

### Administrador
- Gestionar usuarios (aprobar/rechazar)
- Ver inspectores en mapa en tiempo real
- Gestionar documentación legal
- Consultar logs de actividad

---

## 📁 Estructura del Proyecto

```
sistema-inspectores-trelew/
├── app_inspectores/          # App Flutter Android
│   ├── android/
│   │   └── app/
│   │       └── google-services.json  # Firebase config
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/          # Firebase, Chat, Location
│   │   ├── screens/           # Pantallas UI
│   │   └── models/            # Modelos de datos
│   └── pubspec.yaml
│
├── panel_admin/              # Panel Web Admin
│   ├── public/
│   │   ├── index.html
│   │   ├── css/styles.css
│   │   └── js/
│   │       ├── app.js
│   │       └── firebase-config.js
│   └── firebase.json
│
├── docs/                     # GitHub Pages (carpeta docs)
│
├── AGENTE.md                 # Documentación del agente IA
├── README.md                 # Este archivo
└── firebase-credentials.json  # Admin SDK credentials
```

---

## 🔧 Configuración Firebase

### Proyecto
- **Project ID**: `app-inspectores-trelew-499913`
- **Project Number**: `468318865609`

### Apps Registradas
| Tipo | Package/Bundle | Status |
|------|----------------|--------|
| Web | Panel Admin | ✅ Activa |
| Android | `com.municipalidad.trelew.inspectores` | ✅ Configurada |

### Servicios Habilitados
- ✅ Firebase Authentication (Google Sign-In)
- ✅ Cloud Firestore
- ✅ Firebase Cloud Messaging
- ✅ Firebase Storage

---

## 🚀 Despliegue

### Panel Web (GitHub Pages)

```bash
# 1. Ir a la rama gh-pages
git checkout gh-pages

# 2. Actualizar archivos en docs/
cp panel_admin/public/* docs/

# 3. Commit y push
git add docs/
git commit -m "Actualización del panel"
git push origin gh-pages
```

**URL**: https://vonwalter23.github.io/App-Inspectores/

### App Android

```bash
cd app_inspectores

# Instalar dependencias
flutter pub get

# Compilar debug APK
flutter build apk --debug

# El APK estará en:
# build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🔐 Seguridad - Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Usuarios - solo admins pueden escribir
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'admin';
    }
    
    // Ubicaciones - solo inspectores aprobados
    match /ubicaciones/{userId} {
      allow read: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.estado == 'aprobado';
      allow write: if request.auth != null 
        && request.auth.uid == userId;
    }
    
    // Mensajes - solo inspectores aprobados
    match /mensajes/{messageId} {
      allow read, write: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.estado == 'aprobado';
    }
  }
}
```

---

## 🤖 Asistente Legal IA (RAG)

### Configuración Groq

```bash
# Variable de entorno requerida
export GROQ_API_KEY="tu-api-key-de-groq"
```

### Modelos Disponibles (Gratuitos)
- `llama-3.1-8b-instant`
- `mixtral-8x7b-32768`
- `gemma2-9b-instant`

### Flujo RAG
1. Admin sube PDF a Google Drive
2. Cloud Function extrae texto
3. Se generan embeddings
4. Se guardan en Firestore
5. Inspector consulta → búsqueda semántica → respuesta Groq

---

## 📱 Funcionalidades

### App Inspector (Android)

| Módulo | Descripción |
|--------|-------------|
| Login | Google Sign In con aprobación admin |
| Chat IA | Consultas legales con RAG |
| Mensajería | Mensajes de texto y audio |
| Ubicación | GPS en tiempo real (cada 30s) |
| Notificaciones | FCM push notifications |

### Panel Admin (Web)

| Módulo | Descripción |
|--------|-------------|
| Dashboard | Estadísticas generales |
| Usuarios | Aprobar/rechazar inspectores |
| Mapa | Ver inspectores en tiempo real |
| Mensajes | Broadcast a inspectores |
| Logs | Historial de actividad |

---

## 🔑 Variables de Entorno

### Backend (Firestore Security Rules)
Ver archivo `firestore.rules`

### App Android
El archivo `google-services.json` contiene todas las credenciales.

### Panel Web
Configuración en `docs/js/firebase-config.js`

### Groq API
```env
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxx
```

---

## 📞 Soporte

- **Proyecto**: Sistema Integral Inspectores de Tránsito
- **Organización**: Municipalidad de Trelew, Chaco, Argentina
- **Desarrollado con**: Flutter, Firebase, Groq AI

---

## 📄 Licencia

Copyright © 2025 Municipalidad de Trelew. Todos los derechos reservados.

---

## 🔗 Enlaces Útiles

- [Firebase Console](https://console.firebase.google.com/project/app-inspectores-trelew-499913)
- [GitHub Repository](https://github.com/Vonwalter23/App-Inspectores)
- [Panel Admin](https://vonwalter23.github.io/App-Inspectores/)
- [Groq API](https://console.groq.com/)
