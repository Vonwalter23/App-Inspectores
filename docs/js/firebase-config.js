// Firebase Configuration - App Inspectores Trelew
// Proyecto: app-inspectores-trelew-499913
// ============================================

const firebaseConfig = {
    apiKey: "AIzaSyAzHrcZYSKa9w-yb-f-iDGWrLGCXYIDyzo",
    authDomain: "app-inspectores-trelew-499913.firebaseapp.com",
    projectId: "app-inspectores-trelew-499913",
    storageBucket: "app-inspectores-trelew-499913.firebasestorage.app",
    messagingSenderId: "468318865609",
    appId: "1:468318865609:web:adc83ac6c3b2ce00cda518",
    measurementId: "G-YYNHJ14JLT"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize services
const auth = firebase.auth();
const db = firebase.firestore();

// Google Maps API Key
const GOOGLE_MAPS_API_KEY = 'AIzaSyBpKbl3vRcqNRwcMm3f8qOOPGpb43qXQZE';
