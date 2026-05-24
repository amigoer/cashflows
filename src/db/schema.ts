import { relations, sql } from 'drizzle-orm';
import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const SALARY_PERIODS = ['monthly', 'biweekly', 'one_off'] as const;
export type SalaryPeriod = (typeof SALARY_PERIODS)[number];

export const REPAYMENT_STATUSES = ['pending', 'paid', 'overdue'] as const;
export type RepaymentStatus = (typeof REPAYMENT_STATUSES)[number];

export const salaries = sqliteTable('salaries', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  amountCents: integer('amount_cents').notNull(),
  paidAt: integer('paid_at').notNull(),
  period: text('period', { enum: SALARY_PERIODS }).notNull().default('monthly'),
  note: text('note'),
  createdAt: integer('created_at')
    .notNull()
    .default(sql`(unixepoch() * 1000)`),
});

export const debtPlans = sqliteTable('debt_plans', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  platform: text('platform').notNull(),
  principalCents: integer('principal_cents').notNull(),
  totalPeriods: integer('total_periods').notNull(),
  monthlyPaymentCents: integer('monthly_payment_cents').notNull(),
  firstDueDate: integer('first_due_date').notNull(),
  aprBps: integer('apr_bps').notNull().default(0),
  note: text('note'),
  archived: integer('archived', { mode: 'boolean' }).notNull().default(false),
  createdAt: integer('created_at')
    .notNull()
    .default(sql`(unixepoch() * 1000)`),
});

export const repayments = sqliteTable('repayments', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  debtPlanId: integer('debt_plan_id')
    .notNull()
    .references(() => debtPlans.id, { onDelete: 'cascade' }),
  periodIndex: integer('period_index').notNull(),
  dueDate: integer('due_date').notNull(),
  amountCents: integer('amount_cents').notNull(),
  status: text('status', { enum: REPAYMENT_STATUSES }).notNull().default('pending'),
  paidAt: integer('paid_at'),
});

export const debtPlansRelations = relations(debtPlans, ({ many }) => ({
  repayments: many(repayments),
}));

export const repaymentsRelations = relations(repayments, ({ one }) => ({
  debtPlan: one(debtPlans, {
    fields: [repayments.debtPlanId],
    references: [debtPlans.id],
  }),
}));

export type Salary = typeof salaries.$inferSelect;
export type NewSalary = typeof salaries.$inferInsert;
export type DebtPlan = typeof debtPlans.$inferSelect;
export type NewDebtPlan = typeof debtPlans.$inferInsert;
export type Repayment = typeof repayments.$inferSelect;
export type NewRepayment = typeof repayments.$inferInsert;
