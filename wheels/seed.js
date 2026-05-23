const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'wheels-fd8c0',
});

const db = admin.firestore();

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

const reviewTexts = [
  'Very punctual and respectful during the ride.',
  'Great communication and smooth coordination.',
  'Friendly, reliable, and easy to travel with.',
  'Everything went well from pickup to arrival.',
  'Excellent attitude and very trustworthy.',
];

function normalize(value) {
  return String(value ?? '').trim().toLowerCase();
}

function usernameFromEmail(email) {
  return normalize(email).split('@')[0];
}

function userMatchesIdentifier(user, identifier) {
  const needle = normalize(identifier);
  if (!needle) return false;

  const values = [
    user.id,
    user.email,
    usernameFromEmail(user.email),
    user.fullName,
  ].map(normalize);

  return values.some((value) => value === needle || value.includes(needle));
}

async function loadUsers() {
  const snapshot = await db.collection('users').get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function ensureReviewerUsers(existingUsers) {
  if (existingUsers.length >= 2) {
    return existingUsers;
  }

  const reviewers = [
    {
      id: 'seed-reviewer-carlos',
      fullName: 'Carlos Mendez',
      email: 'seed.reviewer.carlos@uniandes.edu.co',
      role: 'driver',
    },
    {
      id: 'seed-reviewer-laura',
      fullName: 'Laura Perez',
      email: 'seed.reviewer.laura@uniandes.edu.co',
      role: 'passenger',
    },
    {
      id: 'seed-reviewer-sofia',
      fullName: 'Sofia Torres',
      email: 'seed.reviewer.sofia@uniandes.edu.co',
      role: 'driver',
    },
  ];

  for (const reviewer of reviewers) {
    await db.collection('users').doc(reviewer.id).set(
      {
        fullName: reviewer.fullName,
        email: reviewer.email,
        role: reviewer.role,
        photoUrl: '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  return loadUsers();
}

async function seedReviewsForUsers(identifiers) {
  if (identifiers.length === 0) {
    throw new Error(
      'Pass at least one user identifier. Example: node seed.js reviews prueba prueba6',
    );
  }

  let users = await loadUsers();
  users = await ensureReviewerUsers(users);

  const targetUsers = [];
  for (const identifier of identifiers) {
    const matches = users.filter((user) =>
      userMatchesIdentifier(user, identifier),
    );
    if (matches.length === 0) {
      console.warn(`No user found for "${identifier}".`);
      continue;
    }

    const user = matches[0];
    targetUsers.push(user);
    console.log(
      `Target "${identifier}" -> ${user.fullName} (${user.email}) [${user.id}]`,
    );
  }

  if (targetUsers.length === 0) {
    throw new Error('No matching users found. Check the users collection first.');
  }

  for (const target of targetUsers) {
    const reviewers = users.filter((user) => user.id !== target.id);
    for (let i = 0; i < 5; i++) {
      const reviewer = reviewers[i % reviewers.length];
      const rating = i === 2 ? 4 : 5;
      const createdAt = new Date(Date.now() - (i + 1) * 24 * 60 * 60 * 1000);
      const reviewRef = db.collection('reviews').doc(
        `manual_${target.id}_${i + 1}`,
      );

      await reviewRef.set(
        {
          reviewedUserId: target.id,
          reviewedUserName: target.fullName,
          reviewerUserId: reviewer.id,
          reviewerName: reviewer.fullName,
          rating,
          roleTag: target.role === 'driver' ? 'driver' : 'passenger',
          reviewedAs: target.role === 'driver' ? 'driver' : 'passenger',
          reviewText: reviewTexts[i % reviewTexts.length],
          createdAt,
          updatedAt: createdAt,
        },
        { merge: true },
      );
    }

    console.log(`Added 5 reviews for ${target.fullName}.`);
  }
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

  for (let i = 0; i < 120; i++) {
    const reviewedUser = users[randomInt(0, users.length - 1)];
    let reviewer = users[randomInt(0, users.length - 1)];
    while (reviewer.id === reviewedUser.id) {
      reviewer = users[randomInt(0, users.length - 1)];
    }

    const reviewRef = db.collection('reviews').doc();
    const rating = randomInt(3, 5);
    const createdAt = new Date(
      Date.now() - randomInt(0, 45) * 24 * 60 * 60 * 1000,
    );

    await reviewRef.set({
      reviewedUserId: reviewedUser.id,
      reviewedUserName: reviewedUser.fullName,
      reviewerUserId: reviewer.id,
      reviewerName: reviewer.fullName,
      rating,
      roleTag: reviewedUser.role === 'driver' ? 'driver' : 'passenger',
      reviewedAs: reviewedUser.role === 'driver' ? 'driver' : 'passenger',
      reviewText: reviewTexts[randomInt(0, reviewTexts.length - 1)],
      createdAt,
      updatedAt: createdAt,
    });
  }

  console.log('Reviews created');
}

async function main() {
  const [mode, ...args] = process.argv.slice(2);

  if (mode === 'reviews') {
    await seedReviewsForUsers(args);
    return;
  }

  await seed();
}

main()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
