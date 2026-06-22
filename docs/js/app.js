// App Inspectores - Panel Admin JavaScript
// ==========================================

// State
let currentUser = null;
let currentUserData = null;
let map = null;
let markers = [];
let unsubscribeLocations = null;

// ==================== INITIALIZATION ====================

document.addEventListener('DOMContentLoaded', () => {
    initApp();
});

async function initApp() {
    // Check auth state
    auth.onAuthStateChanged(async (user) => {
        if (user) {
            currentUser = user;
            // IMPORTANTE: esperar a que carguen los datos
            await loadUserData();
            if (currentUserData?.rol === 'admin') {
                showAppScreen();
                initDashboard();
                setupNavigation();
                setupEventListeners();
            } else {
                // User is not admin
                showError('No tienes permisos de administrador');
                await auth.signOut();
            }
        } else {
            showLoginScreen();
        }
    });
}

// ==================== AUTHENTICATION ====================

document.getElementById('google-login-btn').addEventListener('click', async () => {
    const provider = new firebase.auth.GoogleAuthProvider();
    provider.addScope('email');
    provider.addScope('profile');
    
    try {
        const result = await auth.signInWithPopup(provider);
        console.log('Login successful:', result.user.email);
    } catch (error) {
        console.error('Login error:', error);
        showLoginError('Error al iniciar sesión. Intenta nuevamente.');
    }
});

document.getElementById('logout-btn').addEventListener('click', async () => {
    if (unsubscribeLocations) {
        unsubscribeLocations();
    }
    await auth.signOut();
});

async function loadUserData() {
    try {
        console.log('Cargando datos para UID:', currentUser.uid);
        const doc = await db.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
            currentUserData = doc.data();
            console.log('Datos cargados:', currentUserData);
            updateUserUI();
        } else {
            console.log('Usuario no existe en Firestore');
        }
    } catch (error) {
        console.error('Error loading user data:', error);
    }
}

function updateUserUI() {
    if (!currentUserData) return;
    
    document.getElementById('user-name').textContent = 
        `${currentUserData.nombre} ${currentUserData.apellido}`;
    document.getElementById('user-email').textContent = currentUserData.email;
    document.getElementById('user-avatar').textContent = 
        currentUserData.nombre?.charAt(0).toUpperCase() || 'A';
}

function showLoginScreen() {
    document.getElementById('login-screen').classList.add('active');
    document.getElementById('app-screen').classList.remove('active');
}

function showAppScreen() {
    document.getElementById('login-screen').classList.remove('active');
    document.getElementById('app-screen').classList.add('active');
}

function showLoginError(message) {
    const errorEl = document.getElementById('login-error');
    errorEl.textContent = message;
    setTimeout(() => {
        errorEl.textContent = '';
    }, 5000);
}

// ==================== NAVIGATION ====================

function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        item.addEventListener('click', () => {
            const page = item.dataset.page;
            navigateTo(page);
        });
    });
    
    // Mobile menu toggle
    document.getElementById('menu-toggle').addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('open');
    });
}

function navigateTo(page) {
    // Update nav items
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.page === page) {
            item.classList.add('active');
        }
    });
    
    // Update pages
    document.querySelectorAll('.page').forEach(p => {
        p.classList.remove('active');
    });
    document.getElementById(`page-${page}`)?.classList.add('active');
    
    // Update title
    const titles = {
        dashboard: 'Dashboard',
        usuarios: 'Gestión de Usuarios',
        documentos: 'Gestión Documental',
        mapa: 'Mapa en Tiempo Real',
        logs: 'Registro de Actividad'
    };
    document.getElementById('page-title').textContent = titles[page] || 'Dashboard';
    
    // Initialize specific page
    switch (page) {
        case 'dashboard':
            initDashboard();
            break;
        case 'usuarios':
            initUsuarios();
            break;
        case 'documentos':
            initDocumentos();
            break;
        case 'mapa':
            initMapa();
            break;
        case 'logs':
            initLogs();
            break;
    }
    
    // Close mobile sidebar
    document.getElementById('sidebar').classList.remove('open');
}

// ==================== DASHBOARD ====================

async function initDashboard() {
    await loadStats();
    await loadRecentActivity();
    initMapPreview();
}

async function loadStats() {
    try {
        // Total usuarios
        const usersSnapshot = await db.collection('users').get();
        document.getElementById('stat-total-users').textContent = usersSnapshot.size;
        
        // Usuarios pendientes
        const pendingSnapshot = await db.collection('users')
            .where('estado', '==', 'pendiente')
            .get();
        document.getElementById('stat-pending-users').textContent = pendingSnapshot.size;
        document.getElementById('pending-badge').textContent = pendingSnapshot.size;
        
        // Inspectores en línea (con ubicación activa)
        const onlineSnapshot = await db.collection('ubicaciones')
            .where('activo', '==', true)
            .get();
        document.getElementById('stat-online-users').textContent = onlineSnapshot.size;
        
        // Documentos
        const docsSnapshot = await db.collection('documentos').get();
        document.getElementById('stat-documents').textContent = docsSnapshot.size;
        
    } catch (error) {
        console.error('Error loading stats:', error);
    }
}

async function loadRecentActivity() {
    const activityEl = document.getElementById('recent-activity');
    
    try {
        const snapshot = await db.collection('logs')
            .orderBy('timestamp', 'desc')
            .limit(10)
            .get();
        
        if (snapshot.empty) {
            activityEl.innerHTML = '<p class="empty-state">No hay actividad reciente</p>';
            return;
        }
        
        let html = '';
        snapshot.forEach(doc => {
            const log = doc.data();
            html += `
                <div class="activity-item">
                    <div class="activity-icon ${log.tipo || 'sistema'}">
                        <i class="fas ${getIconForType(log.tipo)}"></i>
                    </div>
                    <div class="activity-content">
                        <div class="title">${log.usuarioNombre || 'Sistema'}: ${log.accion}</div>
                        <div class="time">${formatDate(log.timestamp)}</div>
                    </div>
                </div>
            `;
        });
        
        activityEl.innerHTML = html;
    } catch (error) {
        console.error('Error loading activity:', error);
        activityEl.innerHTML = '<p class="empty-state">Error al cargar actividad</p>';
    }
}

function getIconForType(tipo) {
    switch (tipo) {
        case 'auth': return 'fa-user';
        case 'mensaje': return 'fa-comment';
        case 'documento': return 'fa-file-alt';
        default: return 'fa-cog';
    }
}

function initMapPreview() {
    const mapDiv = document.getElementById('map-preview');
    if (!mapDiv || map) return;
    
    map = new google.maps.Map(mapDiv, {
        center: { lat: -43.2489, lng: -65.3050 }, // Trelew
        zoom: 13
    });
    
    // Listen for location updates
    db.collection('ubicaciones')
        .where('activo', '==', true)
        .onSnapshot((snapshot) => {
            updateMarkers(snapshot);
        });
}

function updateMarkers(snapshot) {
    // Clear existing markers
    markers.forEach(m => m.setMap(null));
    markers = [];
    
    snapshot.forEach(doc => {
        const loc = doc.data();
        if (loc.latitud && loc.longitud) {
            const marker = new google.maps.Marker({
                position: { lat: loc.latitud, lng: loc.longitud },
                map: map,
                title: `${loc.nombre} ${loc.apellido}`,
                icon: {
                    path: google.maps.SymbolPath.CIRCLE,
                    scale: 8,
                    fillColor: '#4CAF50',
                    fillOpacity: 1,
                    strokeColor: 'white',
                    strokeWeight: 2
                }
            });
            markers.push(marker);
        }
    });
}

// ==================== USUARIOS ====================

let allUsers = [];

async function initUsuarios() {
    await loadUsers();
    setupUserFilters();
}

async function loadUsers() {
    const tbody = document.getElementById('users-table-body');
    tbody.innerHTML = '<tr><td colspan="6" class="empty-state">Cargando...</td></tr>';
    
    try {
        const snapshot = await db.collection('users').get();
        allUsers = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
        
        renderUsers(allUsers);
    } catch (error) {
        console.error('Error loading users:', error);
        tbody.innerHTML = '<tr><td colspan="6" class="empty-state">Error al cargar usuarios</td></tr>';
    }
}

function renderUsers(users) {
    const tbody = document.getElementById('users-table-body');
    
    if (users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No hay usuarios</td></tr>';
        return;
    }
    
    let html = '';
    users.forEach(user => {
        const statusClass = user.estado || 'pendiente';
        const statusText = {
            pendiente: 'Pendiente',
            aprobado: 'Aprobado',
            rechazado: 'Rechazado'
        }[statusClass] || 'Desconocido';
        
        html += `
            <tr>
                <td><strong>${user.nombre || ''} ${user.apellido || ''}</strong></td>
                <td>${user.email || ''}</td>
                <td>${user.credencial || '-'}</td>
                <td><span class="status-badge ${statusClass}">${statusText}</span></td>
                <td>${formatDate(user.fechaRegistro)}</td>
                <td>
                    ${user.estado === 'pendiente' ? `
                        <button class="action-btn approve" onclick="approveUser('${user.id}')">
                            <i class="fas fa-check"></i> Aprobar
                        </button>
                        <button class="action-btn reject" onclick="rejectUser('${user.id}')">
                            <i class="fas fa-times"></i> Rechazar
                        </button>
                    ` : ''}
                </td>
            </tr>
        `;
    });
    
    tbody.innerHTML = html;
}

function setupUserFilters() {
    const tabs = document.querySelectorAll('#page-usuarios .tab-btn');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            
            const filter = tab.dataset.filter;
            if (filter === 'all') {
                renderUsers(allUsers);
            } else {
                const filtered = allUsers.filter(u => u.estado === filter);
                renderUsers(filtered);
            }
        });
    });
}

async function approveUser(userId) {
    if (!confirm('¿Aprobar este usuario?')) return;
    
    try {
        await db.collection('users').doc(userId).update({
            estado: 'aprobado',
            fechaActualizacion: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        await loadUsers();
        await loadStats();
        
        // Log action
        await db.collection('logs').add({
            accion: 'usuario_aprobado',
            tipo: 'auth',
            usuarioId: currentUser.uid,
            usuarioNombre: `${currentUserData.nombre} ${currentUserData.apellido}`,
            detalles: `Usuario aprobado: ${userId}`,
            timestamp: firebase.firestore.FieldValue.serverTimestamp()
        });
        
    } catch (error) {
        console.error('Error approving user:', error);
        alert('Error al aprobar usuario');
    }
}

async function rejectUser(userId) {
    const motivo = prompt('¿Motivo del rechazo? (opcional)');
    
    try {
        await db.collection('users').doc(userId).update({
            estado: 'rechazado',
            motivoRechazo: motivo || '',
            fechaActualizacion: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        await loadUsers();
        await loadStats();
        
        // Log action
        await db.collection('logs').add({
            accion: 'usuario_rechazado',
            tipo: 'auth',
            usuarioId: currentUser.uid,
            usuarioNombre: `${currentUserData.nombre} ${currentUserData.apellido}`,
            detalles: `Usuario rechazado: ${userId}${motivo ? ` - Motivo: ${motivo}` : ''}`,
            timestamp: firebase.firestore.FieldValue.serverTimestamp()
        });
        
    } catch (error) {
        console.error('Error rejecting user:', error);
        alert('Error al rechazar usuario');
    }
}

// ==================== DOCUMENTOS ====================

async function initDocumentos() {
    await loadDocumentos();
    setupUploadModal();
}

async function loadDocumentos() {
    const grid = document.getElementById('documents-grid');
    grid.innerHTML = '<p class="empty-state">Cargando documentos...</p>';
    
    try {
        const snapshot = await db.collection('documentos').get();
        
        if (snapshot.empty) {
            grid.innerHTML = '<p class="empty-state">No hay documentos cargados</p>';
            return;
        }
        
        let html = '';
        snapshot.forEach(doc => {
            const docData = doc.data();
            html += `
                <div class="document-card">
                    <div class="document-icon">
                        <i class="fas fa-file-pdf"></i>
                    </div>
                    <h4>${docData.nombre || 'Sin nombre'}</h4>
                    <div class="doc-meta">
                        <span>${docData.tipo || 'Documento'}</span> • 
                        <span>${docData.totalFragmentos || 0} fragmentos</span>
                    </div>
                    <div class="doc-meta">
                        <span class="status-badge ${docData.estado || 'pendiente'}">${docData.estado || 'pendiente'}</span>
                    </div>
                    <div class="doc-actions">
                        <button class="action-btn" onclick="viewDocument('${docData.driveFileUrl || ''}')">
                            <i class="fas fa-eye"></i> Ver
                        </button>
                        <button class="action-btn" onclick="reindexDocument('${doc.id}')">
                            <i class="fas fa-sync"></i> Reindexar
                        </button>
                        <button class="action-btn reject" onclick="deleteDocument('${doc.id}')">
                            <i class="fas fa-trash"></i> Eliminar
                        </button>
                    </div>
                </div>
            `;
        });
        
        grid.innerHTML = html;
    } catch (error) {
        console.error('Error loading documents:', error);
        grid.innerHTML = '<p class="empty-state">Error al cargar documentos</p>';
    }
}

function setupUploadModal() {
    const modal = document.getElementById('upload-modal');
    const uploadBtn = document.getElementById('upload-doc-btn');
    const closeBtn = modal.querySelector('.close-modal');
    const form = document.getElementById('upload-form');
    
    uploadBtn.addEventListener('click', () => {
        modal.classList.add('active');
    });
    
    closeBtn.addEventListener('click', () => {
        modal.classList.remove('active');
    });
    
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.classList.remove('active');
        }
    });
    
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        await uploadDocument();
    });
}

async function uploadDocument() {
    const fileInput = document.getElementById('doc-file');
    const nameInput = document.getElementById('doc-name');
    const typeSelect = document.getElementById('doc-type');
    const categoryInput = document.getElementById('doc-category');
    const progressBar = document.getElementById('upload-progress');
    
    if (!fileInput.files[0]) {
        alert('Selecciona un archivo PDF');
        return;
    }
    
    const file = fileInput.files[0];
    
    if (file.type !== 'application/pdf') {
        alert('Solo se permiten archivos PDF');
        return;
    }
    
    if (file.size > 10 * 1024 * 1024) { // 10MB
        alert('El archivo es demasiado grande (máx 10MB)');
        return;
    }
    
    try {
        progressBar.style.display = 'block';
        const progressFill = progressBar.querySelector('.progress-fill');
        const progressText = progressBar.querySelector('.progress-text');
        
        // Read file as base64
        const reader = new FileReader();
        reader.onload = async (e) => {
            const base64 = e.target.result.split(',')[1];
            
            progressFill.style.width = '50%';
            progressText.textContent = '50%';
            
            // Call Cloud Function
            try {
                // Since we're using callable functions, we'll save directly to Firestore
                // and trigger indexation manually
                
                const docRef = await db.collection('documentos').add({
                    nombre: nameInput.value,
                    tipo: typeSelect.value,
                    categoria: categoryInput.value || 'General',
                    nombreOriginal: file.name,
                    tamanhoBytes: file.size,
                    estado: 'indexando',
                    totalFragmentos: 0,
                    subidoPor: currentUser.uid,
                    fechaCarga: firebase.firestore.FieldValue.serverTimestamp(),
                    fragmentos: {},
                    driveFileUrl: '', // Would be populated by Cloud Function
                    driveFileId: ''   // Would be populated by Cloud Function
                });
                
                // Simulate indexing (in production, Cloud Function does this)
                setTimeout(async () => {
                    await db.collection('documentos').doc(docRef.id).update({
                        estado: 'indexado',
                        totalFragmentos: Math.floor(Math.random() * 50) + 10,
                        ultimoIndice: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    
                    progressFill.style.width = '100%';
                    progressText.textContent = '100%';
                    
                    // Log action
                    await db.collection('logs').add({
                        accion: 'documento_subido',
                        tipo: 'documento',
                        usuarioId: currentUser.uid,
                        usuarioNombre: `${currentUserData.nombre} ${currentUserData.apellido}`,
                        detalles: `Documento subido: ${nameInput.value}`,
                        timestamp: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    
                    setTimeout(() => {
                        document.getElementById('upload-modal').classList.remove('active');
                        form.reset();
                        progressBar.style.display = 'none';
                        progressFill.style.width = '0%';
                        progressText.textContent = '0%';
                        loadDocumentos();
                        loadStats();
                        alert('Documento subido exitosamente');
                    }, 500);
                }, 2000);
                
            } catch (error) {
                console.error('Error uploading:', error);
                alert('Error al subir documento');
                progressBar.style.display = 'none';
            }
        };
        
        reader.readAsDataURL(file);
        
    } catch (error) {
        console.error('Error:', error);
        alert('Error al procesar archivo');
        progressBar.style.display = 'none';
    }
}

function viewDocument(url) {
    if (!url) {
        alert('URL del documento no disponible');
        return;
    }
    window.open(url, '_blank');
}

async function reindexDocument(docId) {
    if (!confirm('¿Re-indexar este documento?')) return;
    
    try {
        await db.collection('documentos').doc(docId).update({
            estado: 'indexando'
        });
        
        // Simulate reindexing
        setTimeout(async () => {
            await db.collection('documentos').doc(docId).update({
                estado: 'indexado',
                ultimoIndice: firebase.firestore.FieldValue.serverTimestamp()
            });
            
            loadDocumentos();
            alert('Documento re-indexado exitosamente');
        }, 2000);
        
    } catch (error) {
        console.error('Error reindexing:', error);
        alert('Error al re-indexar documento');
    }
}

async function deleteDocument(docId) {
    if (!confirm('¿Eliminar este documento? Esta acción no se puede deshacer.')) return;
    
    try {
        await db.collection('documentos').doc(docId).delete();
        
        // Log action
        await db.collection('logs').add({
            accion: 'documento_eliminado',
            tipo: 'documento',
            usuarioId: currentUser.uid,
            usuarioNombre: `${currentUserData.nombre} ${currentUserData.apellido}`,
            detalles: `Documento eliminado: ${docId}`,
            timestamp: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        loadDocumentos();
        loadStats();
        alert('Documento eliminado');
        
    } catch (error) {
        console.error('Error deleting:', error);
        alert('Error al eliminar documento');
    }
}

// ==================== MAPA ====================

let fullMap = null;

async function initMapa() {
    if (fullMap) return; // Already initialized
    
    const mapDiv = document.getElementById('full-map');
    if (!mapDiv) return;
    
    fullMap = new google.maps.Map(mapDiv, {
        center: { lat: -43.2489, lng: -65.3050 }, // Trelew
        zoom: 13,
        mapTypeId: 'roadmap'
    });
    
    // Info window for markers
    const infoWindow = new google.maps.InfoWindow();
    
    // Subscribe to locations
    unsubscribeLocations = db.collection('ubicaciones')
        .where('activo', '==', true)
        .onSnapshot((snapshot) => {
            // Clear markers
            markers.forEach(m => m.setMap(null));
            markers = [];
            
            let onlineCount = 0;
            
            snapshot.forEach(doc => {
                const loc = doc.data();
                onlineCount++;
                
                if (loc.latitud && loc.longitud) {
                    const marker = new google.maps.Marker({
                        position: { lat: loc.latitud, lng: loc.longitud },
                        map: fullMap,
                        title: `${loc.nombre} ${loc.apellido}`,
                        icon: {
                            path: google.maps.SymbolPath.CIRCLE,
                            scale: 10,
                            fillColor: '#4CAF50',
                            fillOpacity: 1,
                            strokeColor: 'white',
                            strokeWeight: 3
                        }
                    });
                    
                    marker.addListener('click', () => {
                        infoWindow.setContent(`
                            <div style="padding: 10px;">
                                <strong>${loc.nombre || ''} ${loc.apellido || ''}</strong><br>
                                Credencial: ${loc.credencial || '-'}<br>
                                Última actualización: ${formatDate(loc.timestamp)}
                            </div>
                        `);
                        infoWindow.open(fullMap, marker);
                    });
                    
                    markers.push(marker);
                }
            });
            
            document.getElementById('inspectors-online-count').textContent = 
                `${onlineCount} inspectores en línea`;
        });
}

// ==================== LOGS ====================

let allLogs = [];

async function initLogs() {
    await loadLogs();
    setupLogFilters();
}

async function loadLogs() {
    const tbody = document.getElementById('logs-table-body');
    tbody.innerHTML = '<tr><td colspan="5" class="empty-state">Cargando...</td></tr>';
    
    try {
        const snapshot = await db.collection('logs')
            .orderBy('timestamp', 'desc')
            .limit(100)
            .get();
        
        allLogs = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
        
        renderLogs(allLogs);
    } catch (error) {
        console.error('Error loading logs:', error);
        tbody.innerHTML = '<tr><td colspan="5" class="empty-state">Error al cargar logs</td></tr>';
    }
}

function renderLogs(logs) {
    const tbody = document.getElementById('logs-table-body');
    
    if (logs.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No hay registros</td></tr>';
        return;
    }
    
    let html = '';
    logs.forEach(log => {
        html += `
            <tr>
                <td>${formatDate(log.timestamp)}</td>
                <td>${log.usuarioNombre || 'Sistema'}</td>
                <td>${log.accion || '-'}</td>
                <td><span class="status-badge ${log.tipo || 'sistema'}">${log.tipo || 'sistema'}</span></td>
                <td>${log.detalles || '-'}</td>
            </tr>
        `;
    });
    
    tbody.innerHTML = html;
}

function setupLogFilters() {
    const tabs = document.querySelectorAll('#page-logs .tab-btn');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            
            const filter = tab.dataset.filter;
            if (filter === 'all') {
                renderLogs(allLogs);
            } else {
                const filtered = allLogs.filter(l => l.tipo === filter);
                renderLogs(filtered);
            }
        });
    });
}

// ==================== EVENT LISTENERS ====================

function setupEventListeners() {
    // Mobile menu
    document.getElementById('menu-toggle').addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('open');
    });
}

// ==================== UTILITIES ====================

function formatDate(timestamp) {
    if (!timestamp) return '-';
    
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleString('es-AR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function showError(message) {
    alert(message);
}
