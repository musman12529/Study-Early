importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyByo4Q3R5CX2JWdCa3Cg5sR02ot1_2xMzQ',
  appId: '1:521674901512:web:01e92cd486a61a4f2d29bd',
  messagingSenderId: '521674901512',
  projectId: 'gr09-studyearly-fall-2025',
  authDomain: 'gr09-studyearly-fall-2025.firebaseapp.com',
  storageBucket: 'gr09-studyearly-fall-2025.firebasestorage.app',
  measurementId: 'G-7RS3L112XF',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle =
    payload.notification?.title ?? 'Studyearly notification';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});


