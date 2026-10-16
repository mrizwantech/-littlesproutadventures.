import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const host = process.env.FIRESTORE_EMULATOR_HOST;
assert(host, 'Run this test through the Firestore emulator, never production.');
const project = 'demo-little-learners';
const root = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const uid = `parent-${randomUUID()}`;
const token = (user) => {
  const encode = (data) => Buffer.from(JSON.stringify(data)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    sub: user,
    user_id: user,
    aud: project,
    iss: `https://securetoken.google.com/${project}`,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600,
    firebase: { sign_in_provider: 'google.com' },
  })}.`;
};
const headers = (user) => ({
  'Content-Type': 'application/json',
  ...(user ? { Authorization: `Bearer ${token(user)}` } : {}),
});
const write = (user, fields) => fetch(`${root}:commit`, {
  method: 'POST',
  headers: headers(user),
  body: JSON.stringify({
    writes: [{
      update: {
        name: `projects/${project}/databases/(default)/documents/users/${uid}`,
        fields,
      },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
    }],
  }),
});
const valid = {
  nickname: { stringValue: 'Alex' },
  ageBand: { stringValue: '4-5' },
};
async function expectStatus(response, status, label) {
  const body = await response.text();
  assert.equal(response.status, status, `${label}: ${body}`);
  console.log(`PASS ${label}`);
}
await expectStatus(await write(null, valid), 403, 'Unauthenticated writes denied');
await expectStatus(await write('other-parent', valid), 403, 'Cross-account writes denied');
await expectStatus(await write(uid, valid), 200, 'Owner can create a valid profile');
for (const avatar of ['girl', 'boy']) {
  await expectStatus(await write(uid, { ...valid, avatar: { stringValue: avatar } }), 200, `Owner can save ${avatar} avatar`);
}
await expectStatus(await fetch(`${root}/users/${uid}`, { headers: headers(uid) }), 200, 'Owner can read profile');
await expectStatus(await fetch(`${root}/users/${uid}`, { headers: headers('other-parent') }), 403, 'Cross-account reads denied');
await expectStatus(await fetch(`${root}/users/${uid}`), 403, 'Unauthenticated reads denied');
await expectStatus(await fetch(`${root}/users`, { headers: headers(uid) }), 403, 'Profile listing denied');
for (const [label, fields] of [
  ['Invalid age band', { ...valid, ageBand: { stringValue: '8-9' } }],
  ['Blank nickname', { ...valid, nickname: { stringValue: '   ' } }],
  ['Long nickname', { ...valid, nickname: { stringValue: 'a'.repeat(41) } }],
  ['Missing age band', { nickname: valid.nickname }],
  ['Invalid avatar', { ...valid, avatar: { stringValue: 'unknown' } }],
  ['Null avatar', { ...valid, avatar: { nullValue: null } }],
  ['Unexpected personal field', { ...valid, birthDate: { stringValue: '2020-01-01' } }],
]) {
  await expectStatus(await write(uid, fields), 403, `${label} denied`);
}
await expectStatus(await write(uid, { ...valid, nickname: { stringValue: 'Sam' } }), 200, 'Owner can update profile');
await expectStatus(await fetch(`${root}/users/${uid}`, { method: 'DELETE', headers: headers(uid) }), 200, 'Owner can delete profile');
