import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

initializeApp();

// Score is client-reported: grade quizzes server-side before any public leaderboard.
export const onProgressWritten = onDocumentWritten('users/{uid}/progress/{lessonId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!after?.completed || before?.completed) return; // award once per lesson (rules forbid un-completing)
  await getFirestore().doc(`users/${event.params.uid}/stats/current`).set(
    { xp: FieldValue.increment(10 + Math.round(after.score / 10)), updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
});
