const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'wheels-fd8c0',
});

const db = admin.firestore();

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function seed() {
  console.log('Seeding data...');

  const users = [];

  for (let i = 0; i < 50; i++) {
    const userRef = db.collection('users').doc();

    const user = {
      fullName: `User ${i}`,
      email: `user${i}@uniandes.edu.co`,
      role: Math.random() > 0.5 ? 'driver' : 'passenger',
      photoUrl: '',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await userRef.set(user);
    users.push({ id: userRef.id, ...user });
  }

  console.log('Users created');

  const drivers = users.filter((u) => u.role === 'driver');
  if (drivers.length === 0) {
    throw new Error('No drivers were generated.');
  }

  for (let i = 0; i < 200; i++) {
    const driver = drivers[randomInt(0, drivers.length - 1)];

    const rideRef = db.collection('rides').doc();

    const ride = {
      driverId: driver.id,
      driverName: driver.fullName,
      driverEmail: driver.email,
      status: ['completed', 'completed', 'completed', 'in_progress', 'cancelled'][randomInt(0, 4)],
      origin: 'Uniandes',
      destination: 'Bogotá',
      availableSeats: randomInt(1, 4),
      totalSeats: randomInt(1, 4),
      pricePerSeat: randomInt(3000, 8000),
      passengerIds: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await rideRef.set(ride);
  }

  console.log('Rides created');
}

seed()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });