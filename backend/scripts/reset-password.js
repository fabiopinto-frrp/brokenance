// Resets a user's password when it is forgotten (there is no email to send a reset link to).
//
//   npm run user:reset-password -- <username>
//   docker compose exec api npm run user:reset-password -- <username>     (inside Docker)
//
// It generates a new random password, prints it once, and logs the user out everywhere.
// Log in with it and change it in the app.
import { randomBytes } from 'node:crypto';
import { hashPassword } from '../src/lib/password.js';
import { prisma } from '../src/lib/prisma.js';

const username = process.argv[2]?.trim().toLowerCase();

if (!username) {
  console.error('Usage: npm run user:reset-password -- <username>');
  process.exit(1);
}

try {
  const user = await prisma.user.findUnique({ where: { username } });
  if (!user) {
    console.error(`No user called "${username}".`);
    process.exitCode = 1;
  } else {
    const password = randomBytes(18).toString('base64url');
    await prisma.$transaction([
      prisma.user.update({ where: { id: user.id }, data: { passwordHash: await hashPassword(password) } }),
      prisma.refreshToken.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);
    console.log(`Password of "${username}" reset. Every session was logged out.`);
    console.log(`New password: ${password}`);
    console.log('Log in with it and change it in the app.');
  }
} finally {
  await prisma.$disconnect();
}
