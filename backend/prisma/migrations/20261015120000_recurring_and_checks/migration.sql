-- AlterTable
ALTER TABLE "profiles" ADD COLUMN     "net_worth_set_at" TIMESTAMPTZ(3);

-- AlterTable
ALTER TABLE "subscriptions" ADD COLUMN     "charge_from" DATE NOT NULL;


-- Database-level checks (Prisma cannot express them in the schema). The API validates the same
-- rules first and answers with a clear error. These are the last line of defence.
ALTER TABLE "profiles"
  ADD CONSTRAINT "profiles_monthly_income_not_negative" CHECK ("monthly_income_cents" >= 0);

ALTER TABLE "transactions"
  ADD CONSTRAINT "transactions_amount_not_zero" CHECK ("amount_cents" <> 0);

ALTER TABLE "subscriptions"
  ADD CONSTRAINT "subscriptions_amount_positive" CHECK ("amount_cents" > 0),
  ADD CONSTRAINT "subscriptions_billing_day_range" CHECK ("billing_day" BETWEEN 1 AND 31);

ALTER TABLE "savings_targets"
  ADD CONSTRAINT "savings_targets_amount_positive" CHECK ("amount_cents" > 0);

ALTER TABLE "goals"
  ADD CONSTRAINT "goals_target_positive" CHECK ("target_cents" > 0),
  ADD CONSTRAINT "goals_saved_not_negative" CHECK ("saved_cents" >= 0);
