importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');
try {
  importScripts('/firebase-config.local.js');
} catch (_) {
  // Config file is optional in source control and should be provided locally.
}

const firebaseConfig = self.FIREBASE_WEB_CONFIG;

if (!firebaseConfig) {
  console.warn(
    'Missing FIREBASE_WEB_CONFIG on service worker scope. ' +
      'Notifications will not initialize.'
  );
} else {
  firebase.initializeApp(firebaseConfig);
}

const messaging = firebaseConfig ? firebase.messaging() : null;

if (messaging) {
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
}

