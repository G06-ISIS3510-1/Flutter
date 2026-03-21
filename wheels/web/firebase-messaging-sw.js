importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDp64jnFMJVhq0eg-62omUHcA02A7Oxjk8',
  appId: '1:95599418351:web:cd0815485296d8be12f41a',
  messagingSenderId: '95599418351',
  projectId: 'wheels-fd8c0',
  authDomain: 'wheels-fd8c0.firebaseapp.com',
  storageBucket: 'wheels-fd8c0.firebasestorage.app',
  measurementId: 'G-6SSG01937Z',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'Wheels';
  const options = {
    body: notification.body || 'Tienes una nueva notificacion.',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(title, options);
});
