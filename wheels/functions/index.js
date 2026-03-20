const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');

admin.initializeApp();

const firestore = admin.firestore();
const messaging = admin.messaging();

exports.sendHabitualConnectionReminders = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('Etc/UTC')
  .onRun(async () => {
    const usersSnapshot = await firestore.collection('users').get();
    const nowUtc = new Date();
    let notifiedUsers = 0;

    for (const userDoc of usersSnapshot.docs) {
      const data = userDoc.data() || {};
      const tokens = Array.isArray(data.fcmTokens)
        ? data.fcmTokens.filter((token) => typeof token === 'string' && token)
        : [];

      if (tokens.length === 0) {
        continue;
      }

      const summaryRef = userDoc.ref.collection('engagement').doc('summary');
      const summarySnap = await summaryRef.get();
      const summary = summarySnap.data();
      const currentLocalDate = new Date(
        nowUtc.getTime() + Number((summary && summary.timezoneOffsetMinutes) || 0) * 60 * 1000,
      );
      const currentLocalHour = currentLocalDate.getUTCHours();
      const dateKey = buildDateKey(currentLocalDate);
      const thresholdDate = new Date(
        currentLocalDate.getTime() - 30 * 24 * 60 * 60 * 1000,
      );
      const thresholdKey = buildDateKey(thresholdDate);
      const dailySnapshot = await userDoc.ref
        .collection('engagementDaily')
        .where('dateKey', '>=', thresholdKey)
        .get();
      const hourCounts = buildHourCounts(dailySnapshot.docs);
      const totalConnections = Object.values(hourCounts).reduce(
        (sum, count) => sum + count,
        0,
      );

      if (totalConnections === 0) {
        continue;
      }

      const preferredHour = getPreferredHour(hourCounts);

      if (Number.isNaN(preferredHour) || currentLocalHour !== preferredHour) {
        continue;
      }

      if (summary && summary.lastReminderDateKey === dateKey) {
        continue;
      }

      const todayDaily = dailySnapshot.docs.find((doc) => doc.id === dateKey);
      const dailyData = todayDaily ? todayDaily.data() : {};
      const hours = Array.isArray(dailyData.hours) ? dailyData.hours : [];

      if (hours.includes(preferredHour)) {
        continue;
      }

      const message = {
        tokens,
        notification: {
          title: 'Te extrañamos en Wheels',
          body: `Sueles conectarte hacia las ${formatHour(preferredHour)}. Entra a la app y mira nuevas opciones.`,
        },
        data: {
          type: 'engagement_reminder',
          preferredHour: String(preferredHour),
        },
      };

      const response = await messaging.sendEachForMulticast(message);
      const invalidTokens = [];

      response.responses.forEach((sendResponse, index) => {
        if (!sendResponse.success) {
          const code = sendResponse.error && sendResponse.error.code;
          if (
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(tokens[index]);
          }
        }
      });

      await summaryRef.set(
        {
          hourCounts,
          preferredHour,
          rollingWindowStartDateKey: thresholdKey,
          rollingWindowDays: 30,
          totalConnectionsLast30Days: totalConnections,
          lastReminderDateKey: dateKey,
          lastReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      if (invalidTokens.length > 0) {
        await userDoc.ref.set(
          {
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
          },
          { merge: true },
        );
      }

      notifiedUsers += 1;
    }

    logger(`Finished reminder cycle. Notified users: ${notifiedUsers}`);
    return null;
  });

function buildDateKey(date) {
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${date.getUTCFullYear()}-${month}-${day}`;
}

function formatHour(hour) {
  const normalized = `${String(hour).padStart(2, '0')}:00`;
  return normalized;
}

function buildHourCounts(dailyDocs) {
  const counts = {};

  for (let hour = 0; hour < 24; hour += 1) {
    counts[String(hour)] = 0;
  }

  for (const dailyDoc of dailyDocs) {
    const data = dailyDoc.data() || {};
    const hours = Array.isArray(data.hours) ? data.hours : [];
    for (const hour of hours) {
      counts[String(hour)] = (counts[String(hour)] || 0) + 1;
    }
  }

  return counts;
}

function getPreferredHour(hourCounts) {
  let bestHour = 0;
  let bestCount = -1;

  for (let hour = 0; hour < 24; hour += 1) {
    const count = Number(hourCounts[String(hour)] || 0);
    if (count > bestCount) {
      bestCount = count;
      bestHour = hour;
    }
  }

  return bestHour;
}

function logger(message) {
  functions.logger.info(message);
}
