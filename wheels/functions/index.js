const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();

const db = admin.firestore();

exports.getTrustScore = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ success: false, message: 'Method not allowed.' });
    return;
  }

  const userId = String(req.query.userId || '').trim();
  if (!userId) {
    res.status(400).json({ success: false, message: 'userId is required.' });
    return;
  }

  try {
    const trust = await buildTrustScore(userId);
    res.status(200).json({ success: true, data: trust });
  } catch (error) {
    functions.logger.error('getTrustScore failed', error);
    res.status(500).json({
      success: false,
      message: 'Could not calculate the trust score.',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

async function buildTrustScore(userId) {
  const userRef = db.collection('users').doc(userId);
  const driverRidesQuery = db.collection('rides').where('driverId', '==', userId);
  const passengerRidesQuery = db
    .collection('rides')
    .where('passengerIds', 'array-contains', userId);

  const [userSnapshot, driverRidesSnapshot, passengerRidesSnapshot] = await Promise.all([
    userRef.get(),
    driverRidesQuery.get(),
    passengerRidesQuery.get(),
  ]);

  const userData = userSnapshot.data() || {};
  const ridesById = new Map();

  for (const doc of driverRidesSnapshot.docs) {
    ridesById.set(doc.id, { data: doc.data(), relation: 'driver' });
  }
  for (const doc of passengerRidesSnapshot.docs) {
    if (!ridesById.has(doc.id)) {
      ridesById.set(doc.id, { data: doc.data(), relation: 'passenger' });
    }
  }

  let completedRides = 0;
  let cancelledRides = 0;
  let activeRides = 0;

  for (const { data } of ridesById.values()) {
    const status = readString(data.status);
    if (status === 'completed') {
      completedRides += 1;
      continue;
    }
    if (status === 'cancelled') {
      cancelledRides += 1;
      continue;
    }
    if (status === 'open' || status === 'in_progress') {
      activeRides += 1;
    }
  }

  const paymentCounters = await Promise.all(
    Array.from(ridesById.entries()).map(([rideId, ride]) =>
      loadPaymentCountersForRide({
        rideId,
        userId,
        relation: ride.relation,
      }),
    ),
  );

  let approvedPayments = 0;
  let pendingPayments = 0;
  let failedPayments = 0;
  for (const counters of paymentCounters) {
    approvedPayments += counters.approvedPayments;
    pendingPayments += counters.pendingPayments;
    failedPayments += counters.failedPayments;
  }

  const totalRides = ridesById.size;
  const totalPayments = approvedPayments + pendingPayments + failedPayments;
  const accountCreatedAt =
    readDate(userData.createdAt) || readDate(userData.updatedAt) || new Date();
  const role = readString(userData.role) || 'passenger';

  return {
    userId,
    role,
    accountCreatedAt: accountCreatedAt.toISOString(),
    totalRides,
    completedRides,
    cancelledRides,
    activeRides,
    totalPayments,
    approvedPayments,
    pendingPayments,
    failedPayments,
    score: calculateScore({
      totalRides,
      completedRides,
      cancelledRides,
      approvedPayments,
      pendingPayments,
      failedPayments,
      accountCreatedAt,
    }),
    rewardPoints: calculateRewardPoints({
      completedRides,
      approvedPayments,
      cancelledRides,
      failedPayments,
      accountCreatedAt,
      totalRides,
    }),
  };
}

async function loadPaymentCountersForRide({ rideId, userId, relation }) {
  const passengersCollection = db
    .collection('payments')
    .doc(rideId)
    .collection('passengers');

  if (relation === 'passenger') {
    const snapshot = await passengersCollection.doc(userId).get();
    if (!snapshot.exists) {
      return emptyCounters();
    }
    return classifyPayments([snapshot.data() || {}]);
  }

  const snapshot = await passengersCollection.get();
  return classifyPayments(snapshot.docs.map((doc) => doc.data()));
}

function classifyPayments(payments) {
  let approvedPayments = 0;
  let pendingPayments = 0;
  let failedPayments = 0;

  for (const payment of payments) {
    const paymentStatus = readString(payment.paymentStatus);
    const status = readString(payment.status);
    if (paymentStatus === 'paid' || status === 'approved') {
      approvedPayments += 1;
      continue;
    }
    if (paymentStatus === 'unpaid' || status === 'rejected') {
      failedPayments += 1;
      continue;
    }
    pendingPayments += 1;
  }

  return { approvedPayments, pendingPayments, failedPayments };
}

function calculateScore({
  totalRides,
  completedRides,
  cancelledRides,
  approvedPayments,
  pendingPayments,
  failedPayments,
  accountCreatedAt,
}) {
  let score = 68;
  const completionRate = totalRides === 0 ? 0 : completedRides / totalRides;
  const accountAgeDays = Math.max(
    0,
    Math.floor((Date.now() - accountCreatedAt.getTime()) / 86400000),
  );

  score += clamp(completedRides * 3, 0, 18);
  score += clamp(approvedPayments * 2, 0, 12);
  score += clamp(Math.floor(accountAgeDays / 30) * 2, 0, 10);

  if (totalRides >= 5 && completionRate >= 0.9) {
    score += 6;
  }
  if (approvedPayments >= 3 && pendingPayments === 0 && failedPayments === 0) {
    score += 4;
  }
  if (totalRides === 0) {
    score -= 6;
  }

  score -= clamp(cancelledRides * 8, 0, 24);
  score -= clamp(failedPayments * 10, 0, 20);
  score -= clamp(pendingPayments * 2, 0, 8);

  return clamp(score, 45, 99);
}

function calculateRewardPoints({
  completedRides,
  approvedPayments,
  cancelledRides,
  failedPayments,
  accountCreatedAt,
  totalRides,
}) {
  const accountAgeDays = Math.max(
    0,
    Math.floor((Date.now() - accountCreatedAt.getTime()) / 86400000),
  );
  const maturityPoints = clamp(Math.floor(accountAgeDays / 30) * 2, 0, 20);
  const completionBonus = totalRides >= 3 && cancelledRides === 0 ? 20 : 0;

  return Math.max(
    0,
    completedRides * 5 +
      approvedPayments * 3 +
      maturityPoints +
      completionBonus -
      cancelledRides * 4 -
      failedPayments * 6,
  );
}

function readString(value) {
  return typeof value === 'string' && value.trim() ? value.trim().toLowerCase() : null;
}

function readDate(value) {
  if (!value) {
    return null;
  }
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function emptyCounters() {
  return { approvedPayments: 0, pendingPayments: 0, failedPayments: 0 };
}
