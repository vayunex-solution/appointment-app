/**
 * Firebase Admin SDK Configuration
 * Initialize Firebase for sending FCM push notifications
 */
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let firebaseInitialized = false;

const initFirebase = () => {
    if (firebaseInitialized) return;

    try {
        const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');

        if (fs.existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            firebaseInitialized = true;
            console.log('✅ Firebase Admin SDK initialized');
        } else {
            console.warn('⚠️ Firebase service account not found at:', serviceAccountPath);
            console.warn('   Push notifications will be disabled.');
            console.warn('   Download from Firebase Console → Project Settings → Service Accounts');
        }
    } catch (error) {
        console.error('❌ Firebase init failed:', error.message);
    }
};

const getMessaging = () => {
    if (!firebaseInitialized) return null;
    return admin.messaging();
};

module.exports = { initFirebase, getMessaging, admin };
