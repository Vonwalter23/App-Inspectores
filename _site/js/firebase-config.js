// Firebase Configuration - App Inspectores Trelew
// ============================================

const firebaseConfig = {
    apiKey: "AIzaSyCbOI6ePQm4a24qXK3bMSmfztC_FHD88bY",
    authDomain: "app-inspectores-trelew.firebaseapp.com",
    databaseURL: "https://app-inspectores-trelew-default-rtdb.firebaseio.com",
    projectId: "app-inspectores-trelew",
    storageBucket: "app-inspectores-trelew.firebasestorage.app",
    messagingSenderId: "946555132852",
    appId: "1:946555132852:web:f54dd2762f4c47b19fb0e1",
    measurementId: "G-8LF98EX6Q7"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize services
const auth = firebase.auth();
const db = firebase.firestore();
const storage = firebase.storage();
const messaging = firebase.messaging();

// Enable Firestore offline persistence (optional)
db.enablePersistence().catch((err) => {
    console.log('Persistence error:', err.code);
});

// Google Maps API Key
const GOOGLE_MAPS_API_KEY = 'AIzaSyBpKbl3vRcqNRwcMm3f8qOOPGpb43qXQZE';
