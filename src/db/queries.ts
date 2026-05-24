import { and, asc, desc, eq, gte, inArray, lt, sql } from 'drizzle-orm';

import { db } from './client';
import { generateRepaymentSchedule } from './repayment-schedule';
import {
  debtPlans,
  repayments,
  salaries,
  type NewDebtPlan,
  type NewSalary,
  type Repayment,
  type Salary,
} from './schema';

// ---------- Salaries ----------

export async function listSalaries(): Promise<Salary[]> {
  return db.select().from(salaries).orderBy(desc(salaries.paidAt));
}

export async function listSalariesInRange(startMs: number, endMs: number): Promise<Salary[]> {
  return db
    .select()
    .from(salaries)
    .where(and(gte(salaries.paidAt, startMs), lt(salaries.paidAt, endMs)))
    .orderBy(asc(salaries.paidAt));
}

export async function createSalary(input: NewSalary): Promise<Salary> {
  const rows = await db.insert(salaries).values(input).returning();
  return rows[0];
}

export async function updateSalary(id: number, patch: Partial<NewSalary>): Promise<void> {
  await db.update(salaries).set(patch).where(eq(salaries.id, id));
}

export async function deleteSalary(id: number): Promise<void> {
  await db.delete(salaries).where(eq(salaries.id, id));
}

// ---------- Debt Plans ----------

export async function listDebtPlans(includeArchived = false) {
  const rows = await db
    .select()
    .from(debtPlans)
    .where(includeArchived ? sql`1=1` : eq(debtPlans.archived, false))
    .orderBy(asc(debtPlans.platform), desc(debtPlans.createdAt));
  return rows;
}

export async function getDebtPlan(id: number) {
  const rows = await db.select().from(debtPlans).where(eq(debtPlans.id, id)).limit(1);
  return rows[0] ?? null;
}

export async function createDebtPlanWithSchedule(input: NewDebtPlan) {
  const inserted = await db.insert(debtPlans).values(input).returning();
  const plan = inserted[0];
  const schedule = generateRepaymentSchedule({
    debtPlanId: plan.id,
    totalPeriods: plan.totalPeriods,
    monthlyPaymentCents: plan.monthlyPaymentCents,
    firstDueDate: plan.firstDueDate,
  });
  if (schedule.length > 0) {
    await db.insert(repayments).values(schedule);
  }
  return plan;
}

export async function updateDebtPlan(id: number, patch: Partial<NewDebtPlan>): Promise<void> {
  await db.update(debtPlans).set(patch).where(eq(debtPlans.id, id));
}

export async function archiveDebtPlan(id: number, archived: boolean): Promise<void> {
  await db.update(debtPlans).set({ archived }).where(eq(debtPlans.id, id));
}

export async function deleteDebtPlan(id: number): Promise<void> {
  await db.delete(debtPlans).where(eq(debtPlans.id, id));
}

// ---------- Repayments ----------

export async function listRepaymentsForPlan(planId: number): Promise<Repayment[]> {
  return db
    .select()
    .from(repayments)
    .where(eq(repayments.debtPlanId, planId))
    .orderBy(asc(repayments.periodIndex));
}

export async function listRepaymentsInRange(startMs: number, endMs: number) {
  return db
    .select({
      repayment: repayments,
      debtPlan: debtPlans,
    })
    .from(repayments)
    .innerJoin(debtPlans, eq(repayments.debtPlanId, debtPlans.id))
    .where(and(gte(repayments.dueDate, startMs), lt(repayments.dueDate, endMs)))
    .orderBy(asc(repayments.dueDate));
}

export async function markRepayment(id: number, paid: boolean): Promise<void> {
  await db
    .update(repayments)
    .set({ status: paid ? 'paid' : 'pending', paidAt: paid ? Date.now() : null })
    .where(eq(repayments.id, id));
}

export async function deleteRepaymentsForPlan(planId: number): Promise<void> {
  await db.delete(repayments).where(eq(repayments.debtPlanId, planId));
}

// ---------- Aggregates ----------

export type DebtPlanSummary = {
  planId: number;
  platform: string;
  totalPeriods: number;
  paidPeriods: number;
  remainingPeriods: number;
  remainingCents: number;
  totalDueCents: number;
};

export async function summarizeDebtPlans(): Promise<DebtPlanSummary[]> {
  const plans = await db.select().from(debtPlans).where(eq(debtPlans.archived, false));
  if (plans.length === 0) return [];

  const planIds = plans.map((p) => p.id);
  const reps = await db
    .select()
    .from(repayments)
    .where(inArray(repayments.debtPlanId, planIds));

  const groupedByPlan = new Map<number, Repayment[]>();
  for (const r of reps) {
    const arr = groupedByPlan.get(r.debtPlanId) ?? [];
    arr.push(r);
    groupedByPlan.set(r.debtPlanId, arr);
  }

  return plans.map((plan) => {
    const rs = groupedByPlan.get(plan.id) ?? [];
    const paid = rs.filter((r) => r.status === 'paid');
    const remaining = rs.filter((r) => r.status !== 'paid');
    return {
      planId: plan.id,
      platform: plan.platform,
      totalPeriods: plan.totalPeriods,
      paidPeriods: paid.length,
      remainingPeriods: remaining.length,
      remainingCents: remaining.reduce((s, r) => s + r.amountCents, 0),
      totalDueCents: rs.reduce((s, r) => s + r.amountCents, 0),
    };
  });
}

export type MonthSummary = {
  incomeCents: number;
  repaymentCents: number;
  netCents: number;
  salaryCount: number;
  repaymentCount: number;
};

export async function summarizeMonth(startMs: number, endMs: number): Promise<MonthSummary> {
  const [incomeRows, repaymentRows] = await Promise.all([
    listSalariesInRange(startMs, endMs),
    db
      .select()
      .from(repayments)
      .where(and(gte(repayments.dueDate, startMs), lt(repayments.dueDate, endMs))),
  ]);

  const incomeCents = incomeRows.reduce((s, r) => s + r.amountCents, 0);
  const repaymentCents = repaymentRows.reduce((s, r) => s + r.amountCents, 0);
  return {
    incomeCents,
    repaymentCents,
    netCents: incomeCents - repaymentCents,
    salaryCount: incomeRows.length,
    repaymentCount: repaymentRows.length,
  };
}
