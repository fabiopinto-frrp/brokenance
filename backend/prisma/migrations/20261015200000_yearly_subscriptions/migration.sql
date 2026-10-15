-- CreateEnum
CREATE TYPE "subscription_period" AS ENUM ('MONTHLY', 'YEARLY');

-- AlterTable
ALTER TABLE "subscriptions" ADD COLUMN     "billing_month" INTEGER,
ADD COLUMN     "period" "subscription_period" NOT NULL DEFAULT 'MONTHLY';


-- Monthly subscriptions have no month, yearly ones need one (1-12).
ALTER TABLE "subscriptions"
  ADD CONSTRAINT "subscriptions_billing_month_matches_period" CHECK (
    ("period" = 'MONTHLY' AND "billing_month" IS NULL)
    OR ("period" = 'YEARLY' AND "billing_month" BETWEEN 1 AND 12)
  );
