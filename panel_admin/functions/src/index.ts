import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { google } from 'googleapis';
import axios from 'axios';

// Inicializar Firebase Admin
admin.initializeApp();

// Inicializar Firestore
const db = admin.firestore();
const messaging = admin.messaging();

// ==================== CONFIGURACIÓN ====================

// Groq API Configuration
const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_API_KEY = '${GROQ_API_KEY}';
const GROQ_MODEL = 'llama-3.1-8b-instant';

// Google Drive Configuration
const DRIVE_FOLDER_ID = '11U5_4AceI_l7cEEkEjaEk_WLUsXSi1Jz';

// ==================== HELPER FUNCTIONS ====================

/**
 * Envía notificación FCM a un usuario específico
 */
async function sendNotificationToUser(
  userId: string, 
  title: string, 
  body: string, 
  data?: Record<string, string>
) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'inspectores_channel',
          priority: 'high',
        },
      },
    });
    
    console.log(`Notification sent to ${userId}`);
  } catch (error) {
    console.error(`Error sending notification to ${userId}:`, error);
  }
}

/**
 * Envía notificación a todos los inspectores
 */
async function sendToAllInspectors(title: string, body: string, data?: Record<string, string>) {
  try {
    await messaging.send({
      topic: 'inspectores',
      notification: { title, body },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'inspectores_channel',
          priority: 'high',
        },
      },
    });
  } catch (error) {
    console.error('Error sending to topic:', error);
  }
}

// ==================== FIRESTORE TRIGGERS ====================

/**
 * Trigger cuando se crea un nuevo mensaje
 */
export const onMensajeCreated = functions.firestore
  .document('mensajes/{mensajeId}')
  .onCreate(async (snapshot, context) => {
    const mensaje = snapshot.data();
    
    if (!mensaje) return;

    const { remitenteNombre, contenido, tipo, mencion, mencionUsuarios } = mensaje;

    // Registrar en logs
    await db.collection('logs').add({
      accion: 'mensaje_enviado',
      tipo: 'mensaje',
      usuarioId: mensaje.remitenteId,
      usuarioNombre: remitenteNombre,
      detalles: `Envió un mensaje de tipo ${tipo}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Si hay menciones, notificar
    if (mencion && mencion.length > 0) {
      const title = `${remitenteNombre} te mencionó`;
      
      if (mencion.includes('@todos')) {
        // Notificar a todos los inspectores
        await sendToAllInspectors(title, contenido);
      } else if (mencionUsuarios && mencionUsuarios.length > 0) {
        // Notificar a usuarios mencionados
        for (const userId of mencionUsuarios) {
          if (userId !== mensaje.remitenteId) {
            await sendNotificationToUser(userId, title, contenido, {
              type: 'mencion',
              mensajeId: context.params.mensajeId,
            });
          }
        }
      }
    }

    return null;
  });

/**
 * Trigger cuando se actualiza la ubicación de un inspector
 */
export const onUbicacionUpdated = functions.firestore
  .document('ubicaciones/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    
    if (!newData || !newData.activo) return;

    // No hacer nada especial, la ubicación se actualiza directamente
    // Este trigger puede usarse para alertas si es necesario
    
    return null;
  });

/**
 * Trigger cuando se crea una solicitud de acceso
 */
export const onRequestCreated = functions.firestore
  .document('requests/{requestId}')
  .onCreate(async (snapshot, context) => {
    const request = snapshot.data();
    
    if (!request) return;

    // Registrar en logs
    await db.collection('logs').add({
      accion: 'solicitud_registro',
      tipo: 'auth',
      usuarioId: request.uid,
      usuarioNombre: `${request.nombre} ${request.apellido}`,
      detalles: 'Nueva solicitud de acceso pendiente',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * Trigger cuando se actualiza el estado de un usuario
 */
export const onUserStatusChanged = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (!before || !after) return;
    
    const oldStatus = before.estado;
    const newStatus = after.estado;

    // Si el estado cambió a aprobado
    if (oldStatus !== 'aprobado' && newStatus === 'aprobado') {
      // Registrar en logs
      await db.collection('logs').add({
        accion: 'usuario_aprobado',
        tipo: 'auth',
        usuarioId: context.params.userId,
        usuarioNombre: `${after.nombre} ${after.apellido}`,
        detalles: 'Usuario aprobado para acceder a la aplicación',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Notificar al usuario
      await sendNotificationToUser(
        context.params.userId,
        '¡Acceso Aprobado!',
        'Tu solicitud de acceso ha sido aprobada. Ya puedes usar la aplicación.',
        { type: 'aprobacion' }
      );

      // Eliminar de requests si existe
      await db.collection('requests').doc(context.params.userId).delete().catch(() => {});
    }

    // Si el estado cambió a rechazado
    if (oldStatus !== 'rechazado' && newStatus === 'rechazado') {
      // Registrar en logs
      await db.collection('logs').add({
        accion: 'usuario_rechazado',
        tipo: 'auth',
        usuarioId: context.params.userId,
        usuarioNombre: `${after.nombre} ${after.apellido}`,
        detalles: 'Usuario rechazado',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Notificar al usuario
      await sendNotificationToUser(
        context.params.userId,
        'Solicitud Rechazada',
        'Tu solicitud de acceso ha sido rechazada. Contacta al administrador.',
        { type: 'rechazo' }
      );
    }

    return null;
  });

// ==================== HTTP FUNCTIONS ====================

/**
 * Endpoint para subir documento a Google Drive e indexar
 */
export const uploadDocument = functions.https.onCall(async (data, context) => {
  // Verificar que sea admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debe iniciar sesión');
  }

  const userId = context.auth.uid;
  const userDoc = await db.collection('users').doc(userId).get();
  
  if (userDoc.data()?.rol !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Solo administradores');
  }

  const { fileData, fileName, fileType, fileCategory } = data;

  if (!fileData || !fileName) {
    throw new functions.https.HttpsError('invalid-argument', 'Faltan datos del archivo');
  }

  try {
    // Decodificar archivo base64
    const buffer = Buffer.from(fileData, 'base64');

    // Subir a Google Drive (usando Google APIs)
    // Nota: En producción, usar una cuenta de servicio
    const drive = google.drive('v3');
    
    const fileMetadata = {
      name: fileName,
      parents: [DRIVE_FOLDER_ID],
    };

    const media = {
      mimeType: 'application/pdf',
      body: buffer.toString('base64'),
    };

    const response = await drive.files.create({
      resource: fileMetadata,
      media: media,
      fields: 'id, name, webViewLink',
    });

    const driveFileId = response.data.id;
    const driveFileUrl = response.data.webViewLink;

    // Crear documento en Firestore
    const docRef = await db.collection('documentos').add({
      nombre: fileName.replace('.pdf', ''),
      tipo: fileType || 'documento',
      categoria: fileCategory || 'General',
      driveFileId,
      driveFileUrl,
      nombreOriginal: fileName,
      tamanhoBytes: buffer.length,
      estado: 'pendiente',
      totalFragmentos: 0,
      subidoPor: userId,
      fechaCarga: admin.firestore.FieldValue.serverTimestamp(),
      fragmentos: {},
    });

    // Programar indexación (en background)
    await indexDocument(docRef.id, driveFileId, fileName);

    return {
      success: true,
      documentId: docRef.id,
      driveFileId,
      driveFileUrl,
    };
  } catch (error) {
    console.error('Error uploading document:', error);
    throw new functions.https.HttpsError('internal', 'Error al subir el documento');
  }
});

/**
 * Indexa un documento PDF (extrae texto y genera fragmentos)
 */
async function indexDocument(documentId: string, driveFileId: string, fileName: string) {
  try {
    // Marcar como indexando
    await db.collection('documentos').doc(documentId).update({
      estado: 'indexando',
    });

    // Descargar contenido del PDF desde Google Drive
    const drive = google.drive('v3');
    
    // En producción, usar cuenta de servicio para descargar
    const response = await drive.files.get({
      fileId: driveFileId,
      alt: 'media',
    }, { responseType: 'arraybuffer' });

    const pdfContent = response.data;
    
    // Extraer texto del PDF (simplificado - en producción usar pdf-parse)
    const textContent = extractTextFromPDF(pdfContent);
    
    // Fragmentar texto
    const chunks = chunkText(textContent, 500);
    
    // Crear fragmentos en Firestore
    const fragmentos: Record<string, any> = {};
    chunks.forEach((chunk, index) => {
      fragmentos[`chunk_${index}`] = {
        texto: chunk,
        pagina: Math.floor(index / 10) + 1, // Estimación
        inicioChar: index * 500,
        embedding: [], // En producción, generar embeddings aquí
      };
    });

    // Actualizar documento
    await db.collection('documentos').doc(documentId).update({
      estado: 'indexado',
      totalFragmentos: chunks.length,
      ultimoIndice: admin.firestore.FieldValue.serverTimestamp(),
      fragmentos,
    });

    console.log(`Document ${fileName} indexed with ${chunks.length} chunks`);
  } catch (error) {
    console.error('Error indexing document:', error);
    await db.collection('documentos').doc(documentId).update({
      estado: 'error',
    });
  }
}

/**
 * Extrae texto de un PDF (versión simplificada)
 */
function extractTextFromPDF(pdfData: any): string {
  // En producción, usar pdf-parse o similar
  // Por ahora, retornar placeholder
  try {
    const text = pdfData.toString('utf8', 0, pdfData.length);
    // Limpiar caracteres no imprimibles
    return text.replace(/[^\x20-\x7E\n]/g, ' ').trim();
  } catch {
    return '';
  }
}

/**
 * Fragmenta texto en chunks
 */
function chunkText(text: string, chunkSize: number): string[] {
  const chunks: string[] = [];
  const sentences = text.split(/[.!?]+/).filter(s => s.trim());
  
  let currentChunk = '';
  for (const sentence of sentences) {
    if ((currentChunk + sentence).length <= chunkSize) {
      currentChunk += sentence + '. ';
    } else {
      if (currentChunk.trim()) {
        chunks.push(currentChunk.trim());
      }
      currentChunk = sentence + '. ';
    }
  }
  
  if (currentChunk.trim()) {
    chunks.push(currentChunk.trim());
  }
  
  return chunks;
}

/**
 * Elimina un documento
 */
export const deleteDocument = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debe iniciar sesión');
  }

  const userId = context.auth.uid;
  const userDoc = await db.collection('users').doc(userId).get();
  
  if (userDoc.data()?.rol !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Solo administradores');
  }

  const { documentId } = data;

  if (!documentId) {
    throw new functions.https.HttpsError('invalid-argument', 'Falta el ID del documento');
  }

  try {
    const doc = await db.collection('documentos').doc(documentId).get();
    const docData = doc.data();
    
    if (!docData) {
      throw new functions.https.HttpsError('not-found', 'Documento no encontrado');
    }

    // Eliminar de Google Drive
    if (docData.driveFileId) {
      const drive = google.drive('v3');
      await drive.files.delete({ fileId: docData.driveFileId });
    }

    // Eliminar de Firestore
    await db.collection('documentos').doc(documentId).delete();

    // Registrar en logs
    await db.collection('logs').add({
      accion: 'documento_eliminado',
      tipo: 'documento',
      usuarioId,
      usuarioNombre: `${userDoc.data()?.nombre} ${userDoc.data()?.apellido}`,
      detalles: `Documento eliminado: ${docData.nombre}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Error deleting document:', error);
    throw new functions.https.HttpsError('internal', 'Error al eliminar el documento');
  }
});

/**
 * Re-indexa un documento existente
 */
export const reindexDocument = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debe iniciar sesión');
  }

  const userId = context.auth.uid;
  const userDoc = await db.collection('users').doc(userId).get();
  
  if (userDoc.data()?.rol !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Solo administradores');
  }

  const { documentId } = data;

  if (!documentId) {
    throw new functions.https.HttpsError('invalid-argument', 'Falta el ID del documento');
  }

  try {
    const doc = await db.collection('documentos').doc(documentId).get();
    const docData = doc.data();
    
    if (!docData) {
      throw new functions.https.HttpsError('not-found', 'Documento no encontrado');
    }

    // Re-indexar
    await indexDocument(documentId, docData.driveFileId, docData.nombreOriginal || docData.nombre);

    return { success: true };
  } catch (error) {
    console.error('Error reindexing document:', error);
    throw new functions.https.HttpsError('internal', 'Error al re-indexar el documento');
  }
});

// ==================== SCHEDULED FUNCTIONS ====================

/**
 * Limpia ubicaciones antiguas (cada hora)
 */
export const cleanupOldLocations = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async () => {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    const snapshot = await db.collection('ubicaciones')
      .where('activo', '==', true)
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, { activo: false });
    });

    await batch.commit();
    console.log(`Cleaned up ${snapshot.size} inactive locations`);
    
    return null;
  });

/**
 * Función para hacer queries al asistente IA (RAG)
 */
export const queryAI = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debe iniciar sesión');
  }

  const { query } = data;

  if (!query || typeof query !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Falta la consulta');
  }

  try {
    // 1. Buscar fragmentos relevantes en Firestore
    const docsSnapshot = await db.collection('documentos')
      .where('estado', '==', 'indexado')
      .get();

    let relevantChunks: any[] = [];
    
    for (const doc of docsSnapshot.docs) {
      const fragmentos = doc.data().fragmentos || {};
      
      for (const [chunkId, chunk] of Object.entries(fragmentos)) {
        const chunkText = (chunk as any).texto.toLowerCase();
        const queryLower = query.toLowerCase();
        
        // Simple keyword matching (en producción usar embeddings)
        const keywords = queryLower.split(' ')
          .filter(w => w.length > 3)
          .filter(w => !['para', 'como', 'cual', 'donde', 'cuando', 'puede'].includes(w));
        
        let matches = 0;
        for (const keyword of keywords) {
          if (chunkText.includes(keyword)) matches++;
        }
        
        if (matches > 0) {
          relevantChunks.push({
            ...(chunk as any),
            documento: doc.data().nombre,
            tipo: doc.data().tipo,
            matches,
          });
        }
      }
    }

    // Ordenar por relevancia
    relevantChunks.sort((a, b) => b.matches - a.matches);
    relevantChunks = relevantChunks.slice(0, 5);

    // 2. Construir contexto
    let context = '';
    if (relevantChunks.length > 0) {
      context = 'INFORMACIÓN DE LOS DOCUMENTOS CARGADOS:\n\n';
      for (let i = 0; i < relevantChunks.length; i++) {
        const chunk = relevantChunks[i];
        context += `--- Fragmento ${i + 1} ---\n`;
        context += `Documento: ${chunk.documento}\n`;
        context += `Tipo: ${chunk.tipo}\n`;
        context += `Contenido: ${chunk.texto}\n\n`;
      }
      context += '---\n\n';
    }

    // 3. Llamar a Groq API
    const fullPrompt = context + `PREGUNTA DEL USUARIO: ${query}`;

    const response = await axios.post(GROQ_API_URL, {
      model: GROQ_MODEL,
      messages: [
        {
          role: 'system',
          content: `Eres un asistente legal especializado en legislación de tránsito de Argentina, específicamente del municipio de Trelew, Chubut.

Tu función es RESPONDER ÚNICAMENTE basándote en la documentación legal oficial cargada en el sistema.

REGLAS IMPORTANTES:
1. SOLO responde usando información de los documentos oficiales cargados
2. NUNCA inventes, infieras o uses conocimiento general del modelo
3. Si la información NO está en los documentos, responde exactamente: "No se encontró información en las normas cargadas."
4. Cite siempre la norma y artículo correspondiente
5. Sé breve y directo en tus respuestas

FORMATO DE RESPUESTA:
Cuando encuentres información:
---
[Respuesta breve]

📋 Norma: [Nombre de la norma]
📌 Artículo: [Número de artículo]
---

Cuando NO encuentres información:
---
No se encontró información en las normas cargadas.
---`,
        },
        {
          role: 'user',
          content: fullPrompt,
        },
      ],
      temperature: 0.3,
      max_tokens: 1024,
    }, {
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    const answer = response.data.choices[0].message.content;

    // 4. Guardar en historial
    await db.collection('chat_historial').add({
      userId: context.auth.uid,
      pregunta: query,
      respuesta: answer,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Registrar en logs
    await db.collection('logs').add({
      accion: 'consulta_ia',
      tipo: 'sistema',
      usuarioId: context.auth.uid,
      detalles: `Consultó: ${query.substring(0, 100)}...`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { answer, relevantChunks: relevantChunks.length };
  } catch (error: any) {
    console.error('Error in queryAI:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Error al procesar la consulta');
  }
});
