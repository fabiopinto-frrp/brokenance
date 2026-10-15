import argon2 from 'argon2';

const options = { type: argon2.argon2id };

export const hashPassword = (password) => argon2.hash(password, options);

export async function verifyPassword(hash, password) {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false;
  }
}

// When the username does not exist we still do the same amount of work, so response time does not
// reveal which usernames have an account.
let dummyHash;
export async function burnPasswordCheck(password) {
  dummyHash ??= hashPassword('dummy-password-used-for-timing-only');
  await verifyPassword(await dummyHash, password);
}
