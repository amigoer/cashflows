import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';

import { db } from '@/db/client';
import { debtPlans, repayments, salaries, type DebtPlan, type Repayment, type Salary } from '@/db/schema';

export const EXPORT_VERSION = 1;

export type ExportPayload = {
  version: number;
  exportedAt: number;
  salaries: Salary[];
  debtPlans: DebtPlan[];
  repayments: Repayment[];
};

export async function collectExportPayload(): Promise<ExportPayload> {
  const [salaryRows, debtRows, repaymentRows] = await Promise.all([
    db.select().from(salaries),
    db.select().from(debtPlans),
    db.select().from(repayments),
  ]);
  return {
    version: EXPORT_VERSION,
    exportedAt: Date.now(),
    salaries: salaryRows,
    debtPlans: debtRows,
    repayments: repaymentRows,
  };
}

function writeToFile(name: string, content: string): File {
  const file = new File(Paths.cache, name);
  if (file.exists) file.delete();
  file.create();
  file.write(content);
  return file;
}

function isoStamp(): string {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}`;
}

export async function exportJson(): Promise<string> {
  const payload = await collectExportPayload();
  const json = JSON.stringify(payload, null, 2);
  const file = writeToFile(`cashflows-${isoStamp()}.json`, json);
  await Sharing.shareAsync(file.uri, { mimeType: 'application/json' });
  return file.uri;
}

function escapeCsv(value: unknown): string {
  if (value == null) return '';
  const str = String(value);
  if (/[",\n\r]/.test(str)) return `"${str.replace(/"/g, '""')}"`;
  return str;
}

function rowsToCsv<T extends Record<string, unknown>>(rows: T[], columns: (keyof T & string)[]): string {
  const header = columns.join(',');
  const body = rows
    .map((row) => columns.map((c) => escapeCsv(row[c])).join(','))
    .join('\n');
  return [header, body].filter(Boolean).join('\n');
}

export async function exportCsv(): Promise<string> {
  const payload = await collectExportPayload();
  const sections = [
    '# salaries',
    rowsToCsv(payload.salaries, [
      'id',
      'amountCents',
      'paidAt',
      'period',
      'note',
      'createdAt',
    ]),
    '',
    '# debt_plans',
    rowsToCsv(payload.debtPlans, [
      'id',
      'platform',
      'principalCents',
      'totalPeriods',
      'monthlyPaymentCents',
      'firstDueDate',
      'aprBps',
      'note',
      'archived',
      'createdAt',
    ]),
    '',
    '# repayments',
    rowsToCsv(payload.repayments, [
      'id',
      'debtPlanId',
      'periodIndex',
      'dueDate',
      'amountCents',
      'status',
      'paidAt',
    ]),
  ];
  const csv = sections.join('\n');
  const file = writeToFile(`cashflows-${isoStamp()}.csv`, csv);
  await Sharing.shareAsync(file.uri, { mimeType: 'text/csv' });
  return file.uri;
}

export type ImportResult =
  | { ok: true; salaryCount: number; debtCount: number; repaymentCount: number }
  | { ok: false; reason: 'canceled' | 'invalid' };

export async function importJson(): Promise<ImportResult> {
  const pick = await File.pickFileAsync({ mimeTypes: ['application/json'] });
  if (pick.canceled) return { ok: false, reason: 'canceled' };

  const file = pick.result;
  const text = await file.text();
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return { ok: false, reason: 'invalid' };
  }

  if (!isExportPayload(parsed)) {
    return { ok: false, reason: 'invalid' };
  }

  await db.transaction(async (tx) => {
    await tx.delete(repayments);
    await tx.delete(debtPlans);
    await tx.delete(salaries);
    if (parsed.salaries.length > 0) await tx.insert(salaries).values(parsed.salaries);
    if (parsed.debtPlans.length > 0) await tx.insert(debtPlans).values(parsed.debtPlans);
    if (parsed.repayments.length > 0) await tx.insert(repayments).values(parsed.repayments);
  });

  return {
    ok: true,
    salaryCount: parsed.salaries.length,
    debtCount: parsed.debtPlans.length,
    repaymentCount: parsed.repayments.length,
  };
}

function isExportPayload(value: unknown): value is ExportPayload {
  if (typeof value !== 'object' || value === null) return false;
  const p = value as Partial<ExportPayload>;
  return (
    typeof p.version === 'number' &&
    Array.isArray(p.salaries) &&
    Array.isArray(p.debtPlans) &&
    Array.isArray(p.repayments)
  );
}
