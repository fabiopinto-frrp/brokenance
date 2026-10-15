import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

// Loads backend/.env (not committed, .env.example lists the keys). Variables that are already
// set (by Docker, the shell or the tests) are never overwritten, and the file is optional.
// Resolved from this file, so it works whatever folder the command runs from.
dotenv.config({ path: fileURLToPath(new URL('../../.env', import.meta.url)), quiet: true });
