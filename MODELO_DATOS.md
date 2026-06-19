# MODELO DE DATOS - FIRESTORE
## Sistema Integral para Inspectores de Tránsito de Trelew

---

## 1. COLECCIÓN: `users`

### Descripción
Almacena la información de todos los usuarios del sistema (inspectores y administradores).

### Estructura del Documento

```typescript
// users/{uid}
interface User {
  // Identificación
  uid: string;                    // Firebase Auth UID (PK)
  email: string;                  // Email de Google
  emailVerified: boolean;         // Email verificado
  
  // Datos Personales
  nombre: string;                 // Nombre completo
  apellido: string;               // Apellido
  credencial: string;             // Número de credencial (4 cifras)
  fotoUrl?: string;               // URL de foto de perfil (opcional)
  
  // Estados y Roles
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  rol: 'inspector' | 'admin';
  
  // Notificaciones
  fcmToken?: string;              // Token de Firebase Cloud Messaging
  
  // Metadatos
  fechaRegistro: Timestamp;      // Cuándo se registró
  fechaActualizacion: Timestamp;  // Última modificación
  ultimoAcceso?: Timestamp;       // Último login
}

// Índices Compuestos Recomendados
// 1. users: estado ASC
// 2. users: rol ASC, estado ASC
// 3. users: credencial ASC (unique)
```

### Reglas de Seguridad

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /users/{userId} {
      // Lectura:
      // - Usuarios aprobados pueden leer su propio perfil
      // - Administradores pueden leer todos
      allow read: if 
        (request.auth != null && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.estado == 'aprobado')
        ||
        (request.auth != null && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'admin');
      
      // Escritura:
      // - Solo el propio usuario puede actualizar su perfil
      // - Solo admins pueden cambiar roles y estados
      allow write: if request.auth.uid == userId;
      
      // Admin solo puede crear usuarios o actualizar estados
      allow create: if request.auth != null;
    }
  }
}
```

---

## 2. COLECCIÓN: `ubicaciones`

### Descripción
Almacena la ubicación en tiempo real de los inspectores activos.

### Estructura del Documento

```typescript
// ubicaciones/{uid}
interface Ubicacion {
  // Identificación del Inspector
  uid: string;                    // FK a users.uid (PK)
  nombre: string;                // Nombre (duplicado para eficiencia)
  apellido: string;               // Apellido
  credencial: string;             // Número de credencial
  
  // Coordenadas
  latitud: number;                // Latitud GPS (-43.2489 para Trelew)
  longitud: number;               // Longitud GPS (-65.3050 para Trelew)
  
  // Estado
  activo: boolean;               // Si está transmitiendo
  precision: number;              // Precisión GPS en metros
  
  // Timestamps
  timestamp: Timestamp;           // Última actualización GPS
  ultimaActividad?: Timestamp;    // Última interacción con la app
}

// Índices Compuestos
// 1. ubicaciones: activo ASC, timestamp DESC
```

### Reglas de Seguridad

```javascript
match /ubicaciones/{userId} {
  // Lectura:
  // - Solo usuarios aprobados pueden ver ubicaciones
  // - Inspectores solo ven a otros inspectores (no a admins)
  allow read: if isApprovedInspector();
  
  // Escritura:
  // - Solo el propio usuario puede actualizar su ubicación
  allow write: if request.auth.uid == userId && isApprovedUser();
}
```

---

## 3. COLECCIÓN: `mensajes`

### Descripción
Almacena todos los mensajes del canal interno.

### Estructura del Documento

```typescript
// mensajes/{mensajeId}
interface Mensaje {
  // Identificación
  mensajeId: string;             // Auto-generado (PK)
  
  // Remitente
  remitenteId: string;            // FK a users.uid
  remitenteNombre: string;        // Nombre completo
  remitenteCredencial: string;    // Para mostrar en mensaje
  
  // Contenido
  contenido: string;             // Texto del mensaje (máx 2000 chars)
  tipo: 'texto' | 'audio';       // Tipo de mensaje
  audioUrl?: string;             // URL del audio en Storage (si tipo='audio')
  audioDuracion?: number;        // Duración en segundos (máx 30)
  
  // Menciones
  mencion: string[];              // Array de menciones @usuario o @todos
  mencionUsuarios: string[];     // UIDs mencionados (para notificaciones)
  
  // Estado
  leidoPor: string[];             // UIDs de quienes leyeron el mensaje
  
  // Metadatos
  timestamp: Timestamp;           // Hora de envío
  editando: boolean;             // Si está siendo editado
  eliminado: boolean;            // Soft delete
}

// Sub-colección para respuestas/hilos
// mensajes/{mensajeId}/respuestas/{respuestaId}
interface Respuesta {
  respuestaId: string;
  autorId: string;
  autorNombre: string;
  contenido: string;
  timestamp: Timestamp;
}

// Índices Compuestos
// 1. mensajes: timestamp DESC
// 2. mensajes: remitenteId ASC, timestamp DESC
// 3. mensajes: mencion ASC, timestamp DESC
```

### Reglas de Seguridad

```javascript
match /mensajes/{mensajeId} {
  // Todos los usuarios aprobados pueden leer mensajes
  allow read: if isApprovedUser();
  
  // Solo usuarios aprobados pueden crear mensajes
  allow create: if isApprovedInspector() && 
                request.resource.data.remitenteId == request.auth.uid;
  
  // Solo el autor puede editar/eliminar
  allow update, delete: if request.auth.uid == resource.data.remitenteId;
}
```

---

## 4. COLECCIÓN: `documentos`

### Descripción
Índice de documentos legales (leyes, ordenanzas, resoluciones).

### Estructura del Documento

```typescript
// documentos/{documentoId}
interface Documento {
  // Identificación
  documentoId: string;           // Auto-generado (PK)
  
  // Información del Documento
  nombre: string;                // Título del documento
  tipo: 'ley' | 'ordenanza' | 'resolucion' | 'reglamento';
  categoria?: string;           // Ej: "Tránsito", "Estacionamiento"
  numero?: string;               // Ej: "Ordenanza 1234/2024"
  
  // Archivo
  driveFileId: string;           // ID del archivo en Google Drive
  driveFileUrl: string;          // URL para visualizar
  nombreOriginal: string;         // Nombre del archivo PDF original
  tamanhoBytes: number;          // Tamaño del archivo
  hashMd5?: string;              // Para verificar integridad
  
  // Indexación RAG
  estado: 'pendiente' | 'indexando' | 'indexado' | 'error';
  totalFragmentos: number;       // Cantidad de chunks indexados
  ultimIndice?: Timestamp;        // Última indexación
  
  // Metadatos
  subidoPor: string;             // UID del admin que subió
  fechaCarga: Timestamp;          // Cuándo se subió
  fechaActualizacion?: Timestamp;
  observaciones?: string;        // Notas del admin
  
  // Fragmentos (sub-colección para RAG)
  fragmentos: {
    [fragmentoId: string]: {
      texto: string;             // Texto del fragmento (500 chars)
      pagina: number;             // Página donde aparece
      inicioChar: number;        // Posición inicial en documento
      embedding?: number[];       // Vector de embedding
    }
  };
}

// Índices Compuestos
// 1. documentos: tipo ASC, nombre ASC
// 2. documentos: estado ASC
// 3. documentos: fechaCarga DESC
```

### Reglas de Seguridad

```javascript
match /documentos/{documentoId} {
  // Solo admins pueden escribir
  allow read: if isApprovedUser();
  
  // Solo admins pueden crear/modificar/eliminar
  allow write: if isAdmin();
}
```

---

## 5. COLECCIÓN: `logs`

### Descripción
Registro de actividad del sistema para auditoría.

### Estructura del Documento

```typescript
// logs/{logId}
interface Log {
  // Identificación
  logId: string;                 // Auto-generado (PK)
  
  // Acción
  accion: string;                // Ej: "login", "logout", "mensaje_enviado"
  tipo: 'auth' | 'mensaje' | 'documento' | 'sistema' | 'ubicacion';
  
  // Usuario
  usuarioId: string;             // FK a users.uid
  usuarioNombre: string;         // Nombre para display
  
  // Detalles
  detalles: string;              // Descripción textual
  datosAdicionales?: Map<string, any>;  // Datos estructurados
  
  // Contexto
  ip?: string;                   // Dirección IP (si aplica)
  dispositivo?: string;          // Tipo de dispositivo
  appVersion?: string;           // Versión de la app
  
  // Timestamp
  timestamp: Timestamp;         // Hora del evento
}

// Índices Compuestos
// 1. logs: timestamp DESC
// 2. logs: usuarioId ASC, timestamp DESC
// 3. logs: tipo ASC, timestamp DESC
```

### Reglas de Seguridad

```javascript
match /logs/{logId} {
  // Solo admins pueden leer logs
  allow read: if isAdmin();
  
  // Cloud Functions crean logs automáticamente
  allow create: if false; // Solo desde Functions con service account
}
```

---

## 6. COLECCIÓN: `requests`

### Descripción
Solicitudes de acceso pendientes de aprobación.

### Estructura del Documento

```typescript
// requests/{requestId}
interface Request {
  // Identificación
  requestId: string;            // Auto-generado (PK)
  
  // Datos del Solicitante
  uid: string;                   // Firebase Auth UID
  email: string;                 // Email de Google
  nombre: string;                 // Nombre
  apellido: string;              // Apellido
  credencial: string;             // Número de credencial
  
  // Estado
  estado: 'pendiente' | 'aprobado' | 'rechazado';
  
  // Respuesta Admin
  adminId?: string;              // UID del admin que respondió
  adminNombre?: string;          // Nombre del admin
  respuestaMotivo?: string;      // Razón del rechazo (opcional)
  adminResponse?: Timestamp;     // Cuándo se respondió
  
  // Metadatos
  timestamp: Timestamp;          // Cuándo se creó la solicitud
  ip?: string;                  // IP del solicitante
}

// Índices Compuestos
// 1. requests: estado ASC, timestamp DESC
// 2. requests: uid ASC (unique)
```

### Reglas de Seguridad

```javascript
match /requests/{requestId} {
  // Usuarios aprobados pueden leer solicitudes pendientes
  allow read: if isApprovedUser();
  
  // Cloud Function crea la request al registrarse
  allow create: if false;
  
  // Solo admins pueden actualizar (aprobar/rechazar)
  allow update: if isAdmin();
  
  // Nadie puede eliminar requests (historial)
  allow delete: if false;
}
```

---

## 7. COLECCIÓN: `config`

### Descripción
Configuración general del sistema.

### Estructura del Documento

```typescript
// config/{configId}
interface Config {
  configId: string;              // Ej: "app_config"
  
  // App
  appVersion: string;            // Versión actual requerida
  appVersionMinima: string;      // Versión mínima soportada
  
  // Geolocalización
  ubicacionCentro: {
    latitud: number;
    longitud: number;
  };
  ubicacionRadioKm: number;      // Radio de cobertura en km (3km)
  
  // Chat IA
  ragMaxChunks: number;          // Fragmentos a recuperar (default: 5)
  ragChunkSize: number;          // Tamaño de chunk en caracteres (default: 500)
  ragModel: string;              // Modelo Groq a usar
  
  // Mensajería
  audioMaxDuracionSegundos: number;  // Máximo 30
  
  // Notificaciones
  notificarMenciones: boolean;
  notificarTodos: boolean;
  
  // Timestamps
  fechaActualizacion: Timestamp;
}

// Documento: config/app_config
const defaultConfig = {
  appVersion: "1.0.0",
  appVersionMinima: "1.0.0",
  ubicacionCentro: { latitud: -43.2489, longitud: -65.3050 },
  ubicacionRadioKm: 3,
  ragMaxChunks: 5,
  ragChunkSize: 500,
  ragModel: "llama-3.1-8b-instant",
  audioMaxDuracionSegundos: 30,
  notificarMenciones: true,
  notificarTodos: true
};
```

### Reglas de Seguridad

```javascript
match /config/{configId} {
  // Todos los usuarios aprobados pueden leer configuración
  allow read: if isApprovedUser();
  
  // Solo admins pueden escribir configuración
  allow write: if isAdmin();
}
```

---

## 8. FUNCIONES HELPER PARA REGLAS

```javascript
// Firestore Rules - Helper Functions
function isAuthenticated() {
  return request.auth != null;
}

function isApprovedUser() {
  return isAuthenticated() && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.estado == 'aprobado';
}

function isInspector() {
  return isApprovedUser() && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'inspector';
}

function isAdmin() {
  return isAuthenticated() && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'admin';
}

function isApprovedInspector() {
  return isInspector();
}

function isOwnData(userId) {
  return request.auth.uid == userId;
}

function isValidEmail(email) {
  return email.matches('.*@.*\\..*');
}

function isValidCredencial(credencial) {
  return credencial.matches('[0-9]{4}');
}
```

---

## 9. ÍNDICES COMPUESTOS (Firestore)

### Crear estos índices en Firestore:

```
# Para consultas de usuarios
Colección: users
Índice: estado ASC, fechaRegistro DESC

# Para consultas de ubicación
Colección: ubicaciones  
Índice: activo ASC, timestamp DESC

# Para consultas de mensajes
Colección: mensajes
Índice: timestamp DESC
Índice: mencion ASC, timestamp DESC

# Para consultas de documentos
Colección: documentos
Índice: tipo ASC, nombre ASC
Índice: estado ASC, fechaCarga DESC

# Para consultas de logs
Colección: logs
Índice: tipo ASC, timestamp DESC
Índice: usuarioId ASC, timestamp DESC

# Para consultas de requests
Colección: requests
Índice: estado ASC, timestamp DESC
```

---

## 10. ESTRUCTURA DE STORAGE (Firebase Storage)

```
storage/
├── audio/
│   ├── {uid}/
│   │   ├── {timestamp}.m4a       // Mensajes de audio
│   │   └── {timestamp}.m4a
│
├── profiles/
│   └── {uid}/
│       └── foto.jpg               // Fotos de perfil
│
└── documentos/
    └── temporal/
        └── {uploadId}.pdf        // PDF temporal antes de subir a Drive
```

---

## 11. REGLAS DE STORAGE

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Audio messages
    match /audio/{userId}/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId
        && request.resource.size < 1MB  // ~30 segundos de audio
        && request.resource.contentType == 'audio/mp4';
    }
    
    // Profile photos
    match /profiles/{userId}/{filename} {
      allow read: if true;
      allow write: if request.auth.uid == userId
        && request.resource.size < 5MB
        && request.resource.contentType.matches('image/.*');
    }
    
    // Documentos temporales
    match /documentos/temporal/{filename} {
      allow write: if isAdmin()
        && request.resource.size < 10MB
        && request.resource.contentType == 'application/pdf';
    }
  }
}
```

---

*Documento creado: 2025*
*Versión: 1.0*
