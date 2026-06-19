# ARQUITECTURA TÉCNICA
## Sistema Integral para Inspectores de Tránsito de Trelew

---

## 1. VISIÓN GENERAL DEL SISTEMA

### 1.1 Componentes Principales

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SISTEMA INSPECTORES TRELEW                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────────────┐          ┌──────────────────────┐              │
│   │   APP ANDROID (APK)  │          │   PANEL WEB ADMIN    │              │
│   │                       │          │                       │              │
│   │  • Login Google       │          │  • Dashboard         │              │
│   │  • Chat IA Legal      │          │  • Gestión Usuarios  │              │
│   │  • Mensajería         │          │  • Gestión Docs      │              │
│   │  • Geolocalización    │          │  • Mapa Tiem. Real   │              │
│   │  • Notificaciones FCM │          │  • Logs              │              │
│   └───────────┬──────────┘          └───────────┬──────────┘              │
│               │                                   │                          │
│               │         FIREBASE BACKEND           │                          │
│               │                                   │                          │
│               ▼                                   ▼                          │
│   ┌──────────────────────────────────────────────────────────┐              │
│   │                                                           │              │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │              │
│   │  │ Authentication│  │  Firestore   │  │ Cloud Functions │ │              │
│   │  │  (Google)     │  │  Database    │  │                 │ │              │
│   │  └─────────────┘  └─────────────┘  └─────────────────┘ │              │
│   │                                                           │              │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │              │
│   │  │Cloud Messaging│  │   Storage    │  │   Hosting       │ │              │
│   │  │  (FCM)       │  │              │  │   (Web Admin)   │ │              │
│   │  └─────────────┘  └─────────────┘  └─────────────────┘ │              │
│   │                                                           │              │
│   └───────────────────────────────────────────────────────────┘              │
│                                       │                                      │
│                    ┌──────────────────┼──────────────────┐                   │
│                    │                  │                  │                   │
│                    ▼                  ▼                  ▼                   │
│            ┌───────────────┐  ┌───────────────┐  ┌───────────────┐         │
│            │  Google Drive  │  │   Groq API     │  │ Google Maps   │         │
│            │  (Documentos)  │  │  (Chat IA)     │  │    API        │         │
│            └───────────────┘  └───────────────┘  └───────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. ARQUITECTURA DE LA APLICACIÓN MÓVIL (FLUTTER)

### 2.1 Estructura de Capas

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                   │
│  (Widgets, Pages, UI Components)                        │
│  • LoginPage, HomePage, ChatPage, MensajesPage, etc.  │
├─────────────────────────────────────────────────────────┤
│                    BUSINESS LOGIC LAYER                  │
│  (Services, BLoC/Cubit State Management)                │
│  • AuthService, ChatService, LocationService, etc.     │
├─────────────────────────────────────────────────────────┤
│                    DATA LAYER                           │
│  (Repositories, Firebase, Local Storage)                 │
│  • UserRepository, MensajeRepository, etc.              │
├─────────────────────────────────────────────────────────┤
│                    EXTERNAL SERVICES                    │
│  (Firebase, Google Sign-In, Groq API)                   │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Flujo de Pantallas

```
                    ┌──────────────┐
                    │   SPLASH     │
                    │   SCREEN     │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  LOGIN PAGE  │◄─────────────────┐
                    │  (Google)    │                  │
                    └──────┬───────┘                  │
                           │                           │
              ┌────────────┼────────────┐              │
              │            │            │              │
              ▼            │            ▼              │
     ┌──────────────┐      │     ┌──────────────┐      │
     │   PENDING    │      │     │    HOME     │      │
     │    PAGE      │      │     │   PAGE      │      │
     │  (Waiting)   │      │     │             │      │
     └──────────────┘      │     └──────┬───────┘      │
                            │            │              │
                            │     ┌──────┴───────┐      │
                            │     │              │      │
                            │     ▼              ▼      │
                            │ ┌────────┐  ┌───────────┐ │
                            │ │ CHAT   │  │  MENSAJES │ │
                            │ │  IA    │  │  PAGE     │ │
                            │ │ PAGE   │  │           │ │
                            │ └────────┘  └───────────┘ │
                            │                           │
                            │            ┌───────────────┤
                            │            │    PERFIL     │
                            │            │    PAGE      │
                            │            └───────────────┘
                            │
                            └──────────────────────────┘
```

---

## 3. ARQUITECTURA DEL PANEL WEB ADMIN

### 3.1 Estructura de Páginas

```
┌─────────────────────────────────────────────────────────────────┐
│                        PANEL ADMIN WEB                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    SIDEBAR / NAVBAR                       │  │
│  │  Logo | Dashboard | Usuarios | Documentos | Mapa | Logs  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                                                           │  │
│  │                    CONTENT AREA                           │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              DASHBOARD / CONTENT                     │  │  │
│  │  │                                                       │  │  │
│  │  │  • Stats Cards                                       │  │  │
│  │  │  • User List                                        │  │  │
│  │  │  • Document Upload                                 │  │  │
│  │  │  • Google Maps with Markers                        │  │  │
│  │  │  • Activity Logs Table                             │  │  │
│  │  │                                                       │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. ARQUITECTURA DEL BACKEND (FIREBASE)

### 4.1 Firebase Cloud Functions

```
┌─────────────────────────────────────────────────────────────┐
│                   CLOUD FUNCTIONS                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐         │
│  │   HTTP FUNCTIONS     │  │   FIRESTORE TRIGGERS │         │
│  │                      │  │                       │         │
│  │  • /api/upload-doc   │  │  • onUserCreate      │         │
│  │  • /api/query-ai     │  │  • onMensajeCreate   │         │
│  │  • /api/delete-doc   │  │  • onLocationUpdate  │         │
│  │  • /api/send-notif   │  │  • onDocUpload      │         │
│  └──────────────────────┘  └──────────────────────┘         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │                    SCHEDULED FUNCTIONS                │    │
│  │  • cleanupOldLocations (cada 1 hora)                  │    │
│  │  • sendDailyDigest (diario 8am)                      │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 Flujo de Indexación RAG

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA RAG (RAG Pipeline)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ADMIN SUBE PDF                                                      │
│         │                                                           │
│         ▼                                                           │
│   ┌─────────────┐                                                   │
│   │  Cloud     │                                                    │
│   │  Function  │                                                    │
│   │  /upload   │                                                    │
│   └──────┬─────┘                                                   │
│          │                                                         │
│          ▼                                                         │
│   ┌─────────────┐      ┌─────────────┐                             │
│   │  Google    │ ───► │  Extract   │                              │
│   │  Drive     │      │   Text     │                              │
│   │  Upload    │      │  (PDF.js)  │                              │
│   └─────────────┘      └──────┬─────┘                             │
│                               │                                    │
│                               ▼                                    │
│                        ┌─────────────┐                             │
│                        │  Chunking  │                              │
│                        │  (500 chars│                              │
│                        │  Overlap)  │                              │
│                        └──────┬─────┘                              │
│                               │                                    │
│                               ▼                                    │
│                        ┌─────────────┐                             │
│                        │ Generate   │                              │
│                        │ Embeddings │                              │
│                        │ (Groq API) │                              │
│                        └──────┬─────┘                              │
│                               │                                    │
│                               ▼                                    │
│                        ┌─────────────┐                             │
│                        │  Store in  │                              │
│                        │ Firestore  │                              │
│                        │ (vector    │                              │
│                        │  field)    │                              │
│                        └─────────────┘                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Flujo de Consulta RAG

```
┌─────────────────────────────────────────────────────────────────┐
│                   CONSULTA IA (RAG Query)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   USER PREGUNTA                                                  │
│         │                                                        │
│         ▼                                                        │
│   ┌─────────────┐                                                │
│   │   App       │                                                 │
│   │   Flutter   │                                                 │
│   └──────┬─────┘                                                 │
│          │                                                       │
│          ▼                                                       │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              Cloud Function: /api/query-ai              │   │
│   │                                                          │   │
│   │  1. Generate embedding of query                          │   │
│   │  2. Search Firestore for similar chunks                  │   │
│   │  3. Build context from top-k chunks                      │   │
│   │  4. Send to Groq with prompt template                    │   │
│   │  5. Return formatted response                            │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                               │                                 │
│                               ▼                                 │
│                        ┌─────────────┐                          │
│                        │   GROQ API  │                          │
│                        │  (llama-3)  │                          │
│                        └──────┬──────┘                          │
│                               │                                 │
│                               ▼                                 │
│                        ┌─────────────┐                          │
│                        │  RESPONSE   │                          │
│                        │ FORMATTED   │                          │
│                        │ WITH SOURCE │                          │
│                        └─────────────┘                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. MODELO DE DATOS (FIRESTORE)

### 5.1 Estructura de Colecciones

```
firestore/
│
├── users/
│   ├── {uid}/
│   │   ├── email: string
│   │   ├── nombre: string
│   │   ├── apellido: string
│   │   ├── credencial: string (número 4 cifras)
│   │   ├── estado: "pendiente" | "aprobado" | "rechazado"
│   │   ├── rol: "inspector" | "admin"
│   │   ├── fechaRegistro: timestamp
│   │   ├── fechaActualizacion: timestamp
│   │   └── fcmToken: string
│
├── ubicaciones/
│   ├── {uid}/
│   │   ├── latitud: number
│   │   ├── longitud: number
│   │   ├── timestamp: timestamp
│   │   ├── nombre: string
│   │   ├── apellido: string
│   │   ├── credencial: string
│   │   └── activo: boolean
│
├── mensajes/
│   ├── {mensajeId}/
│   │   ├── remitenteId: string
│   │   ├── remitenteNombre: string
│   │   ├── contenido: string
│   │   ├── tipo: "texto" | "audio"
│   │   ├── audioUrl: string (opcional)
│   │   ├── mencion: string[] (ej: ["@Juan Pérez", "@todos"])
│   │   ├── timestamp: timestamp
│   │   └── leidoPor: string[]
│
├── documentos/
│   ├── {documentoId}/
│   │   ├── nombre: string
│   │   ├── tipo: "ley" | "ordenanza" | "resolucion" | "reglamento"
│   │   ├── fechaCarga: timestamp
│   │   ├── driveFileId: string
│   │   ├── estado: "indexado" | "pendiente" | "error"
│   │   └── fragmentos/
│   │       ├── {fragmentoId}/
│   │       │   ├── texto: string
│   │       │   ├── embedding: number[] (vector)
│   │       │   └── pagina: number
│
├── logs/
│   ├── {logId}/
│   │   ├── accion: string
│   │   ├── usuarioId: string
│   │   ├── usuarioNombre: string
│   │   ├── detalles: string
│   │   ├── timestamp: timestamp
│   │   └── tipo: "auth" | "mensaje" | "documento" | "sistema"
│
└── requests/
    ├── {requestId}/
        ├── uid: string
        ├── email: string
        ├── nombre: string
        ├── apellido: string
        ├── credencial: string
        ├── estado: "pendiente" | "aprobado" | "rechazado"
        ├── timestamp: timestamp
        └── adminResponse: timestamp
```

---

## 6. SECURITY RULES (FIRESTORE)

### 6.1 Principios de Seguridad

```
┌─────────────────────────────────────────────────────────────┐
│                   SECURITY RULES PRINCIPLES                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   • Mínimo Privilegio: Solo acceso a datos necesarios       │
│   • Validación de Estado: Solo usuarios "aprobado" acceden │
│   • Separación de Roles: Inspectores vs Administradores     │
│   • Validación de Datos: Tipos y rangos verificados        │
│   • Rate Limiting: Protege contra abuso                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. CONFIGURACIÓN DE SERVICIOS

### 7.1 Firebase Services

```
┌─────────────────────────────────────────────────────────────┐
│                    SERVICIOS FIREBASE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Authentication                                             │
│   ├── Provider: Google Sign-In                              │
│   ├── UID: Google User ID                                    │
│   └── Custom Claims: rol (inspector/admin)                  │
│                                                              │
│   Firestore                                                  │
│   ├── Region: southamerica-east1 (São Paulo)                │
│   └── Mode: Native                                           │
│                                                              │
│   Storage                                                    │
│   ├── Purpose: Audio messages, profile images               │
│   └── Path: /audio/{uid}/{timestamp}.m4a                   │
│                                                              │
│   Cloud Messaging                                            │
│   ├── Topic: inspectors                                      │
│   └── Payload: { title, body, data }                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 Google APIs

```
┌─────────────────────────────────────────────────────────────┐
│                    APIS GOOGLE                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Google Drive API                                          │
│   ├── Purpose: Store legal documents (PDFs)                 │
│   ├── Folder: App Inspectores (ID: 11U5_4AceI...)         │
│   └── Scope: https://www.googleapis.com/auth/drive.file     │
│                                                              │
│   Google Maps JavaScript API                                │
│   ├── Purpose: Real-time inspector locations map            │
│   ├── Key: AIzaSyBpKbl3vRcqNRwcMm3f8qOOPGpb43qXQZE        │
│   └── Features: Markers, InfoWindows, Geocoding            │
│                                                              │
│   Groq API                                                  │
│   ├── Purpose: Legal assistant AI (RAG)                    │
│   ├── Model: llama-3.1-8b-instant                          │
│   └── Endpoint: https://api.groq.com/openai/v1             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. FLUJO DE AUTENTICACIÓN

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUJO DE AUTENTICACIÓN                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐                                                   │
│   │ INSPECTOR│                                                   │
│   │ Opens App│                                                   │
│   └────┬─────┘                                                   │
│        │                                                         │
│        ▼                                                         │
│   ┌──────────────┐                                               │
│   │ Google Sign  │                                               │
│   │    In        │                                               │
│   └──────┬───────┘                                               │
│          │                                                       │
│          ▼                                                       │
│   ┌──────────────┐                                               │
│   │ Check Users │                                               │
│   │ Collection  │                                               │
│   └──────┬───────┘                                               │
│          │                                                       │
│    ┌─────┴─────┐                                                 │
│    │           │                                                 │
│    ▼           ▼                                                 │
│ ┌──────┐  ┌─────────────┐                                        │
│ │ NEW  │  │   EXISTS   │                                        │
│ │USER  │  │             │                                        │
│ └──┬───┘  └──────┬──────┘                                        │
│    │             │                                               │
│    ▼             ▼                                               │
│ ┌────────────┐ ┌────────────┐                                   │
│ │ Create     │ │ Check      │                                   │
│ │ Request    │ │ Status     │                                   │
│ │ (pending)  │ │            │                                   │
│ └─────┬──────┘ └─────┬──────┘                                   │
│       │              │                                           │
│       │         ┌────┴─────┐                                     │
│       │         │          │                                     │
│       │         ▼          ▼                                     │
│       │    ┌────────┐ ┌────────┐                                │
│       │    │PENDING │ │APPROVED│                                │
│       │    │        │ │        │                                │
│       │    └───┬────┘ └───┬────┘                                │
│       │        │          │                                      │
│       │        ▼          ▼                                      │
│       │  ┌─────────┐ ┌─────────┐                               │
│       │  │ Wait    │ │Access   │                               │
│       │  │ Screen  │ │Granted  │                               │
│       │  └─────────┘ └─────────┘                               │
│       │                                                         │
│       └─────────────────────────────────────────────────┐       │
│                                                           │       │
│   ADMIN: Revisa requests → Aprueba/Rechaza                │       │
│                                                           │       │
│           (Firebase Function envía notificación FCM)      │       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. GEOLOCALIZACIÓN

### 9.1 Flujo de Ubicación

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUJO DE GEOLOCALIZACIÓN                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   APP START                                                      │
│       │                                                          │
│       ▼                                                          │
│   ┌──────────────┐                                               │
│   │ Start        │                                               │
│   │ Location     │                                               │
│   │ Tracking     │                                               │
│   └──────┬───────┘                                               │
│          │                                                      │
│          │ (every 30 seconds)                                   │
│          │                                                      │
│          ▼                                                      │
│   ┌──────────────┐                                               │
│   │ Get GPS      │                                               │
│   │ Position     │                                               │
│   └──────┬───────┘                                               │
│          │                                                      │
│          ▼                                                      │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ Update Firestore: /ubicaciones/{uid}                      │  │
│   │ { latitud, longitud, timestamp, nombre, activo: true }    │  │
│   └──────────────────────────────────────────────────────────┘  │
│          │                                                      │
│          │ (on app close / logout)                             │
│          │                                                      │
│          ▼                                                      │
│   ┌──────────────┐                                               │
│   │ Set activo:  │                                               │
│   │ false        │                                               │
│   └──────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. MENSAJERÍA INTERNA

### 10.1 Flujo de Mensajes

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUJO DE MENSAJERÍA                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐                                                   │
│   │ INSPECTOR│                                                   │
│   │ Type     │                                                   │
│   │ Message  │                                                   │
│   │ @Juan    │                                                   │
│   └────┬─────┘                                                   │
│        │                                                         │
│        ▼                                                         │
│   ┌──────────────┐                                               │
│   │ Parse @mentions│                                             │
│   │ Extract users │                                             │
│   │ (@todos)       │                                             │
│   └──────┬───────┘                                               │
│          │                                                       │
│          ▼                                                       │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ Save to Firestore: /mensajes/{newId}                     │  │
│   │ { remitenteId, contenido, mencion: ["@Juan"], timestamp }│  │
│   └──────────────────────────────────────────────────────────┘  │
│          │                                                       │
│          ▼                                                       │
│   ┌──────────────┐                                               │
│   │ Cloud        │                                               │
│   │ Function:    │                                               │
│   │ onMensajeCreate│                                             │
│   └──────┬───────┘                                               │
│          │                                                       │
│          ▼                                                       │
│   ┌──────────────┐                                               │
│   │ Send FCM     │                                               │
│   │ to mentioned │                                               │
│   │ users        │                                               │
│   └──────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 11. DIAGRAMA DE DEPLOYMENT

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                    GOOGLE CLOUD                          │  │
│   │                                                          │  │
│   │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │  │
│   │  │ Cloud        │  │ Cloud        │  │  Google     │  │  │
│   │  │ Functions    │  │ Scheduler    │  │  Drive      │  │  │
│   │  │              │  │              │  │             │  │  │
│   │  │ • RAG Index  │  │ • Cleanup    │  │ • Documents │  │  │
│   │  │ • AI Query   │  │ • Digest     │  │ • PDFs      │  │  │
│   │  │ • FCM Send   │  │              │  │             │  │  │
│   │  └──────────────┘  └──────────────┘  └─────────────┘  │  │
│   │                                                          │  │
│   └─────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                     FIREBASE                             │  │
│   │                                                          │  │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │  │
│   │  │Firestore │  │ Hosting  │  │ Storage  │              │  │
│   │  │          │  │ Web App  │  │ Audio    │              │  │
│   │  │• Users   │  │          │  │ Files    │              │  │
│   │  │• Messages │  │          │  │          │              │  │
│   │  │• Locations│  │          │  │          │              │  │
│   │  │• Docs Index│ │          │  │          │              │  │
│   │  └──────────┘  └──────────┘  └──────────┘              │  │
│   │                                                          │  │
│   └─────────────────────────────────────────────────────────┘  │
│                              │                                  │
│          ┌───────────────────┴───────────────────┐              │
│          │                                       │              │
│          ▼                                       ▼              │
│   ┌──────────────────┐                ┌──────────────────┐      │
│   │  ANDROID APPS    │                │   WEB BROWSER    │      │
│   │                  │                │                  │      │
│   │ • Inspector App │                │ • Admin Panel    │      │
│   │ • (.apk)         │                │ • Firebase Host  │      │
│   │                  │                │                  │      │
│   └──────────────────┘                └──────────────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 12. COSTOS ESTIMADOS (FREE TIER)

```
┌─────────────────────────────────────────────────────────────┐
│                    COSTOS ESTIMADOS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Firebase (Spark Plan - Free)                             │
│   ├── Authentication: ILIMITADO ✅                          │
│   ├── Firestore: 1GB storage, 50K reads/day ✅               │
│   ├── Storage: 5GB ✅                                        │
│   ├── Cloud Functions: 2M invocations/month ✅               │
│   ├── Hosting: 10GB ✅                                       │
│   └── Cloud Messaging: ILIMITADO ✅                          │
│                                                              │
│   Groq API (Free Tier)                                      │
│   ├── 30 requests/minute                                     │
│   └── 14,400 requests/day (suficiente para 60 inspectores)  │
│                                                              │
│   Google Maps API                                           │
│   ├── 28,000 map loads/month (free)                        │
│   └── Excess: $7/1000 loads                                 │
│                                                              │
│   💰 COSTO TOTAL ESTIMADO: $0-5/mes                         │
│      (dentro de límites free tier con 60 inspectores)      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 13. VERSIONES Y DEPENDENCIAS

```
┌─────────────────────────────────────────────────────────────┐
│                    VERSIONES MÍNIMAS                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Flutter SDK: 3.16.0+                                     │
│   Dart: 3.2.0+                                              │
│                                                              │
│   Key Dependencies (Flutter):                               │
│   ├── firebase_core: ^2.24.0                               │
│   ├── firebase_auth: ^4.16.0                               │
│   ├── cloud_firestore: ^4.14.0                             │
│   ├── firebase_messaging: ^14.7.0                          │
│   ├── google_sign_in: ^6.2.0                               │
│   ├── geolocator: ^11.0.0                                  │
│   ├── permission_handler: ^11.3.0                           │
│   ├── http: ^1.2.0                                          │
│   └── flutter_sound: ^9.2.0                                │
│                                                              │
│   Node.js (Cloud Functions): 18+                           │
│   ├── firebase-admin: ^12.0.0                             │
│   ├── googleapis: ^130.0.0                                 │
│   └── pdf-parse: ^1.1.0                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

*Documento creado: 2025*
*Versión: 1.0*
