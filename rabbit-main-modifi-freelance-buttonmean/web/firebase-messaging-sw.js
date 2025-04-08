importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyCfn5X61u0vj8Ve8DIJqog_xKrX58Z_vIw",
      authDomain: "rabbit-8cace.firebaseapp.com",
      projectId: "rabbit-8cace",
      storageBucket: "rabbit-8cace.firebasestorage.app",
      messagingSenderId: "654682130983",
      appId: "1:654682130983:web:01ed18d2e8079c835d5c02",
      measurementId: "G-2V3R3RML66"
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
});
