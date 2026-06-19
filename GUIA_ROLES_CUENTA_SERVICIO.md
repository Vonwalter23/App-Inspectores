# 🔐 Guía: Añadir Roles a la Cuenta de Servicio

## Problema
La cuenta de servicio actual no tiene permisos para desplegar Firestore Rules.

## Solución: Añadir Roles en Google Cloud Console

### Paso 1: Ir a IAM

1. Ve a: https://console.cloud.google.com/iam-admin/iam
2. Selecciona el proyecto: `app-inspectores-trelew`

### Paso 2: Encontrar la Cuenta de Servicio

Busca esta cuenta de servicio en la lista:
```
firebase-adminsdk-fbsvc@app-inspectores-trelew.iam.gserviceaccount.com
```

### Paso 3: Añadir Roles

Click en el **lápiz** (editar) junto a la cuenta de servicio.

Añade estos roles (seleccionar de la lista):

- [ ] **Firebase Rules Admin** (`firebaserules.admin`)
- [ ] **Cloud Functions Admin** (`cloudfunctions.admin`)
- [ ] **Cloud Storage Admin** (`storage.admin`)
- [ ] **Cloud Firestore Owner** (`datastore.owner`)
- [ ] **Firebase Admin** (`firebase.admin`)
- [ ] **Project IAM Admin** (`resourcemanager.projectIamAdmin`) - Opcional

### Alternativa Rápida

Si prefieres un solo rol amplio:
- [ ] **Editor** (`roles/editor`)

### Paso 4: Guardar

Click en **"Guardar"**

---

## Verificar Permisos

Después de añadir los roles, vuelve aquí y avísame para continuar.

---

## Scripts Alternativos (si prefieres gcloud CLI)

```bash
# Si tienes gcloud CLI instalado:
gcloud projects add-iam-policy-binding app-inspectores-trelew \
  --member="serviceAccount:firebase-adminsdk-fbsvc@app-inspectores-trelew.iam.gserviceaccount.com" \
  --role="roles/firebaserules.admin"

gcloud projects add-iam-policy-binding app-inspectores-trelew \
  --member="serviceAccount:firebase-adminsdk-fbsvc@app-inspectores-trelew.iam.gserviceaccount.com" \
  --role="roles/cloudfunctions.admin"
```

---

## Una vez añadidos los roles

Avísame y continúo con el despliegue:
- Firestore Rules
- Firestore Indexes
- Storage Rules
- Cloud Functions
- Firebase Hosting
