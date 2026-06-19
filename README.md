# 🚔 Sistema Integral para Inspectores de Tránsito de Trelew

![Flutter](https://img.shields.io/badge/Flutter-3.16-blue)
![Firebase](https://img.shields.io/badge/Firebase-10.7-orange)
![Dart](https://img.shields.io/badge/Dart-3.2-blue)

Sistema completo para la gestión de inspectores de tránsito de la Municipalidad de Trelew, Chubut. Incluye aplicación móvil Android y panel administrativo web.

## 📋 Índice

- [Descripción](#-descripción)
- [Tecnologías](#-tecnologías)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Configuración](#-configuración)
- [Instalación](#-instalación)
- [Despliegue](#-despliegue)
- [API Keys Requeridas](#-api-keys-requeridas)
- [Funcionalidades](#-funcionalidades)
- [Modelo de Datos](#-modelo-de-datos)
- [Seguridad](#-seguridad)
- [Costos Estimados](#-costos-estimados)
- [Licencia](#-licencia)

---

## 📖 Descripción

Este proyecto proporciona una plataforma integral para los inspectores de tránsito de Trelew, incluyendo:

- **Aplicación Android**: Para que los inspectores realicen su trabajo diario
- **Panel Web Admin**: Para que los administradores gestionen usuarios, documentos y monitoreen ubicaciones

### Roles del Sistema

| Rol | Aplicación | Permisos |
|-----|------------|----------|
| **Inspector** | Android | Login, Chat IA, Mensajería, Geolocalización |
| **Administrador** | Web | Gestión de usuarios, Documentos, Mapa en tiempo real, Logs |

---

## 🛠 Tecnologías

### Aplicación Móvil (Flutter)
- Flutter 3.16+
- Dart 3.2+
- Material Design 3
- Firebase SDK

### Panel Web
- HTML5, CSS3, JavaScript
- Firebase Web SDK
- Google Maps JavaScript API

### Backend (Firebase)
- Firebase Authentication
- Cloud Firestore
- Cloud Functions (Node.js)
- Firebase Cloud Messaging
- Firebase Storage
- Firebase Hosting

### Servicios Externos
- Google Sign In
- Google Drive API
- Google Maps API
- Groq API (IA)

---

## 📁 Estructura del Proyecto

```
sistema-inspectores-trelew/
├── app_inspectores/           # Aplicación Android (Flutter)
│   ├── lib/
│   │   ├── main.dart         # Punto de entrada
│   │   └── src/
│   │       ├── auth/         # Páginas de autenticación
│   │       ├── home/         # Página principal
│   │       ├── chat/         # Chat con IA
│   │       ├── mensajeria/    # Sistema de mensajería
│   │       ├── widgets/       # Componentes reutilizables
│   │       ├── services/     # Servicios (ubicación, chat, etc.)
│   │       └── theme/        # Tema de la aplicación
│   ├── android/              # Configuración Android
│   └── pubspec.yaml         # Dependencias Flutter
│
├── panel_admin/              # Panel Web Administrativo
│   ├── public/
│   │   ├── index.html       # Página principal
│   │   ├── css/
│   │   │   └── styles.css   # Estilos
│   │   └── js/
│   │       ├── firebase-config.js
│   │       └── app.js       # Lógica principal
│   └── functions/           # Cloud Functions
│       ├── package.json
│       └── src/
│           └── index.ts     # Funciones serverless
│
├── firebase.json             # Configuración Firebase
├── firestore.rules          # Reglas de seguridad
└── README.md                # Este archivo
```

---

## ⚙ Configuración

### 1. Configuración de Firebase

#### Crear Proyecto Firebase
1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto: `app-inspectores-trelew`
3. Habilitar **Authentication** → Google Sign In
4. Crear **Firestore Database** (modo nativo, región: southamerica-east1)
5. Habilitar **Cloud Messaging**

#### Registrar Apps

**App Android:**
1. Agregar app Android
2. Package name: `com.municipalidad.trelew.inspectores`
3. Descargar `google-services.json`
4. Colocar en `app_inspectores/android/app/`

**App Web:**
1. Agregar app Web
2. Copiar configuración de Firebase

### 2. Configuración de Google Cloud Console

#### Habilitar APIs
1. Ir a [Google Cloud Console](https://console.cloud.google.com/)
2. Seleccionar proyecto
3. Ir a API y servicios → Biblioteca
4. Habilitar:
   - Google Drive API
   - Google Maps JavaScript API
   - Google People API

#### Crear OAuth 2.0
1. Ir a API y servicios → Credenciales
2. Crear ID de cliente OAuth
3. Tipo: Aplicación web
4. Agregar URI de redireccionamiento:
   ```
   https://app-inspectores-trelew.firebaseapp.com/__/auth/handler
   ```

#### Crear API Key
1. API y servicios → Credenciales → Crear credenciales → Clave de API
2. Restringir a Google Maps JavaScript API

### 3. Configuración de Groq API

1. Crear cuenta en [Groq Console](https://console.groq.com/)
2. Generar API Key
3. Guardar para usar en Cloud Functions

---

## 📦 Instalación

### Aplicación Android (Flutter)

```bash
# 1. Navegar al directorio de la app
cd app_inspectores

# 2. Instalar dependencias
flutter pub get

# 3. Colocar google-services.json
# Copiar el archivo descargado a:
# app_inspectores/android/app/google-services.json

# 4. Compilar APK debug
flutter build apk --debug

# 5. Compilar APK release (requiere signing)
flutter build apk --release
```

### Panel Web Admin

```bash
# 1. Navegar al directorio
cd panel_admin

# 2. Instalar Firebase CLI
npm install -g firebase-tools

# 3. Login en Firebase
firebase login

# 4. Inicializar proyecto (si no está inicializado)
firebase init

# 5. Seleccionar:
#    - Hosting
#    - Functions
#    - Firestore

# 6. Desplegar
firebase deploy
```

### Cloud Functions

```bash
# 1. Navegar a functions
cd panel_admin/functions

# 2. Instalar dependencias
npm install

# 3. Compilar TypeScript
npm run build

# 4. Desplegar solo functions
firebase deploy --only functions
```

---

## 🚀 Despliegue

### Despliegue Completo

```bash
# Login en Firebase
firebase login

# Seleccionar proyecto
firebase use app-inspectores-trelew

# Desplegar todo
firebase deploy
```

### Despliegue Individual

```bash
# Solo hosting (panel web)
firebase deploy --only hosting

# Solo functions
firebase deploy --only functions

# Solo firestore rules
firebase deploy --only firestore:rules
```

---

## 🔑 API Keys Requeridas

### Variables de Entorno

Crear archivo `.env` en `panel_admin/functions/`:

```env
GROQ_API_KEY=tu_api_key_de_groq
DRIVE_FOLDER_ID=id_de_carpeta_drive
```

### Firebase Configuration

Obtener de Firebase Console → Project Settings → Your apps

```javascript
const firebaseConfig = {
  apiKey: "TU_API_KEY",
  authDomain: "app-inspectores-trelew.firebaseapp.com",
  databaseURL: "https://app-inspectores-trelew-default-rtdb.firebaseio.com",
  projectId: "app-inspectores-trelew",
  storageBucket: "app-inspectores-trelew.firebasestorage.app",
  messagingSenderId: "TU_SENDER_ID",
  appId: "TU_APP_ID"
};
```

---

## ✨ Funcionalidades

### Aplicación Móvil (Inspector)

| Función | Descripción |
|---------|-------------|
| 🔐 Login con Google | Autenticación mediante Google Sign In |
| ⏳ Pantalla de Espera | Indica estado de la solicitud de acceso |
| 🤖 Asistente Legal IA | Consulta normas usando RAG con Groq |
| 💬 Mensajería Interna | Canal de comunicación entre inspectores |
| 🎤 Mensajes de Audio | Envío de mensajes de voz (máx. 30 seg) |
| 📍 Geolocalización | Ubicación en tiempo real (actualiza cada 30 seg) |
| 🔔 Notificaciones | Alertas por menciones y mensajes |
| 🌙 Modo Oscuro | Soporte para tema oscuro |

### Panel Web (Administrador)

| Función | Descripción |
|---------|-------------|
| 📊 Dashboard | Estadísticas y actividad reciente |
| 👥 Gestión de Usuarios | Aprobar/rechazar inspectores |
| 📄 Gestión Documental | Subir, indexar y eliminar PDFs |
| 🗺️ Mapa en Vivo | Ubicaciones en tiempo real |
| 📜 Logs | Registro de actividad del sistema |

---

## 🗄️ Modelo de Datos

### Colecciones Firestore

```
users/{uid}
├── email: string
├── nombre: string
├── apellido: string
├── credencial: string
├── estado: "pendiente" | "aprobado" | "rechazado"
├── rol: "inspector" | "admin"
├── fechaRegistro: timestamp
└── fcmToken: string

ubicaciones/{uid}
├── latitud: number
├── longitud: number
├── timestamp: timestamp
├── nombre: string
├── apellido: string
├── credencial: string
└── activo: boolean

mensajes/{mensajeId}
├── remitenteId: string
├── remitenteNombre: string
├── contenido: string
├── tipo: "texto" | "audio"
├── audioUrl: string (opcional)
├── mencion: string[]
├── leidoPor: string[]
└── timestamp: timestamp

documentos/{documentoId}
├── nombre: string
├── tipo: "ley" | "ordenanza" | "resolucion"
├── driveFileId: string
├── driveFileUrl: string
├── estado: "pendiente" | "indexando" | "indexado" | "error"
├── totalFragmentos: number
└── fragmentos: Map<string, Fragmento>

logs/{logId}
├── accion: string
├── tipo: "auth" | "mensaje" | "documento" | "sistema"
├── usuarioId: string
├── usuarioNombre: string
├── detalles: string
└── timestamp: timestamp

requests/{uid}
├── uid: string
├── email: string
├── nombre: string
├── apellido: string
├── credencial: string
├── estado: "pendiente" | "aprobado" | "rechazado"
└── timestamp: timestamp
```

---

## 🔒 Seguridad

### Firestore Security Rules

El sistema implementa las siguientes reglas de seguridad:

- **Mínimo Privilegio**: Cada rol tiene acceso solo a lo necesario
- **Validación de Estado**: Solo usuarios "aprobado" pueden acceder
- **Separación de Roles**: Inspectores vs Administradores
- **Validación de Datos**: Tipos y rangos verificados

### Reglas Principales

```javascript
// Solo admins pueden ver logs
allow read: if isAdmin();

// Solo inspectores aprobados pueden crear mensajes
allow create: if isInspector();

// Usuarios solo pueden modificar su propia ubicación
allow write: if isOwnData(userId);
```

### Almacenamiento Seguro

- Tokens FCM almacenados de forma segura
- Archivos de audio en Firebase Storage (privado)
- Documentos en Google Drive (carpeta compartida)

---

## 💰 Costos Estimados

### Firebase (Spark Plan - Free)

| Servicio | Límite Free | Uso Estimado |
|----------|-------------|--------------|
| Authentication | Ilimitado | ✅ |
| Firestore | 1GB storage, 50K reads/day | ✅ Dentro de límite |
| Storage | 5GB | ✅ Dentro de límite |
| Cloud Functions | 2M invocaciones/mes | ✅ Dentro de límite |
| Hosting | 10GB | ✅ Dentro de límite |
| Cloud Messaging | Ilimitado | ✅ |

### Groq API (Free Tier)

- 30 requests/minuto
- 14,400 requests/día
- **Suficiente para 60 inspectores** con consultas normales

### Google Maps API

- 28,000 map loads/mes (gratis)
- Excess: $7/1000 loads
- **Costo estimado**: $0-5/mes

### 💵 Costo Total Estimado: **$0-5/mes**

---

## 🚦 Flujo de Autenticación

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ INSPECTOR│────▶│  GOOGLE │────▶│FIREBASE │
│  LOGIN   │     │  SIGN   │     │  AUTH    │
└──────────┘     └──────────┘     └────┬─────┘
                                       │
                          ┌────────────┴────────────┐
                          │ Check users collection   │
                          └────────────┬────────────┘
                                       │
                          ┌────────────┴────────────┐
                          │                         │
                          ▼                         ▼
                   ┌─────────────┐           ┌─────────────┐
                   │   EXISTE?   │           │  NEW USER   │
                   └──────┬──────┘           └──────┬──────┘
                          │                         │
                          ▼                         ▼
                   ┌─────────────┐           ┌─────────────┐
                   │CHECK STATUS │           │CREATE REQUEST│
                   └──────┬──────┘           │  (pending)  │
                          │                   └─────────────┘
               ┌──────────┴──────────┐
               │                     │
               ▼                     ▼
        ┌───────────┐          ┌───────────┐
        │ APPROVED? │          │  WAITING  │
        └─────┬─────┘          │   SCREEN  │
              │                 └───────────┘
              ▼
        ┌───────────┐
        │   HOME    │
        │   PAGE    │
        └───────────┘
```

---

## 📱 Capturas de Pantalla

*(Agregar capturas del app y panel web)*

---

## 🐛 Solución de Problemas

### Error: "No Firebase App has been created"
```bash
# Asegúrate de que google-services.json está en:
app_inspectores/android/app/google-services.json
```

### Error: "Location permissions denied"
- Verificar que los permisos estén en AndroidManifest.xml
- El usuario debe aceptar los permisos de ubicación

### Error: "API key not valid"
- Verificar que la API key de Google Maps esté correcta
- Verificar restricciones de la API key en Google Cloud Console

---

## 📞 Soporte

Para soporte técnico:
- 📧 Email: soporte@trelew.gob.ar
- 📞 Teléfono: 0800-XXX-XXXX
- 🕐 Horario: Lunes a Viernes 8:00 - 14:00

---

## 📄 Licencia

Este proyecto es propiedad de la **Municipalidad de Trelew**.

Todos los derechos reservados © 2024-2025

---

## 👥 Créditos

Desarrollado para la **Municipalidad de Trelew, Chubut, Argentina**.

- **Arquitecto**: OpenHands AI Agent
- **Tecnología**: Flutter + Firebase + Groq API

---

*Este README fue generado como parte del proyecto Sistema Inspectores Trelew*
