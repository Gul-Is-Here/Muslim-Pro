import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let env;
const db = (uid, claims) =>
  (uid ? env.authenticatedContext(uid, claims) : env.unauthenticatedContext()).firestore();
const storage = (uid) => env.authenticatedContext(uid).storage();
const seed = (path, data) => env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), path), data));

const log = () => ({
  fajr: 'onTime', dhuhr: 'late', asr: 'none', maghrib: 'missed', isha: 'qada',
  updatedAt: serverTimestamp(),
});
const LOG = 'users/alice/prayer_logs/2026-11-11';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-quran-pro',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
    storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
  });
});
afterEach(async () => { await env.clearFirestore(); await env.clearStorage(); });
after(() => env.cleanup());

describe('users/{uid}/prayer_logs', () => {
  it('owner writes a valid log', () => assertSucceeds(setDoc(doc(db('alice'), LOG), log())));
  it('another user cannot read it', async () => {
    await seed(LOG, { ...log(), updatedAt: new Date() });
    await assertFails(getDoc(doc(db('bob'), LOG)));
  });
  it('signed-out user cannot read it', () => assertFails(getDoc(doc(db(null), LOG))));
  it('rejects unknown status', () => assertFails(setDoc(doc(db('alice'), LOG), { ...log(), fajr: 'maybe' })));
  it('rejects extra keys', () => assertFails(setDoc(doc(db('alice'), LOG), { ...log(), xp: 999 })));
  it('rejects client timestamps', () => assertFails(setDoc(doc(db('alice'), LOG), { ...log(), updatedAt: new Date() })));
  it('rejects malformed date ids', () => assertFails(setDoc(doc(db('alice'), 'users/alice/prayer_logs/today'), log())));
});

describe('users/{uid} profile and stats', () => {
  it('cannot write own stats (XP)', () => assertFails(setDoc(doc(db('alice'), 'users/alice/stats/current'), { xp: 1e6 })));
  it('cannot change createdAt', async () => {
    await seed('users/alice', { displayName: 'A', createdAt: new Date(0), updatedAt: new Date(0) });
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'users/alice'), { displayName: 'B', updatedAt: serverTimestamp() }));
  });
});

describe('progress', () => {
  const p = (completed) => ({ completed, score: 80, completedAt: serverTimestamp() });
  it('requires the lesson to exist', () => assertFails(setDoc(doc(db('alice'), 'users/alice/progress/l9'), p(true))));
  it('cannot un-complete a lesson', async () => {
    await seed('lessons/l1', { unit: 1, order: 1 });
    await seed('users/alice/progress/l1', { completed: true, score: 80, completedAt: new Date() });
    await assertFails(setDoc(doc(db('alice'), 'users/alice/progress/l1'), p(false)));
  });
});

describe('public content', () => {
  beforeEach(() => seed('lessons/l1', { unit: 1, order: 1 }));
  it('signed-in (incl. guest) can read', () => assertSucceeds(getDoc(doc(db('alice'), 'lessons/l1'))));
  it('signed-out cannot read', () => assertFails(getDoc(doc(db(null), 'lessons/l1'))));
  it('clients cannot write', () => assertFails(setDoc(doc(db('alice'), 'lessons/l1'), { unit: 2 })));
  it('admin claim can write', () => assertSucceeds(setDoc(doc(db('root', { admin: true }), 'lessons/l1'), { unit: 2 })));
});

describe('storage', () => {
  const up = (uid, path, size, contentType) =>
    uploadBytes(ref(storage(uid), path), new Uint8Array(size), { contentType });
  it('owner uploads a small image', () => assertSucceeds(up('alice', 'users/alice/avatar.png', 10, 'image/png')));
  it('rejects other uid', () => assertFails(up('bob', 'users/alice/avatar.png', 10, 'image/png')));
  it('rejects wrong content type', () => assertFails(up('alice', 'users/alice/doc.png', 10, 'application/pdf')));
  it('rejects > 5 MB', () => assertFails(up('alice', 'users/alice/big.png', 5 * 1024 * 1024 + 1, 'image/png')));
  it('content is read-only', () => assertFails(up('alice', 'content/x.png', 10, 'image/png')));
});
