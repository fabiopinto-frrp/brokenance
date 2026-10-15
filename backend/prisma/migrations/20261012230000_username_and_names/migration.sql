-- Accounts switch from email to username, and the single name becomes first and last name.
-- There is no real data yet, so existing (test) accounts are deleted. Their profiles, tokens and
-- other rows go with them through ON DELETE CASCADE.
DELETE FROM "users";

-- DropIndex
DROP INDEX "users_email_key";

-- AlterTable
ALTER TABLE "profiles" DROP COLUMN "name",
ADD COLUMN     "first_name" TEXT NOT NULL,
ADD COLUMN     "last_name" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "email",
ADD COLUMN     "username" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

